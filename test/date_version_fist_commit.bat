#!/usr/bin/env bats

source src/git_version_date_helper.sh
load test_helper

setup() {
  set_test_suite_tmpdir
  cd $BATS_TEST_SUITE_TMPDIR
  git init

  # Checkout to master and add one commit and a tag

  git checkout -b master
  touch file.txt
  git add file.txt
  git commit --no-gpg-sign -m "new file.txt"
}

@test "current branch is master" {
  set_test_suite_tmpdir
  local branch=$(get_current_branch)
  [ $branch == "master" ]
}

@test "current tag in master matches 0.0.0-" {
  set_test_suite_tmpdir
  local tag=$(get_suffixed_git_tag)
  [[ $tag =~ "0.0.0-" ]]
}
