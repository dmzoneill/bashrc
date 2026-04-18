#!/bin/bash

_lazy_pass ANTHROPIC_VERTEX_PROJECT_ID "bashrc.d/gcp-project-id"
export CLAUDE_CODE_USE_VERTEX="1"
_secret_alias GOOGLE_CLOUD_PROJECT ANTHROPIC_VERTEX_PROJECT_ID
