#!/bin/bash
# A basic script to do some common git things

if [ ! -n "$1" ]; then
    echo "Please enter either 'develop' or 'heroku'"
elif [ $1 = "develop" ]; then 
    git checkout master
    git merge develop
    git push origin master
    git push origin develop
    git checkout develop
elif [ $1 = "heroku" ]; then
    git fetch origin
    git checkout heroku
    git rebase master
    echo "Push to Heroku? [yN]"
    read answer
    if [ answer = "y" ]; then
        git push -f heroku heroku:master
    fi
fi

