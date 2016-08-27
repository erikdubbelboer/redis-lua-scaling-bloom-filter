#!/bin/bash

###
### Note, if you run this on OSX El Capitan, you may run into an issue with FPM
### not working with the error message:
###   Could not open library 'libc.dylib': dlopen(libc.dylib, 5): image not found (LoadError)
### If so, follow these steps:
###   https://github.com/jordansissel/fpm/issues/1010#issuecomment-193217675

#set -xe

### The dir for the package script
MY_DIR=$( dirname $0 )
cd $MY_DIR

### Build debian pckages by default, but any other type will do if FPM understands it.
TYPE=${1:-deb}

echo "Building $TYPE package"

### Throw away any old packages
rm -f *.$TYPE

### Name of the package, project, etc
NAME=redis-lua-scaling-bloom-filter

_GIT_VERSION=`git tag -l | tail -n 1`
VERSION=${_GIT_VERSION:-1}
PACKAGE_VERSION=$VERSION~$( date -u +%Y%m%d%H%M )
PACKAGE_NAME=$NAME

### List of files to package
FILES="*.lua *.js *.md"

### Where this package will be installed
DEST_DIR="/usr/local/${NAME}/"

### Where the sources live
SOURCE_DIR=$MY_DIR

fpm -s dir -t $TYPE -a all -n $PACKAGE_NAME -v $PACKAGE_VERSION --prefix $DEST_DIR -C $SOURCE_DIR $FILES
