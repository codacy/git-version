#!/usr/bin/env bash

# Returns a version that depends on the year and month of the release.
# Format: YYYY.MM.{Monthly increasing number}
#
# On non master branches you will get a version that derives from the version on master.
# Example (branch circleci, branched from 2018.07.0 on master after 2 commits): 2018.07.0-2-gff81932.circleci
#
# If you are using master and dev branches, make sure that the commit that is tagged is common to those 2 branches.
set -e

source src/git_version_helper.sh

function get_suffixed_git_tag () {
  local path="$1"
  local branch="$2"
  local current_version_suffixed
  local new_version

  cd $path
  current_version_suffixed=$(git describe --tags --match [0-9][0-9][0-9][0-9]\.[0-9][0-9]\.[0-9]* $(git rev-parse --verify HEAD) 2>/dev/null | sort -n -t . -k1,1 -k2,2 -k3,3 | tail -1)
  new_version="$current_version_suffixed.$branch"
  echo $new_version
}

function get_latest_version_git_tag () {
  local path="$1"
  cd $path
  echo $(git describe --tags --match [0-9][0-9][0-9][0-9]\.[0-9][0-9]\.*[0-9] $(git log --format="%H" -n 1000) 2>/dev/null | sort | head -n 1)
}

function bump_date_version () {
  version=(${1//./ })
  local year=$(get_current_year)
  local month=$(get_current_month)
  local curr_version_year=${version[0]:-$year}
  local curr_version_month=${version[1]:-$month}
  local curr_version_count=${version[2]:-0}
  new_version_year=$year
  new_version_month=$month

  if [[ $year -gt $curr_version_year ]]; then
      new_version_count=1
  elif [ $month -gt $curr_version_month ]; then
      new_version_count=1
  else
      new_version_count=$((curr_version_count+1))
  fi
  echo "$new_version_year.$new_version_month.$new_version_count"
}

