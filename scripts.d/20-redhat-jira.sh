#!/bin/bash

# Red Hat Jira - secrets
_lazy_pass JIRA_JPAT "redhat.com/jira-ticket-closer"
_secret_alias JPAT JIRA_JPAT
_secret_alias JIRA_AI_API_KEY AI_API_KEY

# Red Hat Jira - instance config
_lazy_pass JIRA_URL "bashrc.d/jira-url"
_lazy_pass JIRA_PROJECT_KEY "bashrc.d/jira-project-key"
_lazy_pass JIRA_BOARD_ID "bashrc.d/jira-board-id"
_lazy_pass JIRA_EMAIL "bashrc.d/jira-email"
_lazy_pass JIRA_COMPONENT_NAME "bashrc.d/jira-component"

# Red Hat Jira - custom fields (updated for Cloud migration)
export JIRA_EPIC_FIELD="customfield_10014"
export JIRA_EPIC_NAME_FIELD="customfield_10011"
export JIRA_STORY_POINTS_FIELD="customfield_10028"
export JIRA_SPRINT_FIELD="customfield_10020"
export JIRA_ACCEPTANCE_CRITERIA_FIELD="customfield_10718"
export JIRA_BLOCKED_FIELD="customfield_10517"
export JIRA_BLOCKED_REASON_FIELD="customfield_10483"
export JIRA_WORKSTREAM_FIELD="customfield_10681"

# Red Hat Jira - defaults
export JIRA_PRIORITY="Normal"
export JIRA_AFFECTS_VERSION="all"
export JIRA_AI_PROVIDER="vertex"
export JIRA_AI_MODEL="claude-sonnet-4-6@20250514"

# jira-query CLI tab completion
if command -v jira-query &>/dev/null; then
    eval "$(jira-query --_completion)"
fi
