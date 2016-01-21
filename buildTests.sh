#!/bin/bash

#  buildTests.sh
#  PhoenixTestFramework
#
#  Created by Samuel Kallner on 22/12/2015.
#  Copyright © 2015 IBM. All rights reserved.

# If not in the PhoenixTestFramework i was copied from there to ease usage

SCRIPT_DIR=$(dirname "$BASH_SOURCE")
cd "$SCRIPT_DIR"

if [ -f "./mainBuildTests.sh" ]; then
    if [ -x "./mainBuildTests.sh" ]; then
        ./mainBuildTests.sh
    else
        echo "Main test builder script isn't executable"
        exit 1
    fi
else
    fwDir="!"
    for  dir in Packages/PhoenixTestFramework* ; do
        fwDir=$dir
    done
    if [[ "${fwDir}" !=  "!"  &&  -d "${fwDir}" ]]; then
        "${fwDir}/TestFramework/mainBuildTests.sh"
    else
        echo "Didn't find the Phoenix test framework"
        exit 1
    fi
fi
