#!/bin/bash

set -euo pipefail

# rm -rf public/*

pandoc \
    --lua-filter=lib/lua-filters/include-files/include-files.lua \
    --filter pandoc-xnos \
    --lua-filter=lib/custom/plantuml-converter.lua \
    --lua-filter=lib/lua-filters/short-captions/short-captions.lua \
    --metadata-file=./metadata.yaml \
    --citeproc \
    --bibliography=./bibliography.bib \
    --toc \
    --standalone \
    --output=public/index.html \
    ./sections/*.md

pandoc \
    --lua-filter=lib/lua-filters/include-files/include-files.lua \
    --filter pandoc-xnos \
    --lua-filter=lib/custom/plantuml-converter.lua \
    --lua-filter=lib/lua-filters/short-captions/short-captions.lua \
    --metadata-file=./metadata.yaml \
    --citeproc \
    --bibliography=./bibliography.bib \
    --toc \
    --standalone \
    --output=public/report.pdf \
    ./sections/*.md

cp -R images public/
cp -R diagrams public/
