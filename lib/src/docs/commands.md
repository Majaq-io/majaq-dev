
# Commands

run majaq.sh with full path 
``` bash
~/src/majaq-dev/majaq.sh [options]
```
or change to majaq.sh directory, then run
``` bash
cd ~/src/majaq-dev
majaq.sh [options]
```
replacing ~/src/majaq-dev with the directory you originally cloned to.

## Parameters

``` 
start
stop
restart
-v or --version
status or --status
-h or --help
```

## start
this will 
+ start majaq-dev environment
+ auto update the majaq-dev repo, and majaq.sh
+ fetch updated backend files
+ if the master-dev db was updated, clear the db and re-seed
  
``` bash
./majaq.sh
or
./majaq.sh start
```

## stop

``` bash
./majaq.sh stop
```

## help and usage
-h or --help diplays command options
``` bash
./majaq.sh -h
```
will output
``` bash
usage: 
    majaq -h or --help
    majaq start
    majaq stop
    majaq restart
    majaq -v or --version
    majaq status or --status
```