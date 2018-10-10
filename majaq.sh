#!/bin/bash
version="1.1"
scriptRepoUrl="https://raw.githubusercontent.com/Majaq-io/majaq-dev/master/majaq.sh"
working_dir=`dirname $0`
dumpDir="$working_dir/src/database/dump"

##### functions
RUNNING=0
if [ "$2" != "-s" ]
then
    SEED=null
fi

isRunning () {
    IS_RUNNING=`docker-compose -f $working_dir/src/docker-compose.yml ps -q wordpress`
    if [ "$IS_RUNNING" != "" ]
    then
        RUNNING=1
        ID=$IS_RUNNING
        # echo "$ID"
    else
        RUNNING=0
    fi
}
isRunning

installBackend () {
    if [ ! -d "$working_dir/src/backend/.git" ]
    then
        echo "installing majaq-dev-backend in ./src/backend"
        rm -rf $working_dir/src/backend
        git clone git@github.com:Majaq-io/majaq-dev-backend.git $working_dir/src/backend
        cp $working_dir/src/files/wp-content/ $working_dir/src/backend/wp-content/
        cp $working_dir/src/files/wp-config.php $working_dir/src/backend/wp-config.php
    fi
}

start () {
    isRunning
    if [ "$RUNNING" = 1 ] && [ "$2" = "-s" ]
    then
        echo "Majaq is already running"
        echo "Now attempting to seed.."
        return

    elif [ "$RUNNING" = 1 ] && [ "$2" != "-s" ]
    then
        echo "Majaq is already running"
        return
    else 
        echo "Majaq version $version"
        checkUpdate
        updateBackend
        echo "Starting...."
        sleep 6
        docker-compose -f $working_dir/src/docker-compose.yml up -d
        if [ -f "$working_dir/src/files/wp-config.php" ] && [ -f "$working_dir/src/backend/wp-config.php" ] 
        then
            rsync -s $working_dir/src/files/wp-config.php $working_dir/src/backend/wp-config.php
        else
            cp $working_dir/src/files/wp-config.php $working_dir/src/backend/wp-config.php
        fi

        if [ -d "$working_dir/src/files/wp-content" ]
        then
            docker-compose  -f $working_dir/src/docker-compose.yml run --rm wordpress rm -rf /var/www/html/wp-content
            rsync -a $working_dir/src/files/wp-content/ $working_dir/src/backend/wp-content/
        else
            cp -r $working_dir/src/backend/wp-content/ $working_dir/src/files
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
    docker-compose  -f $working_dir/src/docker-compose.yml down
    rsync -a $working_dir/src/backend/wp-content/ $working_dir/src/files/wp-content/
    rsync -a $working_dir/src/backend/wp-config.php $working_dir/src/files/wp-config.php
    # rm -rf $working_dir/src/database/seed/*
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
        echo "Majaq Dev is running at"
        echo "http://localhost:8080"
        exit
    fi
}

