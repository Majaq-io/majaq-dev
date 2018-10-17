#!/usr/bin/env sh

# abort on errors
set -e

# backup config.js to dev-config.js
cp .vuepress/config.js .vuepress/dev-config.js

# change base to majaq-dev
sed -i -e 's/docs/majaq-dev/g' .vuepress/config.js

# build it with new config
vuepress build

# put the dev config back
rm .vuepress/config.js
cp .vuepress/dev-config.js .vuepress/config.js
rm .vuepress/dev-config.js

# remove root docs folder
rm -rf ../../../docs

# move the dist folder to root docs
mv .vuepress/dist ../../../docs
