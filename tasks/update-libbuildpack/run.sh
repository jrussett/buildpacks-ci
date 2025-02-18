#!/bin/bash -l

set -o errexit
set -o nounset
set -o pipefail

set -x

if [ "$LANGUAGE" = "multi" ]; then
  update_dir="src/compile"
elif [ "$LANGUAGE" = "dotnet-core" ]; then
  update_dir="src/dotnetcore"
else
  update_dir="src/$LANGUAGE"
fi

pushd buildpack
  source .envrc

  go get -u github.com/cloudfoundry/libbuildpack
  go get github.com/golang/mock/gomock
  go get -u github.com/onsi/ginkgo/ginkgo
  pushd /tmp
    go install github.com/golang/mock/mockgen@latest
  popd
  go mod tidy
  if [[ "$LANGUAGE" != "php" || "$SHIM" == "true" ]]; then
    go mod vendor
  fi

  # for the PHP buildpack
  if [ -e run_tests.sh ]; then
    TMPDIR=$(mktemp -d)
    export TMPDIR
    pip install -r requirements.txt
  fi

  if [[ -d "$update_dir" ]]; then
    pushd "$update_dir"

      go generate || true
      [ -d compile ] && (cd compile && (go generate || true))
      [ -d hooks ] && (cd hooks && (go generate || true))
      [ -d supply ] && (cd supply && (go generate || true))
      [ -d finalize ] && (cd finalize && (go generate || true))

      export CF_STACK=${CF_STACK:-cflinuxfs3}
      if [[ "$LANGUAGE" != "php" || "$SHIM" == "true" ]]; then
            ginkgo -r -mod=vendor -skipPackage=integration,brats
      else
            ginkgo -r -skipPackage=integration,brats
      fi
    popd
  fi

  git add .

  set +e
    git diff --cached --exit-code
    no_changes=$?
  set -e

  if [ $no_changes -ne 0 ]
  then
    git commit -m "Update libbuildpack"
  else
    echo "libbuildpack is up to date"
  fi
popd