checkUpdate () {
    echo "checking update"
    updateVersion=`curl -s $scriptRepoUrl 2> /dev/null | head -n2 | sed -n '2 p'`
    updateVersion=${updateVersion#"version="}
    updateVersion="${updateVersion%\"}"
    updateVersion="${updateVersion#\"}"
    if [ "$updateVersion" = "$version" ]
    then
        echo "Up to date"
    else
        echo "Update available"
        update
    fi
}

update () {
    cd $working_dir
    git fetch origin master
    git pull
}

updateBackend () {
    echo "Checking backend for updates"
    if [ ! -d "$working_dir/src/backend" ]
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

selectSeed () {
    # no seed flag used or selected, just start
    if [ "$SEED" = null ]
    then
        start
        exit

    elif [ "$SEED" = "default" ]
    then
        start
        sleep 3
        SEED=master-dev.sql
        seed
        exit

    elif [ "$SEED" = "select" ]
    then
        prompt="Please select (1-*) dump to seed:"
        options=( $(find "$dumpDir" -type f -path "*.sql" -printf  "%f\n" | xargs -0) )
        PS3="$prompt "
        select opt in "${options[@]}" "Quit" ; do 
            if (( REPLY == 1 + ${#options[@]} )) ; then
                exit
            elif (( REPLY > 0 && REPLY <= ${#options[@]} )) ; then
                # echo  "seeding database $(basename $opt) which is file $REPLY"
                echo  "Seeding database dump $(basename $opt)"
                break
            else
                echo "Invalid option. Try another one."
            fi
        done
        SEED="$opt"
        start
        sleep 3
        seed
        exit
    fi
}

seed () {
    if [ "$1" != "dump" ]
    then
        echo "seeding"
        echo "$SEED"
        # rm db
        REMOVE_db='mysqladmin -u root -ppassword -f drop wordpress'
        docker-compose -f $working_dir/src/docker-compose.yml exec wordpress_db $REMOVE_db &>/dev/null
        # create db
        CREATE_DB='mysqladmin -u root -ppassword create wordpress'
        docker-compose -f $working_dir/src/docker-compose.yml exec wordpress_db $CREATE_DB &>/dev/null
        docker-compose -f $working_dir/src/docker-compose.yml exec -T wordpress_db mysql -u root -ppassword wordpress < $working_dir/src/database/dump/$SEED &>/dev/null
    fi
}

dump () {
    echo "------------------------------------------------------"
    echo "enter name of dump file"
    read -e DUMP_file
    echo "You have named the dump "$DUMP_file""
    # DUMP_file="dump_file"
    echo "dumping src/database/dump/$DUMP_file.sql"
    docker-compose -f $working_dir/src/docker-compose.yml exec wordpress_db mysqldump -u root -ppassword wordpress > $dumpDir/$DUMP_file.sql 
    sed -i 1,1d $dumpDir/$DUMP_file.sql
    echo "dumping complete"
    echo "------------------------------------------------------"

}

usage () {
cat << EOF
usage: 
    majaq -h | --help | usage
    majaq start [-s | --seed [select]]
    majaq stop [-d | --dump ]
    majaq restart
    majaq -v | --version
    majaq update
    majaq status
Report bugs to: dev-team@majaq.io
EOF
}

###### parameters passed

# ./majaq.sh start
isRunning
if [ "$1" = "start" ] && [ -z $2 ] && [ -z $3 ]
then
    if [ "$RUNNING" = 0 ]
    then
        start
    else
        echo "Majaq is already running"
        isRunningMsg
        exit
    fi
fi

# ./majaq.sh start -s (seeds the dump default.sql)
if [ "$1" = "start" ] && [ "$2" = "-s" ] && [ -z $3 ]
then
    SEED="default"
    selectSeed

# ./majaq.sh start -s select (prompts to select dump)
elif [ "$1" = "start" ] && [ "$2" = "-s" ] && [ "$3" = "select" ]
then
    SEED="select"
    selectSeed

elif [ "$RUNNING" = 1 ] && [ "$2" = "-s" ] 
# && [ "$3" != "" ]
then
    echo "Majaq must not be running to seed, try:"
    echo "majaq restart -s"
    echo "  or"
    echo "majaq stop"
    echo "majaq start -s"
    exit

elif [ "$2" = "-s" ] && [ "$3" != "" ]
then
    echo "invalid argument: $3"
    echo "valid options are:"
    echo "-s"
    echo "-s select"
fi

if [ "$1" = "stop" ]
then
    stop

elif [ "$1" = "restart" ]
then
    stop
    sleep 5
    start

elif [ "$1" = "-v" ] || [ "$1" = "--version" ]
then
    echo $version
    exit

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
    # prompt y/n to update
    read -p "Update now (y/n)?" choice
    case "$choice" in 
        y|Y ) update;;
        n|N ) echo "skipping update";;
        * ) echo "invalid";;
    esac
    updateBackend
    exit


elif [ "$1" = "dump" ]
then
    dump
    exit

elif [ "$1" = "" ]
then
    echo "missing arguments"
    usage

else
    echo "invalid arguments: $1"
    usage
fi