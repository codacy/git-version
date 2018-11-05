#!/usr/bin/env bats

source src/git_version_semver_helper.sh
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
  git tag "1.0.0"

  # Checkout to dev from master and add a commit and tag
  git checkout -b dev
  touch file2.txt
  git add file2.txt
  git commit --no-gpg-sign -m "new file2.txt"
}

@test "semver: current branch is dev" {
  set_test_suite_tmpdir
  local branch=$(get_current_branch)
  [ $branch == "dev" ]
}

@test "semver: current tag in dev matches 1.0.0-1*" {
  set_test_suite_tmpdir
  local tag=$(get_suffixed_git_tag)
  [[ $tag =~ "1.0.0-1" ]]
}
