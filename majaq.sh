#!/bin/bash
version="1.0"

cd src
install () {
    echo "installing...."
}

start () {
    echo "Majaq version $version"
    echo "Starting...."
    docker-compose up -d
    # sudo chown -R $USER src/backend
    if [ -f "src/files/wp-config.php" ]
    then
        rsync -s files/wp-config.php backend/wp-config.php
    fi

    if [ -d "src/files/wp-content" ]
    then
        docker-compose run wordpress rm -rf /var/www/html/wp-content
        rsync -a files/wp-content/ backend/wp-content/
    # else
        # cp -r src/backend/wp-content/ src/files
    fi
    isRunning
}

stop () {
    echo "Stopping...."
    # cd src
    docker-compose down
    rsync -a backend/wp-content/ files/wp-content/
    rsync -a backend/wp-config.php files/wp-config.php
    isRunning
}

isRunning () {
    RUNNING=0
    IS_RUNNING=`docker-compose ps -q wordpress`
    if [ "$IS_RUNNING" != "" ]
    then
        RUNNING=1
        ID=$IS_RUNNING
        startedMsg
    else
        RUNNING=0
    fi
}

startedMsg () {
    echo "Majaq now Running!"
}

usage () {
cat << EOF
usage: 
    majaq install [-f | --fresh]
    majaq start [-s | --seed file_in_src_database_seed.sql]
    majaq stop [-e | --export file_in_src_database_export.sql]
    majaq restart
    majaq -v | --version
    majaq update
    majaq -h | --help | usage

Report bugs to: dev-team@majaq.io
EOF
}

# getSwitches
while getopts ":v:h" opt; do
  case $opt in
    v) echo "$version" ;;
    h) usage ;;
    \?) echo "Invalid option: -$OPTARG" >&2
      exit 1 ;;
  esac
done

# getOptions
while getopts "s:e:v:" option
do
case "${option}"
in
s) SEED=${OPTARG};;
e) EXPORT=${OPTARG};;
esac
done

if [ $1 = "install" ]
then
    install
fi

if [ $1 = "start" ]
then
    start
fi

if [ $1 = "stop" ]
then
    stop
fi

# if [ $1 = "-h" ]
# then
#     usage
# fi

if [ $1 = "-v" ]
then
    echo $version
fi






# docker stop $(docker ps -a -q)
# docker rm $(docker ps -a -q)
# docker rmi $(docker images -q)
# sudo chown -R $USER backend
# docker-compose rm -f
# docker-compose pull
# docker-compose up --build -d
# # Run some tests
# ./tests
# docker-compose stop -t 1
