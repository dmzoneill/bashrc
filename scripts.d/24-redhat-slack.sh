#!/bin/bash

# Red Hat Slack
# Slack workspace settings are identifiers, not secrets.
export SLACK_HOST="${SLACK_HOST:-redhat.enterprise.slack.com}"
export SLACK_ENTERPRISE_ID="${SLACK_ENTERPRISE_ID:-E030G10V24F}"

# Fetch xoxc_token and d_cookie from Chrome
if command -v get-slack-creds &>/dev/null; then
    if ! _slack_creds=$(get-slack-creds 2>&1); then
        printf '%s\n' "$_slack_creds" >&2
        echo "Slack credential extraction failed; Slack MCP may be unavailable." >&2
    else
        eval "$_slack_creds"
    fi
    unset _slack_creds
fi

# Konflux Slack webhook
_lazy_pass SLACK_WEBHOOK_KONFLUX "redhat.com/slack-webhook-konflux"

# slack-query CLI tab completion
if [ "${SLACK_MCP:-}" != "1" ] && command -v slack-query &>/dev/null; then
    eval "$(slack-query --_completion)"
fi
