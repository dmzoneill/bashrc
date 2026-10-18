#!/bin/bash

# Non-obtrusive hints for legacy commands with modern alternatives.
# Writes to /dev/tty — invisible to pipes, redirects, and parsers.
# Only active in interactive shells with a real terminal.

[[ $- != *i* ]] && return
tty -s 2>/dev/null || return

declare -A _MODERN_HINTS=(
  # --- net-tools → iproute2 ---
  [ifconfig]="ip addr / ip link"
  [netstat]="ss"
  [route]="ip route"
  [arp]="ip neigh"
  [iptunnel]="ip tunnel"
  [nameif]="ip link set name"
  [iwconfig]="iw"
  [brctl]="ip link / bridge"
  [vconfig]="ip link add type vlan"
  [ifenslave]="ip link type bond"
  [tunctl]="ip tuntap"

  # --- firewall ---
  [iptables]="nft (nftables)"
  [ip6tables]="nft (nftables)"
  [ebtables]="nft (nftables)"
  [arptables]="nft (nftables)"

  # --- network diagnostics ---
  [traceroute]="mtr or trippy (real-time visualization)"
  [nslookup]="dig, dog, or doggo (DoH/DoT/DoQ support)"
  [ping]="gping (graphical) or prettyping (color-coded)"
  [telnet]="ncat or socat"
  [nc]="ncat (TLS support)"
  [tcpdump]="termshark (TUI wireshark)"
  [nmap]="rustscan (faster, feeds nmap)"
  [iftop]="bandwhich or nethogs"
  [whois]="whois (still standard)"

  # --- file transfer ---
  [scp]="rsync or sftp"
  [ftp]="sftp, lftp, or termscp (TUI multi-protocol)"
  [wget]="aria2c (parallel) or curl"

  # --- remote access ---
  [ssh]="mosh (roaming, intermittent connectivity)"

  # --- file viewing and listing ---
  [cat]="bat"
  [ls]="eza -l --icons"
  [less]="bat --paging=always"
  [more]="bat --paging=always"
  [tree]="broot or eza --tree"
  [xxd]="hexyl"
  [hexdump]="hexyl"
  [strings]="bingrep (structured binary inspection)"
  [objdump]="radare2 or binwalk"
  [nm]="bingrep (colorized binary parsing)"

  # --- file finding and searching ---
  [find]="fd"
  [grep]="rg (ripgrep)"
  [egrep]="grep -E"
  [fgrep]="grep -F"
  [ag]="rg (ripgrep)"
  [ack]="rg (ripgrep)"
  [locate]="plocate"

  # --- text processing ---
  [sed]="sd"
  [cut]="choose or tuc"
  [diff]="delta or difft (structural diff)"
  [wc]="tokei (code) or scc (code + complexity)"

  # --- json/yaml/csv ---
  [jq]="jless (interactive JSON viewer)"
  [xmlstarlet]="xq (via yq)"

  # --- disk and filesystem ---
  [du]="dust, ncdu, or gdu"
  [df]="duf"
  [rm]="rip or trash-cli (recoverable delete)"
  [cp]="xcp (progress bars, parallel copy)"

  # --- process and system monitoring ---
  [top]="btop or htop"
  [ps]="procs"
  [kill]="fkill (interactive)"
  [vmstat]="dool (formerly dstat)"
  [iostat]="dool (formerly dstat)"
  [free]="frei (color bar charts)"
  [strace]="bpftrace (eBPF, lower overhead)"
  [ltrace]="bpftrace (eBPF library tracing)"
  [time]="hyperfine (benchmarking)"
  [neofetch]="fastfetch"

  # --- log viewing ---
  [tail]="multitail or lnav (log navigator)"

  # --- system admin ---
  [hostname]="hostnamectl"
  [service]="systemctl"
  [chkconfig]="systemctl enable/disable"
  [crontab]="systemd-timer"
  [dmesg]="journalctl -k"
  [insmod]="modprobe"
  [rmmod]="modprobe -r"
  [fdisk]="gdisk or parted (GPT support)"
  [mount]="udisksctl (unprivileged)"
  [sudo]="sudo-rs (memory-safe Rust rewrite)"

  # --- binary location ---
  [which]="command -v"

  # --- shell and navigation ---
  [cd]="zoxide (frecency jump)"
  [history]="atuin (encrypted sync) or mcfly"
  [watch]="viddy (diff mode) or hwatch (history)"
  [screen]="tmux or zellij"
  [xargs]="parallel (GNU parallel)"
  [make]="just or task (go-task)"

  # --- http and api ---
  [curl]="httpie, xh, or curlie"

  # --- help and docs ---
  [man]="tldr, tealdeer (fast tldr), or navi (interactive)"

  # --- compression ---
  [gzip]="pigz (parallel) or zstd (better ratio+speed)"
  [bzip2]="zstd (better speed/ratio)"
  [xz]="zstd (better speed/ratio)"
  [zip]="7z (p7zip) or zstd"

  # --- git ---
  [gitk]="lazygit or gitui"
  [tig]="lazygit or gitui"

  # --- containers ---
  [docker]="podman (daemonless, rootless)"
  [docker-compose]="podman-compose or docker compose v2"

  # --- package management ---
  [yum]="dnf"
  [pip]="uv or pipx"
  [virtualenv]="python -m venv or uv venv"
  [nvm]="fnm or mise"
  [rbenv]="mise"
  [pyenv]="mise"

  # --- editors ---
  [vi]="nvim (neovim)"
  [nano]="micro"

  # --- terminal emulators ---
  [xterm]="alacritty, kitty, or ghostty"

  # --- file managers ---
  [mc]="yazi or xplr (TUI file manager)"
  [ranger]="yazi (async I/O, image preview)"

  # --- backup ---
  [rsync]="restic (encrypted, deduplicated backup)"
)

# Skip hints for commands already aliased TO their modern replacement.
# e.g. alias cat='bat' means cat hint is redundant — but alias ls='ls --color'
# should still hint because ls isn't aliased to eza.
for _cmd in "${!_MODERN_HINTS[@]}"; do
  _alias_def=$(alias "$_cmd" 2>/dev/null) || continue
  # Extract the first word of the alias target
  _alias_target="${_alias_def#*=\'}"
  _alias_target="${_alias_target#*=\"}"
  _alias_target="${_alias_target%% *}"
  _alias_target="${_alias_target%\'}"
  _alias_target="${_alias_target%\"}"
  # Extract the first word of the modern hint (before space/paren/slash)
  _hint_first="${_MODERN_HINTS[$_cmd]%% *}"
  _hint_first="${_hint_first%%(*}"
  _hint_first="${_hint_first%%/*}"
  # Only suppress if alias target matches the hint's recommended tool
  if [[ "$_alias_target" == "$_hint_first" ]]; then
    unset '_MODERN_HINTS[$_cmd]'
  fi
done
unset _cmd _alias_def _alias_target _hint_first

_modern_hint_check() {
  [[ -n "$COMP_LINE" ]] && return
  local cmd="${BASH_COMMAND%% *}"
  cmd="${cmd##*/}"
  local hint="${_MODERN_HINTS[$cmd]}"
  if [[ -n "$hint" ]]; then
    printf '\e[2m  hint: %s → %s\e[0m\n' "$cmd" "$hint" > /dev/tty
  fi
}

trap '_modern_hint_check' DEBUG
