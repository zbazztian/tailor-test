#!/bin/sh
set -eu

error(){
  echo "$1"
  exit 1
}

LANG="$1"

if [ "${2:-0}" = "--publish" ]; then
  PUBLISH=1
else
  PUBLISH=0
fi

if ! which gh; then
  error 'Please install the "gh" cli tool!'
fi

# install dependencies
if ! gh extensions list | cut -d "	" -f 1 | grep "gh codeql"; then
  gh extensions install github/gh-codeql
fi

if ! gh extensions list | cut -d "	" -f 1 | grep "gh tailor"; then
  gh extensions install zbazztian/gh-tailor
fi

gh codeql download latest
gh codeql set-version latest

# build base pack
set +e

PACK="$LANG/src/base"
TEST_PACK="$LANG/test/base"

gh \
  tailor compile \
  --strict \
  --autobump \
  "$PACK"

RES="$?"
if [ "$RES" = 2 ]; then
  echo "Version already exists. Nothing left to do."
elif [ "$RES" = 0 ]; then
  set -e

  # run base tests
  gh \
    codeql \
    pack install \
    --mode update \
    "$TEST_PACK"

  gh codeql test run "$TEST_PACK"

  # publish base pack
  if [ "$PUBLISH" = "1" ]; then
    gh tailor publish "$PACK"
  fi
else
  error "Build failed"
fi


# build tailored packs
set +e
for t in "$(ls "$LANG/tailor/")"; do
  PACK="$LANG/src/$t"
  TEST_PACK="$LANG/test/$t"
  TAILOR_PROJECT="$LANG/tailor/$t"

  rm -rf "$PACK"
  gh \
    tailor create \
    --outdir "$PACK" \
    --strict \
    "$TAILOR_PROJECT"

  RES="$?"
  if [ "$RES" = 2 ]; then
    echo "Version already exists. Nothing left to do."
  elif [ "$RES" = 0 ]; then
    set -e

    # run tailor tests
    gh \
      codeql \
      pack install \
      --mode update \
      "$TEST_PACK"

    gh codeql test run "$TEST_PACK"

    # publish tailored pack
    if [ "$PUBLISH" = "1" ]; then
      gh tailor publish "$PACK"
    fi
  else
    error "Build failed"
  fi
done
