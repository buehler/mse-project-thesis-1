#!/bin/bash

set -euo pipefail

# rm -rf public/*

PLANTUML_BIN=/c/Users/cbueh/scoop/shims/plantuml.cmd pandoc \
    --filter pandoc-xnos \
    --lua-filter=lib/custom/plantuml-converter.lua \
    --lua-filter=lib/lua-filters/short-captions/short-captions.lua \
    --lua-filter=lib/lua-filters/scholarly-metadata/scholarly-metadata.lua \
    --lua-filter=lib/lua-filters/author-info-blocks/author-info-blocks.lua \
    --metadata-file=./metadata.yaml \
    --citeproc \
    --bibliography=./bibliography.bib \
    --toc \
    --standalone \
    --output=public/index.html \
    ./sections/*.md

# PLANTUML_BIN=/c/Users/cbueh/scoop/shims/plantuml.cmd pandoc \
#     --filter pandoc-xnos \
#     --lua-filter=lib/custom/plantuml-converter.lua \
#     --lua-filter=lib/lua-filters/short-captions/short-captions.lua \
#     --lua-filter=lib/lua-filters/scholarly-metadata/scholarly-metadata.lua \
#     --lua-filter=lib/lua-filters/author-info-blocks/author-info-blocks.lua \
#     --metadata-file=./metadata.yaml \
#     --citeproc \
#     --bibliography=./bibliography.bib \
#     --toc \
#     --standalone \
#     --output=public/report.pdf \
#     ./sections/*.md

cp -R images public/images
cp -R diagrams public/diagrams
