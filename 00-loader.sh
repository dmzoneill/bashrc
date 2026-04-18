#!/bin/bash

# Single loader for ~/.bashrc.d/scripts.d/
# Sources all scripts (which register secrets and set plain exports),
# then resolves secrets automatically via load-secrets.

# Source all scripts from scripts.d/ in order
for rc in ~/.bashrc.d/scripts.d/*.sh; do
    if [ -f "$rc" ]; then
        . "$rc" 2>/dev/null || echo "Failed to source: $rc" >&2
    fi
done
unset rc

# Resolve registered secrets (load-secrets handles missing TTY/gpg-agent gracefully)
load-secrets
