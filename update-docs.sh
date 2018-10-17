#!/usr/bin/env sh


echo "updating docs"
cd lib/src/docs

echo "build for github pages"
npm run deploy 

echo "build for majaq backend theme"
npm run build

echo "push to Github"
cd ../../../
git add docs/ lib/src/docs/
git commit -m "update docs"
git push -u origin master
./majaq.sh restart