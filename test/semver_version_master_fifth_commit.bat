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
  git tag "1.1.0"

  touch file1.txt
  git add file1.txt
  git commit --no-gpg-sign -m "new file1.txt"
  git tag "1.1.2"

  touch file2.txt
  git add file2.txt
  git commit --no-gpg-sign -m "new file2.txt"

  touch file3.txt
  git add file3.txt
  git commit --no-gpg-sign -m "new file3.txt"

  touch file4.txt
  git add file4.txt
  git commit --no-gpg-sign -m "new file4.txt"
}

@test "current branch is master" {
  set_test_suite_tmpdir
  local branch=$(get_current_branch)
  echo $branch
  [ $branch == "master" ]
}

@test "latest tag in master is 1.1.2" {
  set_test_suite_tmpdir
  local tag=$(get_latest_version_git_tag)
  [ $tag == "1.1.2" ]
}

@test "bumped version matches 1.1.3" {
  set_test_suite_tmpdir
  local latest_tag=$(get_latest_version_git_tag)
  local new_tag=$(bump_date_version $latest_tag)
  [[ $new_tag =~ "1.1.3" ]]
}
