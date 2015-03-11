#!/bin/sh
nim compile --out:../bin/runtests test/runall.nim && ./bin/runtests
