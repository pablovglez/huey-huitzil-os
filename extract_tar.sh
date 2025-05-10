#!/bin/bash

extract_tar() {
    case "$1" in
        *.tar.gz|*.tgz)    tar -xvzf "$1" -C builds/;;
        *.tar.bz2)         tar -xvjf "$1" -C builds/;;
        *.tar.xz)          tar -xvJf "$1" -C builds/;;
        *.tar.zst)         tar --zstd -xvf "$1" -C builds/;;
        *.tar)             tar -xvf "$1" -C builds/;;
        *)                 echo "Unsupported archive format: $1" ;;
    esac
}