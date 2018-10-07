#!/bin/bash
version="1.0"
scriptRepoUrl="https://raw.githubusercontent.com/Majaq-io/majaq-dev/master/majaq.sh"
working_dir=`dirname $0`

##### functions
install () {
    echo "installing...."
    rm -rf $working_dir/src/backend
    git clone git@github.com:Majaq-io/majaq-dev-backend.git $working_dir/src/backend
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
        echo "Starting...."
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
    if [ $RUNNING = 0 ]
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
    fi
}

restart () {
    stop
    sleep 5
    start
}

checkUpdate () {
    echo "checking update"
    # scriptRepoUrl="test"
    updateVersion=`curl -s $scriptRepoUrl 2> /dev/null | head -n2 | sed -n '2 p'`
    updateVersion=${updateVersion#"version="}
    updateVersion="${updateVersion%\"}"
    updateVersion="${updateVersion#\"}"
    # echo $version
    # echo $updateVersion
    if [ "$updateVersion" = "$version" ]
    then
        echo "up to date"
    else
        echo "update available"
    fi
    # echo $updateVersion
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

seed () {
    # echo "seeding: $SEED"
    if [ $SEED = "default" ]
    then
        echo "Seeding default: $SEED"
    fi

    if [ $SEED = "select" ]
    then
        seedDir="$working_dir/src/database/seed"
        dumpDir="$working_dir/src/database/dump"
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
    fi
}

usage () {
cat << EOF
usage: 
    majaq install [-f | --fresh]
    majaq start [-s | --seed file_in_src_database_seed.sql]
    majaq stop [-e | --export file_to_src_database_export.sql]
    majaq restart
    majaq -v | --version
    majaq update
    majaq -h | --help | usage
    majaq status

Report bugs to: dev-team@majaq.io
EOF
}


###### parameters passes

if [ "$1" = "install" ]
then
    install
# fi

elif [ "$1" = "start" ]
then
    if [ "$2" = "-s" ] || [ "$2" = "--seed" ] && [ -z "$3" ]
    then
        SEED="default"
        # selectSeed
        seed
    elif [ "$2" = "-s" ] && [ "$3" != "" ]
    then
        SEED="$3"
        seed
    fi
    # echo "$1 $2 $SEED"
    isRunning
    if [ $RUNNING = 0 ]
    then
        start
    else
        isRunningMsg
        echo "Majaq must not be running to seed, try:"
        echo "majaq restart -s"
        echo "  or"
        echo "majaq stop"
        echo "majaq start -s"
    fi
    # sudo chown -R $USER $working_dir/src/backend
# fi

elif [ "$1" = "stop" ]
then
    stop
# fi

elif [ "$1" = "restart" ]
then
    restart
# fi

elif [ "$1" = "-v" ] | [ "$1" = "--version" ]
then
    echo $version
# fi

elif [ "$1" = "-h" ] | [ "$1" = "--help" ]
then
    usage

elif [ "$1" = "status" ]
then
    isRunning
    isRunningMsg

elif [ "$1" = "-check-dependencies" ]
then
    checkDependencies

elif [ "$1" = "" ]
then
    echo "missing arguments"
    usage

else
    echo "invalid arguments: $1"
    usage
fi

