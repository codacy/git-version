#!/usr/bin/env bats

source src/git_version_date_helper.sh
load test_helper
fixtures suite

year=$(get_current_year)
month=$(get_current_month)

setup() {
  set_test_suite_tmpdir
  cd $BATS_TEST_SUITE_TMPDIR
  git init

  # Checkout to master and add one commit and a tag

  git checkout -b master
  touch file.txt
  git add file.txt
  git commit --no-gpg-sign -m "new file.txt"
  git tag "1970.01.1"

  # Checkout to dev from master and add a commit
  git checkout -b dev
  touch file2.txt
  git add file2.txt
  git commit --no-gpg-sign -m "new file2.txt"

  # Checkout to FT-1111 from dev and add a commit
  git checkout -b FT-1111
  touch file3.txt
  git add file3.txt
  git commit --no-gpg-sign -m "new file3.txt"

  # Checkout dev and merge FT-1111
  git checkout dev
  git merge FT-1111

  # Checkout master and merge dev
  git checkout master
  git merge dev
}

@test "current branch is master" {
  set_test_suite_tmpdir
  branch=$(get_current_branch .)
  [ $branch == "master" ]
}

@test "current tag in master matches 1970.01.1" {
  set_test_suite_tmpdir
  tag=$(get_latest_version_git_tag .)
  [[ $tag =~ "1970.01.1" ]]
}

@test "bumped version matches $year.$month.1" {
  set_test_suite_tmpdir
  latest_tag=$(get_latest_version_git_tag .)
  new_tag=$(bump_date_version $latest_tag)
  bump_date_version
  [[ $new_tag =~ "$year.$month.1" ]]
}
