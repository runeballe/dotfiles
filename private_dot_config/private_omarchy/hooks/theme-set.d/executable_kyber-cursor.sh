#!/usr/bin/env bash
# Omarchy theme-set / post-boot hook: rebuild Kyber in the new accent.
# Installed by kyber-cursor's install.sh; does nothing unless Kyber is active.
[[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/kyber-cursor/active" ]] || exit 0
exec "/home/rune/.config/omarchy/plugins/io.github.s3pp3ku.kyber-cursor/bin/kyber" apply >/dev/null 2>&1
