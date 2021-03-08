#!/bin/bash

set -euo pipefail

rm -rf public/*

pandoc \
    --filter pandoc-xnos \
    --lua-filter=lib/lua-filters/scholarly-metadata/scholarly-metadata.lua \
    --lua-filter=lib/lua-filters/author-info-blocks/author-info-blocks.lua \
    --metadata-file=src/metadata.yaml \
    --citeproc \
    --bibliography=src/bibliography.bib \
    --toc \
    --standalone \
    --output=public/index.html \
    src/sections/*.md

pandoc \
    --filter pandoc-xnos \
    --lua-filter=lib/lua-filters/scholarly-metadata/scholarly-metadata.lua \
    --lua-filter=lib/lua-filters/author-info-blocks/author-info-blocks.lua \
    --metadata-file=src/metadata.yaml \
    --citeproc \
    --bibliography=src/bibliography.bib \
    --toc \
    --standalone \
    --output=public/report.pdf \
    src/sections/*.md
