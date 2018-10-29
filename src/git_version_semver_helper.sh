#!/usr/bin/env bash

# Returns a version matching semver.
# Format: MAJOR.MINOR.PATCH
#
# On non master branches you will get a version that derives from the version on master.
# Example (branch circleci, branched from 1.0.0 on master after 2 commits): 1.0.0-2-gff81932.circleci
#
set -e

source src/git_version_helper.sh

function get_suffixed_git_tag () {
  path=${1}
  cd $path
  local branch="$1"
  local current_version_suffixed
  local new_version
  current_version_suffixed=$(git describe --tags --match [0-9][0-9][0-9].*[0-9].*[0-9] --match [0-9][0-9].*[0-9].*[0-9] --match *[0-9].*[0-9].*[0-9] $(git rev-parse --verify HEAD) 2>/dev/null | sort -n -t . -k1,1 -k2,2 -k3,3 | tail -1)
  echo $current_version_suffixed
  new_version="$current_version_suffixed.$branch"
  echo $new_version
}

function get_latest_version_git_tag () {
  path=${1}
  cd $path
  echo $(git describe --tags --match [0-9][0-9][0-9].*[0-9].*[0-9] --match [0-9][0-9].*[0-9].*[0-9] --match [0-9].*[0-9].*[0-9] $(git rev-list --tags HEAD --max-count 100) 2>/dev/null | sort  -n -t . -k1,1 -k2,2 -k3,3 | head -1)
}

function bump_date_version () {
  local version=(${1//./ })
  local commits_list=$2
  local major=${version[0]:-0}
  local minor=${version[1]:-0}
  local patch=${version[2]:-0}

  echo $commits_lists

  is_breaking=$(echo $commits_list | grep "breaking:*")
  is_feature=$(echo $commits_list | grep "feature:*")

  if [[ -n $is_breaking ]]; then
      major=$((minor+1))
      minor=0
      patch=0
  elif [[ -n $is_feature ]]; then
      minor=$((minor+1))
      patch=0
  else
      patch=$((patch+1))
  fi
  echo "$major.$minor.$patch"
}
