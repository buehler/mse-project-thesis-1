#!/bin/bash

pandoc main.md --metadata-file=metadata.yaml --filter pandoc-fignos -s -o project-proposal.pdf
