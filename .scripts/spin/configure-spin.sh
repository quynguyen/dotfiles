#!/bin/bash

echo "********************************************************************************"
echo "Configuring Spin settings"
echo "********************************************************************************"

# Reminder-to-self:
# Quy, you registered this file with Spin with the following command:
# `cat ~/.config/github-copilot/hosts.json | spin secrets create github_copilot_hosts.json`
# In doing so, Spin will automatically create this file for you when you run `spin up`
github_copilot_secret="/etc/spin/secrets/github_copilot_hosts.json"

# Where we ultimately want the secret symlinked to
github_copilot_config_path="${HOME}/.config/github-copilot"
github_copilot_config="${github_copilot_config_path}/hosts.json"

if [[ -f $github_copilot_secret ]]; then
	[[ -d $github_copilot_config_path ]] || mkdir -p $github_copilot_config_path
	ln -snvf $github_copilot_secret $github_copilot_config
fi

echo "********************************************************************************"
echo "Setting the remote repo url on ~/dotfiles/"
echo "********************************************************************************"

# Set the remote URL for the repo
git -C $HOME/dotfiles remote set-url origin git@github.com:quyify/dotfiles.git

# Ouptput the remote URL
git -C $HOME/dotfiles remote -v
