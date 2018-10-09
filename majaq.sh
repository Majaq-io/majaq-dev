#!/bin/bash
version="1.0"
scriptRepoUrl="https://raw.githubusercontent.com/Majaq-io/majaq-dev/master/majaq.sh"
working_dir=`dirname $0`

##### functions
installBackend () {
    if [ -d "$working_dir/src/backend/.git" ]
    then
        echo "installing majaq-dev-backend in ./src/backend"
        rm -rf $working_dir/src/backend
        git clone git@github.com:Majaq-io/majaq-dev-backend.git $working_dir/src/backend
        rsync -a $working_dir/src/backend/wp-content/ $working_dir/src/files/wp-content/
        rsync -a $working_dir/src/backend/wp-config.php $working_dir/src/files/wp-config.php
        exit
    fi
}

start () {
    isRunning
    if [ $RUNNING = 1 ]
    then
        echo "Majaq is already running"
        exit
    else 
        echo "Majaq version $version"
        checkUpdate
        updateBackend
        echo "Starting...."
        sleep 6
        # cd $working_dir/src
        docker-compose -f $working_dir/src/docker-compose.yml up -d
        if [ -f "$working_dir/src/files/wp-config.php" ]
        then
            rsync -s $working_dir/src/files/wp-config.php $working_dir/src/backend/wp-config.php
        fi

        if [ -d "$working_dir/src/files/wp-content" ]
        then
            # cd $working_dir/src
            docker-compose  -f $working_dir/src/docker-compose.yml run wordpress rm -rf /var/www/html/wp-content
            rsync -a $working_dir/src/files/wp-content/ $working_dir/src/backend/wp-content/
        # else
            # cp -r $working_dir/src/backend/wp-content/ $working_dir/src/files
        fi
        isRunning
        isRunningMsg
        exit
    fi
}

