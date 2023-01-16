#!/usr/bin/env bash

help(){
    echo
    echo "Usage:"
    echo "auto-deploy-project.sh <git project dir> <target branch> <build profile>"
    echo
}

if [ ! -d "$1" ];
then
    echo
    echo "Please, input a legal project directory."
    help
    exit 1
fi

TARGET_DIR="$1"
TARGET_BRANCH="$2"
BUILD_PROFILE="$3"
if [ -z "$TARGET_BRANCH" ];
then
    echo
    echo "Please, input a target branch."
    help
    exit 1
fi

# 'goto' project directory
echo
echo "--- goto project directory"
cd "$TARGET_DIR"
echo 
echo "--- update project information"
if [[ ! "$(ls -al)" == *".git"* ]];
then
    echo
    echo "Please, input a legal 'git' project directory."
    help
    exit 1
fi

echo
echo "--- check target branch"
if [ ! `git rev-parse --verify "$TARGET_BRANCH" 2>/dev/null` ];
then
    echo
    echo "'$TARGET_BRANCH' DOES NOT EXIST"
    echo "Please, input a legal target branch."
    help
    exit 1
fi

echo "--- save current branch"
_cur_branch=$(git branch | grep [*])
CUR_BRANCH=${_cur_branch:2}
echo
echo "--- change branch to 'target branch''"
git checkout "$TARGET_BRANCH"
echo
echo "--- pull modifications of this branch."
git pull
echo
echo "--- check 'build profile'"
cd config
if [ $(ls -d */ | grep "$BUILD_PROFILE/" | wc -l) -lt 1 ];
then
    echo
    echo "Please, input a legal 'build profile'."
    help
    echo
    echo "--- restore a current branch"
    cd "$TARGET_DIR"
    git checkout "$CUR_BRANCH"
    exit 1
fi
cd ..

echo
echo "--- execute 'maven package for 'target profile'"
mvn clean package -Dbuild.profile=$BUILD_PROFILE -Dmaven.test.skip-truei -U -up
echo
echo "--- deploy build package."
cd deploy/dev
./deploy.sh

echo
echo "--- restore a current branch"
cd "$TARGET_DIR"
git checkout "$CUR_BRANCH"

exit 0

