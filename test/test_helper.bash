#!/usr/bin/env bash

set_test_suite_tmpdir() {
  export BATS_TEST_SUITE_TMPDIR="$BATS_TMPDIR/tmpdir"
  mkdir -p "$BATS_TEST_SUITE_TMPDIR"
}

teardown() {
  if [[ -n "$BATS_TEST_SUITE_TMPDIR" ]]; then
    rm -rf "$BATS_TEST_SUITE_TMPDIR"
  fi
}
