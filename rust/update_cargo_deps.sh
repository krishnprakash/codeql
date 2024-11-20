#!/bin/bash

set -eu

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cd "$SCRIPT_DIR/.."
time bazel run //misc/bazel/3rdparty:vendor_tree_sitter_extractors
bazel mod tidy
