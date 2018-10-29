REPO_PATH=${1}
TYPE=${2:-date}

if [[ $TYPE == 'semver' ]]; then
  source src/git_version_semver_helper.sh
else
  source src/git_version_date_helper.sh
fi

if [[ -n "$REPO_PATH" ]]; then
  branch=$(get_current_branch $REPO_PATH)
  hash=$(get_current_commit_hash $REPO_PATH)
  if [[ $branch == 'master' ]] ; then
    latest_tag=$(get_latest_version_git_tag $REPO_PATH)
    commits_list=$(get_commit_list_since $latest_tag)
    new_version=$(bump_date_version $latest_tag $commits_list)
  else
    #get highest tags across all branches
    new_version=$(get_suffixed_git_tag $branch)
    if [[ -z $new_version ]]; then
      hash=$(get_current_commit_hash)
      new_version="0.0.0-$hash"
    fi
  fi
  echo $new_version
else
    echo "You are missing the path. Usage:"
    echo "$ $0 {path) [semver|date]"
fi
