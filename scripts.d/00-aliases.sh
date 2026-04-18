#!/bin/bash

alias c='claude'
alias c-r='claude -r'
alias c-c='claude -c'
alias c-s='claude --style compact'
alias c-d="claude --dangerously-skip-permissions"
alias gfur='MAIN=`git remote show upstream | grep "HEAD branch" | cut -d ":" -f 2 | xargs` && git fetch upstream && git rebase upstream/$MAIN'

# CSB VM console (virt-manager SPICE viewer is broken, use remote-viewer)
alias csb-console='remote-viewer --hotkeys=release-cursor=shift+f12 spice://127.0.0.1:5900 &'

# OpenShift/Kubernetes helpers
# kube <env> [namespace] - login via rhtoken, save kubeconfig, optionally set namespace
# kube-clean <env>       - remove all kubeconfig files for env and unset KUBECONFIG
kube() {
  local env="$1"
  local ns="$2"
  if [[ -z "$env" ]]; then
    echo "Usage: kube <env> [namespace]"
    echo "  env       - single letter environment (e.g. e, p, s, k)"
    echo "  namespace - optional namespace; creates config.<env>.<namespace>"
    return 1
  fi
  local kubeconfig="$HOME/.kube/config.${env}"
  # Login if base config doesn't exist
  if [[ ! -f "$kubeconfig" ]]; then
    echo "Fetching token for environment '${env}'..."
    local login_cmd
    login_cmd=$(rhtoken -q "$env" 2>/dev/null | grep '^oc login')
    if [[ -z "$login_cmd" ]]; then
      echo "Error: failed to get login command from rhtoken for '${env}'"
      return 1
    fi
    export KUBECONFIG="$kubeconfig"
    eval "$login_cmd"
  fi
  if [[ -n "$ns" ]]; then
    if [[ ! -f "$kubeconfig" ]]; then
      echo "Error: base config '$kubeconfig' not found. Run 'kube ${env}' first."
      return 1
    fi
    local ns_kubeconfig="$HOME/.kube/config.${env}.${ns}"
    cp "$kubeconfig" "$ns_kubeconfig"
    export KUBECONFIG="$ns_kubeconfig"
    oc config set-context --current --namespace="$ns"
    echo "KUBECONFIG set to $ns_kubeconfig (namespace: $ns)"
  else
    export KUBECONFIG="$kubeconfig"
    echo "KUBECONFIG set to $kubeconfig"
  fi
}

# gabi <query> - run a SQL query against the GABI instance in the current namespace
# Auto-discovers the GABI route and uses the token from the current KUBECONFIG context
gabi() {
  local query="$*"
  if [[ -z "$query" ]]; then
    echo "Usage: gabi <query>"
    echo "  query - SQL query string (e.g. gabi \"\\l;\")"
    echo ""
    echo "Requires: active KUBECONFIG pointed at a namespace with a GABI route"
    return 1
  fi
  if [[ -z "$KUBECONFIG" || ! -f "$KUBECONFIG" ]]; then
    echo "Error: no KUBECONFIG set. Run 'kube <env> [namespace]' first."
    return 1
  fi
  local token
  token=$(oc whoami -t 2>/dev/null)
  if [[ -z "$token" ]]; then
    echo "Error: could not extract token. Is your session valid?"
    return 1
  fi
  local endpoint
  endpoint=$(oc get routes -o json 2>/dev/null | jq -r '.items[] | select(.metadata.name | startswith("gabi-")) | .spec.host' | head -1)
  if [[ -z "$endpoint" ]]; then
    echo "Error: no GABI route found in current namespace ($(oc project -q 2>/dev/null))"
    return 1
  fi
  curl -s -H "Authorization: Bearer ${token}" \
    "https://${endpoint}/query" \
    -d "{\"query\": \"${query}\"}" | jq
}

kube-clean() {
  local env="$1"
  if [[ -z "$env" ]]; then
    echo "Usage: kube-clean <env>"
    return 1
  fi
  local files=("$HOME"/.kube/config."${env}"*)
  if [[ -e "${files[0]}" ]]; then
    rm -f "${files[@]}"
    printf 'Removed %s\n' "${files[@]}"
  else
    echo "No kubeconfig files found for environment '${env}'"
  fi
  if [[ "$KUBECONFIG" == "$HOME/.kube/config.${env}"* ]]; then
    unset KUBECONFIG
    echo "KUBECONFIG unset"
  fi
}