stop () {
    isRunning
    if [ "$RUNNING" = 0 ]
    then
        isRunningMsg
        exit
    fi
    echo "Stopping...."
    # cd src
    # cd $working_dir/src
    docker-compose  -f $working_dir/src/docker-compose.yml down
    rsync -a $working_dir/src/backend/wp-content/ $working_dir/src/files/wp-content/
    rsync -a $working_dir/src/backend/wp-config.php $working_dir/src/files/wp-config.php
    rm -rf $working_dir/src/database/seed/*
    echo "Majaq has stopped"
    exit
}

isRunningMsg () {
    if [ $RUNNING = 0 ]
    then
        echo "Majaq is not running"
        exit
    elif [ $RUNNING = 1 ]
    then
        echo "Majaq is running"
        exit
    fi
}

checkUpdate () {
    echo "checking update"
    updateVersion=`curl -s $scriptRepoUrl 2> /dev/null | head -n2 | sed -n '2 p'`
    updateVersion=${updateVersion#"version="}
    updateVersion="${updateVersion%\"}"
    updateVersion="${updateVersion#\"}"
    # echo $version
    # echo $updateVersion
    if [ "$updateVersion" = "$version" ]
    then
        echo "Up to date"
    else
        echo "Update available"
        cd $working_dir
        git fetch origin master
        git pull
        exit
    fi
    # echo $updateVersion
}

updateBackend () {
    echo "Checking backend for updates"
    if [ -d ./src/backend" ]
    then
        installBackend
    else
        git -C $working_dir/src/backend fetch
        git -C $working_dir/src/backend pull
    fi
}

checkDependencies () {
    echo "=============================="
    echo "checking Majaq dependencies..."

    printf "\n"
    echo "rsync version:"
    rsync --version 2>&1 | head -n 1

    printf "\n"
    echo "Docker Version:"
    docker --version

    printf "\n"
    echo "Docker Compose Version:"
    docker-compose --version

    printf "\n"
    echo "node version:"
    node -v

    printf "\n"
    echo "git version:"
    git --version

    printf "\n"
    echo "Visual Studio Code version:"
    code --version
    echo "=============================="
}

isRunning () {
    RUNNING=0
    IS_RUNNING=`docker-compose -f $working_dir/src/docker-compose.yml ps -q wordpress`
    if [ "$IS_RUNNING" != "" ]
    then
        RUNNING=1
        ID=$IS_RUNNING
    else
        RUNNING=0
    fi
}

usage () {
    # majaq install [-f | --fresh]
cat << EOF
usage: 
    majaq start [-s | --seed [select]]
    majaq stop [-d | --dump ]
    majaq restart
    majaq -v | --version
    majaq update
    majaq -h | --help | usage
    majaq status

Report bugs to: dev-team@majaq.io
EOF
}


###### parameters passes

# if [ "$1" = "install" ]
# then
#     install
# fi

if [ "$1" = "start" ] && [ -z $2 ] && [ -z $3 ]
then
    isRunning
    # echo "$RUNNING"
    if [ "$RUNNING" = 0 ]
    then
        start
    else
        isRunningMsg
        echo "Majaq must not be running to seed, try:"
        echo "majaq restart -s"
        echo "  or"
        echo "majaq stop"
        echo "majaq start -s"
        exit
    fi
    # sudo chown -R $USER $working_dir/src/backend
fi
# +++===============================================
# +++===============================================
if [ "$1" = "start" ] && [ "$2" = "-s" ] && [ -z $3 ]
then
    SEED="default"

elif [ "$2" = "-s" ] && [ "$3" = "select" ]
then
    SEED="select"
elif [ "$2" = "-s" ] && [ "$3" != "" ]
then
    echo "invalid argument: $3"
    echo "valid options are:"
    echo "-s"
    echo "-s select"
fi

isRunning
if [ "$RUNNING" = "0" ]
then
    # echo "$SEED"
    seedDir="$working_dir/src/database/seed"
    dumpDir="$working_dir/src/database/dump"
    if [ "$SEED" = "default" ]
    then
        echo "copy dump/default.sql to seed/default.sql"
        cp $dumpDir/default.sql $seedDir/default.sql
        start
    fi

    if [ "$SEED" = "select" ]
    then
        prompt="Please select a dump to seed:"
        # cd "$working_dir/src/database/dump"
        options=( $(find "$working_dir/src/database/dump" -type f -path "*.sql" -printf  "%f\n" | xargs -0) )
        PS3="$prompt "
        select opt in "${options[@]}" "Quit" ; do 
            if (( REPLY == 1 + ${#options[@]} )) ; then
                exit
            elif (( REPLY > 0 && REPLY <= ${#options[@]} )) ; then
                echo  "You picked $(basename $opt) which is file $REPLY"
                break
            else
                echo "Invalid option. Try another one."
            fi
        done 
        # ls -ld "$dumpDir/$opt"
        cp "$dumpDir/$opt" "$seedDir/$opt"
        start
        exit
    fi
# else    
#     # isRunningMsg
fi

if [ "$1" = "stop" ]
then
    stop
# fi

elif [ "$1" = "restart" ]
then
    stop
    sleep 5
    start
# fi

elif [ "$1" = "-v" ] || [ "$1" = "--version" ]
then
    echo $version
    exit
# fi

elif [ "$1" = "-h" ] || [ "$1" = "--help" ]
then
    usage
    exit

elif [ "$1" = "status" ]
then
    isRunning
    isRunningMsg

elif [ "$1" = "-check-dependencies" ]
then
    checkDependencies

elif [ "$1" = "update" ]
then
    checkUpdate
    # prompt y/n to update
    read -p "Update now (y/n)?" choice
    case "$choice" in 
        y|Y ) echo "yes";;
        n|N ) echo "skipping update";;
        * ) echo "invalid";;
    esac
    updateBackend
    exit

elif [ "$1" = "" ]
then
    echo "missing arguments"
    usage

else
    echo "invalid arguments: $1"
    usage
fi

