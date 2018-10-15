# About The Majaq Development Toolset

## The Purpose

+ To create a development workflow that bridges the gap for backend and front-end developers 
+ To containerize the entire backend development environment, so that everyone on the team is running the same exact setup
+ To persist the backend files and database for each team member development environment.

## The Stack

+ [Docker](https://www.docker.com/) for containerizing the backend development environment.
    + containers used:
        + Wordpress
        + Nginx
        + Mysql
        + PhpMyAdmin
        + WP-CLI
        + Search-Replace-DB (coming soon)

+ git and Github for version control and remote repository
+ shell scripts for starting and stopping the containers, updating the backend, and dumping/seeding/re-seeding the development database.
## 
