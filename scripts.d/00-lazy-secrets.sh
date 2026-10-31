#!/bin/bash

# Lazy-load secrets from pass - secrets are resolved on-demand via `load-secrets`
# instead of blocking shell init with gpg/pinentry calls.
# Decrypted values are cached in the Linux kernel keyring for fast subsequent loads.

_pass_secrets=()
_secret_aliases=()

LAZY_SECRETS_TTL="${LAZY_SECRETS_TTL:-28800}"

_lazy_pass() {
	local var="$1" path="$2"
	_pass_secrets+=("${var}:${path}")
}

_secret_alias() {
	local alias_var="$1" source_var="$2"
	_secret_aliases+=("${alias_var}:${source_var}")
}

_keyring_get() {
	local key_id
	key_id=$(keyctl search @u user "pass:$1" 2>/dev/null) || return 1
	keyctl pipe "$key_id" 2>/dev/null
}

_keyring_set() {
	local key_id
	key_id=$(keyctl add user "pass:$1" "$2" @u 2>/dev/null) || return 1
	keyctl timeout "$key_id" "$LAZY_SECRETS_TTL" 2>/dev/null
}

_keyring_clear() {
	local key_id
	for entry in "${_pass_secrets[@]}"; do
		local path="${entry#*:}"
		key_id=$(keyctl search @u user "pass:$path" 2>/dev/null) &&
			keyctl unlink "$key_id" @u 2>/dev/null
	done
}

load-secrets() {
	local refresh=false
	if [[ "$1" = "--refresh" ]] || [[ "$1" = "-r" ]]; then
		refresh=true
		shift
	fi

	if ! command -v keyctl &>/dev/null; then
		refresh=true
	fi

	# Load from keyring cache first, track misses
	local cached=0 missed=0
	local -a _missed_secrets=()

	if ! $refresh; then
		for entry in "${_pass_secrets[@]}"; do
			local var="${entry%%:*}"
			local path="${entry#*:}"
			local val
			if val=$(_keyring_get "$path") && [[ -n "$val" ]]; then
				export "$var"="$val"
				cached=$((cached + 1))
			else
				_missed_secrets+=("$entry")
				missed=$((missed + 1))
			fi
		done

		if [[ $missed -eq 0 ]]; then
			for entry in "${_secret_aliases[@]}"; do
				local var="${entry%%:*}"
				local src="${entry#*:}"
				export "$var"="${!src}"
			done
			echo "Secrets loaded from cache ($cached cached, ${#_secret_aliases[@]} aliases)"
			return 0
		fi
	else
		_missed_secrets=("${_pass_secrets[@]}")
		missed=${#_pass_secrets[@]}
	fi

	# Only decrypt the missed secrets
	if [[ $missed -eq 0 ]]; then
		return 0
	fi

	if ! timeout 2 gpg-connect-agent /bye &>/dev/null; then
		if ! tty -s 2>/dev/null; then
			echo "Loaded $cached from cache, $missed skipped (no gpg-agent/TTY)" >&2
			return 1
		fi
		echo "gpg-agent not responding - cannot load secrets" >&2
		return 1
	fi

	local tmpdir
	tmpdir=$(mktemp -d)

	# Probe with first missed secret to warm gpg-agent
	local probe_entry="${_missed_secrets[0]}"
	local probe_var="${probe_entry%%:*}"
	local probe_path="${probe_entry#*:}"
	if ! timeout 5 pass show "$probe_path" >"$tmpdir/$probe_var" 2>/dev/null; then
		echo "pass timed out - loaded $cached from cache, $missed skipped" >&2
		rm -rf "$tmpdir"
		return 1
	fi

	# Decrypt remaining misses (agent is warm now)
	local entry var path
	for entry in "${_missed_secrets[@]:1}"; do
		var="${entry%%:*}"
		path="${entry#*:}"
		timeout 10 pass show "$path" 2>/dev/null >"$tmpdir/$var"
	done

	# Read results into environment and cache in keyring
	local decrypted=0
	for entry in "${_missed_secrets[@]}"; do
		var="${entry%%:*}"
		path="${entry#*:}"
		if [[ -f "$tmpdir/$var" ]] && [[ -s "$tmpdir/$var" ]]; then
			local val
			val=$(cat "$tmpdir/$var")
			export "$var"="$val"
			_keyring_set "$path" "$val" 2>/dev/null
			decrypted=$((decrypted + 1))
		fi
	done

	rm -rf "$tmpdir"

	# Set aliases
	for entry in "${_secret_aliases[@]}"; do
		var="${entry%%:*}"
		path="${entry#*:}"
		export "$var"="${!path}"
	done

	echo "Secrets loaded ($cached cached, $decrypted decrypted, ${#_secret_aliases[@]} aliases)"
}

clear-secrets() {
	_keyring_clear
	for entry in "${_pass_secrets[@]}"; do
		unset "${entry%%:*}"
	done
	for entry in "${_secret_aliases[@]}"; do
		unset "${entry%%:*}"
	done
	echo "Secrets cleared from environment and cache"
}
