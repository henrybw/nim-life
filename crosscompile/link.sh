#!/bin/sh

if [ $# -ne 1 ]; then
    echo "usage: $0 target"
    exit 1
fi

cd nimcache &&
sh "../compile_$1.sh" &&
mv "$1" .. &&
cd ..