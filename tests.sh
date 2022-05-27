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

# check dependencies
if ! which gh; then
  error 'Please install the "gh" cli tool!'
fi

if ! gh extensions list | cut -d "	" -f 1 | grep "gh codeql"; then
  gh extensions install github/gh-codeql
  error 'Please install the "gh codeq" extension!'
fi

if ! gh extensions list | cut -d "	" -f 1 | grep "gh tailor"; then
  error 'Please install the "gh tailor" extension!'
fi

#gh codeql download latest
#gh codeql set-version latest


# make tailored packs
for t in "$(ls "$LANG/tailor/")"; do
  PACK="$LANG/src/$t"
  TAILOR_PROJECT="$LANG/tailor/$t"

  rm -rf "$PACK"
  gh \
    tailor make \
    --outdir "$PACK" \
    "$TAILOR_PROJECT"
done


# build packs
PACKS="base local"

for P in $PACKS; do
  PACK="$LANG/src/$P"
  TEST_PACK="$LANG/test/$P"

  set +e
  gh \
    tailor compile \
    --strict \
    --autobump \
    "$PACK"

  RES="$?"
  if [ "$RES" = 2 ]; then
    echo "Version already exists. Skipping tests."
  elif [ "$RES" = 0 ]; then
    set -e

    # run corresponding test pack
    gh \
      codeql \
      pack install \
      --mode update \
      "$TEST_PACK"

    gh codeql test run "$TEST_PACK"

    # publish pack
    if [ "$PUBLISH" = "1" ]; then
      gh tailor publish "$PACK"
    fi
  else
    error "Build failed"
  fi
  set -e
done
