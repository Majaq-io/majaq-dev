#!/bin/bash
version="1.2"

_scriptUrl="https://raw.githubusercontent.com/Majaq-io/majaq-dev/master/majaq.sh"
_pwd=`dirname $0`
_dumpDir="$_pwd/lib/dump"
_script=`basename "$0"`                         # && echo "this script -          $_script"
_scriptName=`echo $_script | cut -d'.' -f1`     # && echo "this script name -     $_scriptName"
_appName="${PWD##*/}"                           # && echo "this script dir name - $_appName"
_container="docker-compose -f $_pwd/lib/docker-compose.yml -p $_appName"

# functions
usage () {
cat << EOF
usage: 
    $_scriptName -h or --help
    $_scriptName start
    $_scriptName stop
    $_scriptName restart
    $_scriptName -v or --version
    $_scriptName -u or --update
    $_scriptName status or --status
Report bugs to: dev-team@majaq.io
EOF
}

RUNNING=0
isRunning () {
    IS_RUNNING=`$_container ps -q wp`
    if [ "$IS_RUNNING" != "" ] ;then
        RUNNING=1
        ID=$IS_RUNNING
        # echo "$ID"
    else
        RUNNING=0
    fi
}
isRunning

checkForUpdate () {
    _update=0
    echo "Checking for update"
    git remote update --quiet > /dev/null 2>&1 && git status -uno | grep -q 'Your branch is behind' && _update=1 
    if [ $_update = 1 ] ;then
        echo "Update available, updating now"
        git fetch --all  --quiet
        git reset --hard origin/master  --quiet
        git pull origin master  --quiet
    else
        echo "Update to date"
    fi
}
####################################################
# parameters

# start the backend
if [ -z $1 ] || [ "$1" = "start" ] ;then
    if [ "$RUNNING" = 1 ] ;then
        echo "Majaq Dev v$version is already runnning"
        exit
    else
        checkForUpdate
        $_container up -d
        exit
    fi

# stop and remove containers(takes longer to restart, but makes it portable)
elif [ "$1" = "stop" ] ;then
    if [ "$RUNNING" = 0 ] ;then
        echo "Majaq Dev v$version is not running"
        exit
    else
        # $_container stop
        $_container down
        exit
    fi

elif [ "$1" = "restart" ] ;then
    if [ "$RUNNING" = 0 ] ;then
        echo "Majaq Dev v$version is not running"
        exit
    else
        $_container stop
        $_container start
        exit
    fi

# help [-h] or [--help]
elif [ "$1" = "-h" ] || [ "$1" = "--help" ] ;then
    usage
    exit

# status [status or --status]
elif [ "$1" = "status" ] || [ "$1" = "--status" ] ;then
    if [ "$RUNNING" = 1 ] ;then
        echo "Majaq Dev v$version is runnning"
    else
        echo "Majaq Dev v$version is not running"
    fi

# version [-v or version]
elif [ "$1" = "-v" ] || [ "$1" = --version ] ;then
    echo 'Majaq Dev version '$version

# if an invalid parameter was passed
else
    echo "invalid argument $0 $1"
    usage
    exit
fi