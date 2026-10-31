#!/bin/bash

_jcode_bin="$HOME/.local/bin/jcode"

jcode__socket_serving() {
    local socket="$1"
    [ -S "$socket" ] && ss -lx 2>/dev/null | grep -Fq -- "$socket"
}

jcode__socket_pid() {
    local socket="$1"
    ss -lxnp 2>/dev/null |
        grep -F -- "$socket" |
        sed -n 's/.*pid=\([0-9][0-9]*\).*/\1/p' |
        head -n 1
}

jcode__binary_exe() {
    local launcher
    launcher=$(readlink -f "$_jcode_bin") || return 1
    if [ -x "${launcher}-linux-x86_64.bin" ]; then
        printf '%s\n' "${launcher}-linux-x86_64.bin"
    else
        printf '%s\n' "$launcher"
    fi
}

jcode__server_matches() {
    local socket="$1" provider="$2" model="$3" pid exe args
    pid=$(jcode__socket_pid "$socket")
    [ -n "$pid" ] || return 1
    [ -r "/proc/$pid/exe" ] || return 1
    exe=$(readlink -f "/proc/$pid/exe" 2>/dev/null) || return 1
    [ "$exe" = "$(jcode__binary_exe)" ] || return 1
    args=$(tr '\0' ' ' <"/proc/$pid/cmdline" 2>/dev/null) || return 1

    case "$provider" in
        cursor)
            [[ "$args" == *" --provider cursor "* ]] || return 1
            ;;
        openai-api)
            [[ "$args" == *" --provider openai-api "* ]] || return 1
            [[ "$args" == *" --model $model "* ]] || return 1
            ;;
        enmaas)
            [[ "$args" == *" --provider-profile enmaas "* ]] || return 1
            [[ "$args" == *" --model enmaas:$model "* ]] || return 1
            ;;
        *)
            return 1
            ;;
    esac
}

jcode__remove_stale() {
    local socket="$1" debug_socket="${1%.sock}-debug.sock"
    if ! jcode__socket_serving "$socket"; then
        rm -f -- "$socket" "$socket.daemon.lock" "$socket.hash"
        if ! jcode__socket_serving "$debug_socket"; then
            rm -f -- "$debug_socket" "$debug_socket.daemon.lock" "$debug_socket.hash"
        fi
    fi
}

jcode__wait_for_socket() {
    local socket="$1" count
    for count in $(seq 1 100); do
        jcode__socket_serving "$socket" && return 0
        sleep 0.1
    done
    return 1
}

jcode__ensure_server() {
    local socket="$1" server_name="$2" provider="$3" model="$4" api_key="$5"
    local log="$HOME/.jcode/jcode-$server_name.log" pid
    local debug_socket="${socket%.sock}-debug.sock"

    if jcode__socket_serving "$socket"; then
        if jcode__server_matches "$socket" "$provider" "$model"; then
            return 0
        fi
        printf '%s: active socket has different Jcode binary/provider/model; refusing to replace it: %s\n' \
            "$server_name" "$socket" >&2
        return 1
    fi

    if jcode__socket_serving "$debug_socket"; then
        printf '%s: debug socket is active without a serving main socket; refusing to replace it: %s\n' \
            "$server_name" "$debug_socket" >&2
        return 1
    fi
    jcode__remove_stale "$socket"

    case "$provider" in
        cursor)
            nohup env \
                -u JCODE_HOME \
                -u JCODE_ACTIVE_PROVIDER \
                -u JCODE_RUNTIME_PROVIDER \
                -u JCODE_INITIAL_PROVIDER_EXPLICIT \
                -u JCODE_NAMED_PROVIDER_PROFILE \
                -u JCODE_PROVIDER_PROFILE_NAME \
                -u JCODE_PROVIDER_PROFILE_ACTIVE \
                -u ENMASS_API_KEY \
                -u OPENAI_API_KEY \
                -u OPENAI_MODEL \
                -u ANTHROPIC_API_KEY \
                -u OPENROUTER_API_KEY \
                "$_jcode_bin" \
                --no-update \
                --no-selfdev \
                --socket "$socket" \
                --provider cursor \
                serve \
                --server-name "$server_name" >"$log" 2>&1 </dev/null &
            ;;
        openai-api)
            nohup env \
                -u JCODE_HOME \
                -u JCODE_ACTIVE_PROVIDER \
                -u JCODE_RUNTIME_PROVIDER \
                -u JCODE_INITIAL_PROVIDER_EXPLICIT \
                -u JCODE_NAMED_PROVIDER_PROFILE \
                -u JCODE_PROVIDER_PROFILE_NAME \
                -u JCODE_PROVIDER_PROFILE_ACTIVE \
                -u ENMASS_API_KEY \
                -u OPENAI_MODEL \
                -u ANTHROPIC_API_KEY \
                -u OPENROUTER_API_KEY \
                OPENAI_API_KEY="$api_key" \
                "$_jcode_bin" \
                --no-update \
                --no-selfdev \
                --socket "$socket" \
                --provider openai-api \
                --model "$model" \
                serve \
                --server-name "$server_name" >"$log" 2>&1 </dev/null &
            ;;
        enmaas)
            nohup env \
                -u JCODE_ACTIVE_PROVIDER \
                -u JCODE_RUNTIME_PROVIDER \
                -u JCODE_INITIAL_PROVIDER_EXPLICIT \
                -u JCODE_SESSION_ID \
                -u JCODE_NON_INTERACTIVE \
                -u JCODE_SOCKET \
                -u JCODE_READY_FD \
                -u OPENAI_API_KEY \
                -u OPENAI_MODEL \
                -u ANTHROPIC_API_KEY \
                -u OPENROUTER_API_KEY \
                JCODE_HOME="$HOME/.jcode/enmaas-glm-home" \
                JCODE_NAMED_PROVIDER_PROFILE=enmaas \
                JCODE_PROVIDER_PROFILE_NAME=enmaas \
                JCODE_PROVIDER_PROFILE_ACTIVE=1 \
                ENMASS_API_KEY="$api_key" \
                "$_jcode_bin" \
                --no-update \
                --no-selfdev \
                --socket "$socket" \
                --provider-profile enmaas \
                --model "enmaas:$model" \
                serve \
                --server-name "$server_name" >"$log" 2>&1 </dev/null &
            ;;
        *)
            printf '%s: unsupported provider: %s\n' "$server_name" "$provider" >&2
            return 1
            ;;
    esac

    pid=$!
    if ! jcode__wait_for_socket "$socket"; then
        printf '%s: server failed to become ready; see %s\n' "$server_name" "$log" >&2
        return 1
    fi
    if ! jcode__server_matches "$socket" "$provider" "$model"; then
        printf '%s: started server does not match current Jcode binary/provider/model; see %s\n' \
            "$server_name" "$log" >&2
        return 1
    fi
    kill -0 "$pid" 2>/dev/null || true
}

