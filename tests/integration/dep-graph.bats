#!/usr/bin/env bats

load '/usr/lib/bats-support/load.bash'
load '/usr/lib/bats-assert/load.bash'
load '/usr/lib/bats-file/load.bash'

TEST_DIR="/var/tmp/kubler_tests"

@test "linear_depgraph" {
    rm -rf "${TEST_DIR}"
    mkdir -p "${TEST_DIR}"
    cp -a "tests/fixtures/namespaces/depgraph_linear" "${TEST_DIR}/"

    run ./bin/kubler --working-dir "${TEST_DIR}/depgraph_linear" dep-graph --as-raw-dot depgraph_linear
    
    assert_success
    assert_output -p '"scratch" -> "depgraph_linear/a" [label="kubler/bob"];'
    assert_output -p '"depgraph_linear/a" -> "depgraph_linear/b";'
    assert_output -p '"depgraph_linear/b" -> "depgraph_linear/c";'
}
