#!/bin/bash

# GitLab
_lazy_pass GITLAB_TOKEN "redhat.com/gitlab-notifier"
_secret_alias GITLAB_API_TOKEN GITLAB_TOKEN
_secret_alias GITLAB_NOTIFIER GITLAB_TOKEN
