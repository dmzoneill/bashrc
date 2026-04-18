#!/bin/bash

# Red Hat Slack
_lazy_pass SLACK_HOST "bashrc.d/slack-host"
_lazy_pass SLACK_ENTERPRISE_ID "bashrc.d/slack-enterprise-id"

# Fetch xoxc_token and d_cookie from Chrome (quiet, no stderr noise)
if command -v get-slack-creds &>/dev/null; then
    eval "$(get-slack-creds --quiet 2>/dev/null)" 2>/dev/null || true
fi

# Konflux Slack webhook
_lazy_pass SLACK_WEBHOOK_KONFLUX "redhat.com/slack-webhook-konflux"

# slack-query CLI tab completion
if command -v slack-query &>/dev/null; then
    eval "$(slack-query --_completion)"
fi
