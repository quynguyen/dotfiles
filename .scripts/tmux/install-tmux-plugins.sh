#!/bin/bash

echo "********************************************************************************"
echo "Installing Tmux plugins"
echo "********************************************************************************"

# Only tpm is ours to manage here. A bare `git submodule update` would also
# walk unrelated gitlinks in the repo and die on any that lack a .gitmodules
# entry ("fatal: No url found for submodule path ..."), taking the whole
# bootstrap with it, since install.sh runs under `set -e`.
TPM_SUBMODULE=".stow-packages/tmux/.tmux/plugins/tpm"

# tpm reads the plugin list from the first config it finds and prefers
# $XDG_CONFIG_HOME/tmux/tmux.conf over ~/.tmux.conf. On Omarchy that path holds
# the OS's own tmux config, which has none of our `@plugin` lines, so tpm would
# find zero plugins and exit silently having installed nothing. Run it with a
# config home that has no tmux.conf so it falls back to ~/.tmux.conf, which is
# ours. (See _get_user_tmux_conf in tpm/scripts/helpers/plugin_functions.sh.)
tpm_run() {
	local xdg_shim
	xdg_shim="$(mktemp -d)"
	XDG_CONFIG_HOME="$xdg_shim" "$@"
	local status=$?
	rm -rf "$xdg_shim"
	return $status
}

# Install or Update plugins
if [[ ! -f ~/.tmux/plugins/tpm/bin/install_plugins ]]; then
	# Install plugins
	git submodule update --init --remote --merge -- "$TPM_SUBMODULE"
	tpm_run ~/.tmux/plugins/tpm/bin/install_plugins
else
	# Update plugins
	git submodule update --recursive -- "$TPM_SUBMODULE"
	tpm_run ~/.tmux/plugins/tpm/bin/install_plugins
	tpm_run ~/.tmux/plugins/tpm/bin/update_plugins all
fi
