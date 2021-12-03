#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ROOT_DIR="$( realpath "${SCRIPT_DIR}/../../.." )"
GO_BIN="${ROOT_DIR}/go/bin"
PATH="${GO_BIN}:${PATH}"

mkdir -p "${GO_BIN}"
go install github.com/onsi/ginkgo/ginkgo@latest


cd "${ROOT_DIR}/bal-develop"
ginkgo -r
