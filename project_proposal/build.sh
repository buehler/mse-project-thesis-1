#!/bin/bash

pandoc \
    --filter pandoc-xnos \
    --lua-filter=../../filters/scholarly-metadata.lua \
    --lua-filter=../../filters/author-info-blocks.lua \
    --metadata-file=metadata.yaml \
    --standalone \
    --output=project-proposal.pdf \
    main.md