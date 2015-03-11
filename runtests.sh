#!/bin/sh
mkdir -p ./bin
nim compile --out:../bin/runtests test/runall.nim && ./bin/runtests
