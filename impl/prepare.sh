#!/usr/bin/env bash

[ ! -d uart_gowin ] && echo "Run the script in impl/ directory." && exit 1

PROJ_DIR=$(realpath ..)
FILES_TO_REPLACE=$(find uart_gowin -type f -print)

for file in $FILES_TO_REPLACE ; do
  if [ -v DEV ] ; then
    git update-index --skip-worktree "${file}"
  fi
  sed --in-place "s|\${PROJ_ROOT}/|${PROJ_DIR}/|" "${file}"
done

