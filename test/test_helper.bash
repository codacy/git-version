fixtures() {
  FIXTURE_ROOT="$BATS_TEST_DIRNAME/fixtures/$1"
  bats_trim_filename "$FIXTURE_ROOT" 'RELATIVE_FIXTURE_ROOT'
}

set_test_suite_tmpdir() {
  export BATS_TEST_SUITE_TMPDIR="$BATS_TMPDIR/tmpdir"
  mkdir -p "$BATS_TEST_SUITE_TMPDIR"
}

teardown() {
  if [[ -n "$BATS_TEST_SUITE_TMPDIR" ]]; then
    rm -rf "$BATS_TEST_SUITE_TMPDIR"
  fi
}
