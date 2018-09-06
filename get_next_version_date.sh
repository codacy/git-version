#!/usr/bin/env bash

# Returns a version that depends on the year and month of the release.
# Format: YYYY.MM.{Monthly increasing number}
#
# On non master branches you will get a version that derives from the version on master.
# Example (branch circleci, branched from 2018.07.0 on master after 2 commits): 2018.07.0-2-gff81932.circleci
#
# If you are using master and dev branches, make sure that the commit that is tagged is common to those 2 branches.
set -e
REPO_PATH=${1:-"."}
cd $REPO_PATH

BRANCH=$(git symbolic-ref --short HEAD)
YEAR=$(date +%Y)
MONTH=$(date +%m)

# if not master, get the latest suffixed tag. example: 5.0.651-29-gc8fb7ec
if [ $BRANCH != 'master' ] ; then
    CURRENT_VERSION_SUFFIXED=$(git describe --tags --match [0-9][0-9][0-9][0-9]\.[0-9][0-9]\.[0-9]* $(git rev-parse --verify HEAD) 2>/dev/null | sort -n -t . -k1,1 -k2,2 -k3,3 | tail -1)
    if [ -z $CURRENT_VERSION_SUFFIXED ]; then
        HASH=$(git rev-parse --verify HEAD --short)
        CURRENT_VERSION_SUFFIXED="0.0.0-$HASH"
    fi
    NEW_VERSION="$CURRENT_VERSION_SUFFIXED.$BRANCH"
    echo $NEW_VERSION
    exit
fi
#get highest tags across all branches, not just the current branch
CURRENT_VERSION=$(git describe --tags --match [0-9][0-9][0-9][0-9]\.[0-9][0-9]\.[0-9] $(git log --format="%H" -n 1000) 2>/dev/null | sort | head -n 1)
if [ -z $CURRENT_VERSION ]; then
    CURRENT_VERSION="$YEAR.$MONTH.0"
fi
# split into array
VERSION_BITS=(${CURRENT_VERSION//./ })

#get number parts and increase last one by 1
VNUM1=${VERSION_BITS[0]}
VNUM2=${VERSION_BITS[1]}
VNUM3=${VERSION_BITS[2]}

if [ $YEAR -gt $VNUM1 ]; then
    VNUM1=$YEAR
    VNUM2=$MONTH
    VNUM3=1
elif [ $MONTH -gt $VNUM1 ]; then
    VNUM2=$MONTH
    VNUM3=1
else
    VNUM3=$((VNUM3+1))
fi

#create new tag
NEW_VERSION="$VNUM1.$VNUM2.$VNUM3"
echo "$NEW_VERSION"
