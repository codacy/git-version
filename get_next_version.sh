#!/usr/bin/env bash

REPO_PATH=${1}
if [[ -z $TYPE ]]; then
  TYPE=${2:-date}
fi

if [[ $TYPE == 'semver' ]]; then
  source src/git_version_semver_helper.sh
else
  source src/git_version_date_helper.sh
fi

if [[ -n "$REPO_PATH" ]]; then
  cd $REPO_PATH
  branch=$(get_current_branch)
  hash=$(get_current_commit_hash)
  if [[ $branch == 'master' ]] ; then
    latest_tag=$(get_latest_version_git_tag)
    commits_list=$(get_commit_list_since $latest_tag)
    new_version=$(bump_date_version $latest_tag $commits_list)
  else
    #get highest tags across all branches
    new_version=$(get_suffixed_git_tag $branch)
  fi
  echo $new_version
else
    echo "You are missing the path. Usage:"
    echo "$(basename $0) <path> [semver | date]"
fi
