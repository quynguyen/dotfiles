#!/bin/bash

# Install or Update plugins
if [[ ! -f ~/.tmux/plugins/tpm/bin/install_plugins ]]; then
	# Install plugins
	git submodule update --init --remote --merge
	~/.tmux/plugins/tpm/bin/install_plugins
else
	# Update plugins
	~/.tmux/plugins/tpm/bin/update_plugins all
fi
