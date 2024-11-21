#!/bin/bash

source ./core/bpm-vars.sh
source ./core/sh-obj.sh
source ./core/arg.sh

source ./.installer/bash-insertion.sh
source ./.installer/compile.sh
source ./.installer/utils.sh
source ./.installer/steps.sh
source ./.installer/main.sh

main

if [ -e "./test.sh" ]; then
  echo "Runnning test script..."
  bash ./test.sh
fi
