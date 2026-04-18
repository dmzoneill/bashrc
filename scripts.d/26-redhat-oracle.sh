#!/bin/bash

# redhat-oracle - maps generic tokens to project-specific names
_secret_alias ORACLE_GITHUB_TOKEN GITHUB_TOKEN
_secret_alias ORACLE_GITLAB_TOKEN GITLAB_TOKEN
_secret_alias ORACLE_JIRA_TOKEN JIRA_JPAT
export ORACLE_SLACK_TOKEN=""
_secret_alias ORACLE_SLACK_XOXC_TOKEN SLACK_XOXC_TOKEN
_secret_alias ORACLE_SLACK_D_COOKIE SLACK_D_COOKIE
