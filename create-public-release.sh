#!/bin/bash

set -e

# Check params
if [ $# -ne 1 ]
	then
		echo Usage: $0 version;
    echo E.g: $0 0.1.0
		echo Version is MAJOR.MINOR.BUGFIX
		echo Latest versions:
		git tag | tail -n 5
		exit 1;
fi

# Set environment
export LANG="C.UTF-8"
export VERSION=$1

RUN_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $RUN_PATH

./step-create-docker-image.sh
./step-upload-docker-image.sh
./step-git-tag.sh

echo ----[ Operation completed successfully ]----

echo
echo You can send the tag: git push --tags
