#!/bin/bash
version="1.2"

_scriptUrl="https://raw.githubusercontent.com/Majaq-io/majaq-dev/master/majaq.sh"
_pwd=`dirname $0`
_dumpDir="$_pwd/lib/dump"
_script=`basename "$0"`                         && echo "this script -          $_script"
_scriptName=`echo $_script | cut -d'.' -f1`     && echo "this script name -     $_scriptName"
_appName="${PWD##*/}"                           && echo "this script dir name - $_appName"
_container="docker-compose -f $_pwd/lib/docker-compose.yml -p $_appName"

# functions
usage () {
cat << EOF
usage: 
    majaq -h | --help | usage
    majaq start
    majaq stop
    majaq restart
    majaq seed
    majaq dump
    majaq -v | --version
    majaq -u | --update
    majaq status
Report bugs to: dev-team@majaq.io
EOF
}

RUNNING=0
isRunning () {
    IS_RUNNING=`$_container ps -q wp`
    if [ "$IS_RUNNING" != "" ]
    then
        RUNNING=1
        ID=$IS_RUNNING
        # echo "$ID"
    else
        RUNNING=0
    fi
}

# parameters
if [ "$1" = "-h" ] || [ "$1" = "--help" ]
then
    usage
    exit

elif [ "$1" = "status" ]
then
    isRunning
    if [ "$RUNNING" = 1 ]
    then
        echo "Majaq Dev is runnning"
    else
        echo "Majaq Dev is not running"
    fi

elif [ "$1" = "-v" ] || [ "$1" = --version ]
then
    echo 'Majaq Dev version '$version

fi