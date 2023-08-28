# Package

version       = "0.1.0"
author        = "metagn"
description   = "tie compile-time values to types under names"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.0.0"

when (compiles do: import nimbleutils):
  import nimbleutils

task docs, "build docs for all modules":
  when declared(buildDocs):
    buildDocs(gitUrl = "https://github.com/metagn/knot")
  else:
    echo "docs task not implemented, need nimbleutils"

task tests, "run tests for multiple backends":
  when declared(runTests):
    runTests(backends = {c, nims})
  else:
    echo "tests task not implemented, need nimbleutils"
