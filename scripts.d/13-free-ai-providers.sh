#!/bin/bash

# Free tier AI provider API keys (loaded from pass via _lazy_pass)
# Keys added via: pass insert <provider>/key

# OpenRouter — 300+ models, 20 RPM free tier
_lazy_pass OPENROUTER_API_KEY "openrouter.ai/key"

# Groq — 320 tok/s, 30 RPM free
_lazy_pass GROQ_API_KEY "groq.com/key"

# Cerebras — 1M tokens/day free
_lazy_pass CEREBRAS_API_KEY "cerebras.ai/key"

# SambaNova — $5 free credits
_lazy_pass SAMBANOVA_API_KEY "sambanova.ai/key"

# Mistral — ~1B tokens/month (Experiment tier)
_lazy_pass MISTRAL_API_KEY "mistral.ai/key"

# NVIDIA NIM — add key: pass insert nvidia.com/nim-key
# _lazy_pass NVIDIA_API_KEY "nvidia.com/nim-key"

# Cloudflare Workers AI
_lazy_pass CLOUDFLARE_AI_TOKEN "cloudflare.com/key-claude"

# OmniRoute
_lazy_pass OMNIROUTE_API_KEY "omniroute.ai/key"