jcode() {
    local socket="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/jcode.sock"
    jcode__ensure_server "$socket" jcode cursor '' '' || return
    "$_jcode_bin" --no-update --no-selfdev --socket "$socket" "$@"
}

jcode-oai() {
    local socket="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/jcode-oai.sock"
    local api_key="${OPENAI_API_KEY:-}"
    if [ -z "$api_key" ] && declare -F load-secrets >/dev/null; then
        api_key=$(load-secrets >/dev/null 2>&1 && printf '%s' "${OPENAI_API_KEY:-}")
    fi
    if [ -z "$api_key" ]; then
        printf 'jcode-oai: OPENAI_API_KEY unavailable\n' >&2
        return 1
    fi
    jcode__ensure_server "$socket" jcode-oai openai-api gpt-5.6-luna "$api_key" || return
    env \
        -u JCODE_HOME \
        -u JCODE_ACTIVE_PROVIDER \
        -u JCODE_RUNTIME_PROVIDER \
        -u JCODE_INITIAL_PROVIDER_EXPLICIT \
        -u JCODE_NAMED_PROVIDER_PROFILE \
        -u JCODE_PROVIDER_PROFILE_NAME \
        -u JCODE_PROVIDER_PROFILE_ACTIVE \
        -u ENMASS_API_KEY \
        -u OPENAI_MODEL \
        -u ANTHROPIC_API_KEY \
        -u OPENROUTER_API_KEY \
        OPENAI_API_KEY="$api_key" \
        "$_jcode_bin" --no-update --no-selfdev --socket "$socket" "$@"
}

jcode-en() {
    local socket="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/jcode-en.sock"
    local api_key="${ENMASS_API_KEY:-}"
    if [ -z "$api_key" ] && declare -F load-secrets >/dev/null; then
        api_key=$(load-secrets >/dev/null 2>&1 && printf '%s' "${ENMASS_API_KEY:-}")
    fi
    if [ -z "$api_key" ]; then
        printf 'jcode-en: ENMASS_API_KEY unavailable\n' >&2
        return 1
    fi
    jcode__ensure_server "$socket" jcode-en enmaas rits/zai-org/glm-5-3 "$api_key" || return
    env \
        -u JCODE_ACTIVE_PROVIDER \
        -u JCODE_RUNTIME_PROVIDER \
        -u JCODE_INITIAL_PROVIDER_EXPLICIT \
        -u JCODE_SESSION_ID \
        -u JCODE_NON_INTERACTIVE \
        -u JCODE_SOCKET \
        -u JCODE_READY_FD \
        -u OPENAI_API_KEY \
        -u OPENAI_MODEL \
        -u ANTHROPIC_API_KEY \
        -u OPENROUTER_API_KEY \
        JCODE_HOME="$HOME/.jcode/enmaas-glm-home" \
        JCODE_NAMED_PROVIDER_PROFILE=enmaas \
        JCODE_PROVIDER_PROFILE_NAME=enmaas \
        JCODE_PROVIDER_PROFILE_ACTIVE=1 \
        ENMASS_API_KEY="$api_key" \
        "$_jcode_bin" --no-update --no-selfdev --socket "$socket" "$@"
}
