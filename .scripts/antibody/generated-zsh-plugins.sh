#!/bin/bash

echo "********************************************************************************"
echo "Installing Zsh plugins"
echo "********************************************************************************"

# Take the list of plugins in `.zsh_plugins.txt`, and turn that into a `.sh` file that will get sourced in `.zshrc`
antibody bundle <~/.zsh_plugins.txt >~/.zsh_plugins.sh

if [[ -n "$SPIN" ]]; then

	echo "********************************************************************************"
	echo "Ensuring gitstatus installed"
	echo "********************************************************************************"
	~/.cache/antibody/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-powerlevel10k/gitstatus/install -f
fi
