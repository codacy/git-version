#!/usr/bin/env bats

source src/git_version_semver_helper.sh
load test_helper

setup() {
  set_test_suite_tmpdir
  cd $BATS_TEST_SUITE_TMPDIR
  git init
  git checkout -b master
  touch file.txt
  git add file.txt
  git commit --no-gpg-sign -m "new file.txt"
  git tag "1.0.0"
}

@test "semver: current branch is master" {
  set_test_suite_tmpdir
  local branch=$(get_current_branch)
  [ $branch == "master" ]
}

@test "semver: latest tag in master is 1.0.0" {
  set_test_suite_tmpdir
  local tag=$(get_latest_version_git_tag)
  [ $tag == "1.0.0" ]
}
