#!/bin/bash

pandoc \
    --filter pandoc-xnos \
    --metadata-file=metadata.yaml \
    --standalone \
    --output=project-proposal.pdf \
    main.md
