#!/bin/bash

set -euxo pipefail

target=$(basename "$1" .md)

pandoc \
    --lua-filter=lib/lua-filters/include-files/include-files.lua \
    --filter pandoc-xnos \
    --lua-filter=lib/custom/plantuml-converter.lua \
    --lua-filter=lib/lua-filters/short-captions/short-captions.lua \
    --metadata-file=./section-metadata.yaml \
    --citeproc \
    --bibliography=./bibliography.bib \
    --standalone \
    --output=public/$target.pdf \
    ./sections/$target.md
