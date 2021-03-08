#!/bin/bash

set -euo pipefail

rm -rf public && mkdir public

pandoc \
    --filter pandoc-xnos \
    --lua-filter=filters/scholarly-metadata.lua \
    --lua-filter=filters/author-info-blocks.lua \
    --metadata-file=src/metadata.yaml \
    --citeproc \
    --bibliography=src/bibliography.bib \
    --toc \
    --standalone \
    --output=public/index.html \
    src/sections/*.md

pandoc \
    --filter pandoc-xnos \
    --lua-filter=filters/scholarly-metadata.lua \
    --lua-filter=filters/author-info-blocks.lua \
    --metadata-file=src/metadata.yaml \
    --citeproc \
    --bibliography=src/bibliography.bib \
    --toc \
    --standalone \
    --output=public/report.pdf \
    src/sections/*.md
