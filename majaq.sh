#!/bin/bash
version="1.0"

# working_dir=~/majaq.io/src
working_dir=`dirname $0`
# echo $working_dir
install () {
    echo "installing...."
    rm -rf $working_dir/src/backend
    git clone git@github.com:Majaq-io/majaq-dev-backend.git $working_dir/src/backend
}

start () {
    echo "Majaq version $version"
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
}

stop () {
    echo "Stopping...."
    # cd src
    cd $working_dir/src
    docker-compose down
    rsync -a $working_dir/src/backend/wp-content/ $working_dir/src/files/wp-content/
    rsync -a $working_dir/src/backend/wp-config.php $working_dir/src/files/wp-config.php
    isRunning
}

isRunning () {
    RUNNING=0
    IS_RUNNING=`docker-compose ps -q wordpress`
    if [ "$IS_RUNNING" != "" ]
    then
        RUNNING=1
        ID=$IS_RUNNING
        echo "Majaq now Running!"
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

Report bugs to: dev-team@majaq.io
EOF
}

if [ "$1" = "install" ]
then
    install
fi

if [ "$1" = "start" ]
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
fi

if [ "$1" = "stop" ]
then
    stop
fi

if [ "$1" = "-v" ]
then
    echo $version
fi

if [ "$1" = "-h" ]
then
    usage
fi
