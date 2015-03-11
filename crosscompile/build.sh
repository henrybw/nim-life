#!/bin/sh

if [ $# -lt 1 ]; then
    echo "usage: $0 target"
    exit 1
fi

nim c --compileOnly --cc:clang --genScript $@ &&
cat nimcache/system.c | sed -e 's,MAP_ANONYMOUS,MAP_ANON,g' > nimcache/system.new.c &&
mv nimcache/system.new.c nimcache/system.c