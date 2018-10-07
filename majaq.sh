#!/bin/bash
version="1.0"
scriptRepoUrl="https://raw.githubusercontent.com/Majaq-io/majaq-dev/master/majaq.sh"

# working_dir=~/majaq.io/src
working_dir=`dirname $0`
# echo $working_dir
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
        cd $working_dir/src
        docker-compose -f $working_dir/src/docker-compose.yml up -d
        if [ -f "$working_dir/src/files/wp-config.php" ]
        then
            rsync -s $working_dir/src/files/wp-config.php $working_dir/src/backend/wp-config.php
        fi

        if [ -d "$working_dir/src/files/wp-content" ]
        then
            cd $working_dir/src
            docker-compose run wordpress rm -rf /var/www/html/wp-content
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
    cd $working_dir/src
    docker-compose down
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

isRunning () {
    RUNNING=0
    IS_RUNNING=`docker-compose ps -q wordpress`
    if [ "$IS_RUNNING" != "" ]
    then
        RUNNING=1
        ID=$IS_RUNNING
    else
        RUNNING=0
    fi
}

seed () {
    echo "seeding: $SEED"
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

if [ "$1" = "install" ]
then
    install
# fi

elif [ "$1" = "start" ]
then
    if [ "$2" = "-s" ] && [ -z "$3" ]
    then
        SEED="default"
        seed
    elif [ "$2" = "-s" ] && [ "$3" != "" ]
    then
        SEED="$3"
        seed
    fi
    # echo "$1 $2 $SEED"
    start
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
# fi

elif [ "$1" = "status" ]
then
    isRunning
    isRunningMsg
# fi

elif [ "$1" = "" ]
then
    echo "missing arguments"
    usage
else
    echo "invalid arguments: $1"
    usage
fi
