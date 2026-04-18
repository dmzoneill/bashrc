#!/bin/bash

# Lazy-load secrets from pass - secrets are resolved on-demand via `load-secrets`
# instead of blocking shell init with gpg/pinentry calls.

_pass_secrets=()
_secret_aliases=()

# Register a secret for lazy loading
# Usage: _lazy_pass VAR_NAME "pass/path"
_lazy_pass() {
    local var="$1" path="$2"
    _pass_secrets+=("${var}:${path}")
}

# Register an alias that mirrors another variable after secrets load
# Usage: _secret_alias ALIAS_VAR SOURCE_VAR
_secret_alias() {
    local alias_var="$1" source_var="$2"
    _secret_aliases+=("${alias_var}:${source_var}")
}

# Resolve all registered secrets in parallel, then set aliases
load-secrets() {
    local entry var path tmpdir pids=()

    # Check gpg-agent health first
    if ! timeout 2 gpg-connect-agent /bye &>/dev/null; then
        # No gpg-agent — need TTY for pinentry, bail if none
        if ! tty -s 2>/dev/null; then
            echo "No gpg-agent and no TTY - skipping secrets" >&2
            return 1
        fi
        echo "gpg-agent not responding - cannot load secrets" >&2
        return 1
    fi

    tmpdir=$(mktemp -d)

    # Probe with the first secret to detect a hung pass/pinentry
    if [ ${#_pass_secrets[@]} -gt 0 ]; then
        local probe_entry="${_pass_secrets[0]}"
        local probe_var="${probe_entry%%:*}"
        local probe_path="${probe_entry#*:}"
        if ! timeout 5 pass show "$probe_path" > "$tmpdir/$probe_var" 2>/dev/null; then
            echo "pass timed out or failed - skipping secrets" >&2
            rm -rf "$tmpdir"
            return 1
        fi
    fi

    # Probe succeeded - load remaining secrets in parallel
    for entry in "${_pass_secrets[@]:1}"; do
        var="${entry%%:*}"
        path="${entry#*:}"
        ( timeout 5 pass show "$path" 2>/dev/null > "$tmpdir/$var" ) &
        pids+=($!)
    done

    # Wait for all to complete
    for pid in "${pids[@]}"; do
        wait "$pid" 2>/dev/null
    done

    # Read results into environment
    for entry in "${_pass_secrets[@]}"; do
        var="${entry%%:*}"
        if [ -f "$tmpdir/$var" ]; then
            export "$var"="$(cat "$tmpdir/$var")"
        fi
    done

    rm -rf "$tmpdir"

    # Set aliases
    for entry in "${_secret_aliases[@]}"; do
        var="${entry%%:*}"
        path="${entry#*:}"
        export "$var"="${!path}"
    done

    echo "Secrets loaded (${#_pass_secrets[@]} secrets, ${#_secret_aliases[@]} aliases)"
}
