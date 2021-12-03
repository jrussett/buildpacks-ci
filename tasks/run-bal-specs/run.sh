#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

go get -u github.com/onsi/ginkgo/ginkgo

cd "${SCRIPT_DIR}/buildpackapplifecycle"
ginkgo -r
