# Documentation

Welcome to the Majaq Deveopment Team! ✋

## Introduction
this is a guide for basic use and collaboration using the "Majaq Development Toolset"

Get more of an overview [here](/about.html)


## Getting Started
Prerequisites:\
you will need Docker and Docker Compose, get them here\
[https://www.docker.com/get-started](https://www.docker.com/get-started)

## Installation:
if you have ssh keys setup run:
``` bash
git clone git@github.com:Majaq-io/majaq-dev.git
```
or use https
``` bash
git clone https://github.com/Majaq-io/majaq-dev.git
```

then...
``` bash
cd majaq-dev
./majaq.sh
```

The first time you run this it may take some time depending on your internet speed.\
After it installs all the dependenies, you should see
``` bash
Majaq Dev v1.5 is now runnning at
http://localhost:8080
```

open up a browser and goto\
[http://localhost:8080](http://localhost:8080)

you should be greeted with this documentation running locally on top of our backend.

try some other links to services running\
phpMyAdmin\
[http://localhost:8081](http://localhost:8081)

Adminer\
[http://localhost:8082](http://localhost:8082)

searchAndReplace\
[http://localhost:8083](http://localhost:8083)

check out the rest api here\
site data:\
[http://localhost:8080/wp-json/wp/v2/](http://localhost:8080/wp-json/wp/v2/)

all pages:\
[http://localhost:8080/wp-json/wp/v2/pages](http://localhost:8080/wp-json/wp/v2/pages)

or just 10 pages\
[http://localhost:8080/wp-json/wp/v2/pages?per_page=10](http://localhost:8080/wp-json/wp/v2/pages?per_page=10)

or a specific page\
[http://localhost:8080/wp-json/wp/v2/pages?slug=home](http://localhost:8080/wp-json/wp/v2/pages?slug=home)

menus:\
coming soon...... probably next

galleries:\
coming soon......

check out the list of [commands](/commands.html)