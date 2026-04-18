#!/bin/bash

# AI / LLM API keys
_lazy_pass AI_API_KEY "openai.com/api-key"
_secret_alias OPENAI_API_KEY AI_API_KEY
export OPENAI_MODEL="gpt-4o-mini"
export AI_MODEL="$OPENAI_MODEL"
