#!/usr/bin/env bash


function get_commit_list_since() {
  local origin_commit=$1
  echo $(git log --pretty=%B $origin_commit..HEAD | tr -d '\n')
}

function get_current_commit_hash() {
  echo $(git rev-parse --verify HEAD --short)
}

function get_current_branch () {
  echo $(git symbolic-ref --short HEAD)
}

function get_current_year () {
  echo $(date +%Y)
}

function get_current_month () {
  echo $(date +%m)
}
