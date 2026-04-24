#!/bin/bash

echo "********************************************************************************"
echo "Generating ~/.zshrc from ~/.zshrc_template"
echo "********************************************************************************"

# Move any existing .zshrc
if [[ -f ~/.zshrc ]] && [[ -z ~/.zshrc.old ]]; then
	mv ~/.zshrc ~/.zshrc.old
fi

# Go two parent dirs up from this script
pushd "$(dirname ${BASH_SOURCE:-$0})/../../" >/dev/null

export REPLACE_source=${BASH_SOURCE:-$0}
export DOLLAR='$'
export REPLACE_dotfiles_path=$(pwd)
export REPLACE_home=$HOME
export REPLACE_file='$file'
export REPLACE_p10k_home='${XDG_CACHE_HOME:-$HOME/.cache}'
export REPLACE_p10k_prompt='${(%):-%n}'
export REPLACE_path='${PATH}'
export REPLACE_term='${TERM}'
export REPLACE_tmux='${TMUX}'
export REPLACE_dotfiles_shell_mode='${DOTFILES_SHELL_MODE}'
export REPLACE_ostype='${OSTYPE}'
export REPLACE_warning=$(
	cat <<-END
		# !!!!! WARNING !!!!! 
		#
		# This file is generated. To make changes to the source...
		# 
		# Option 1:
		# nvim ~/.zshrc_template
		# run ${REPLACE_source}
		# 
		# Option 2:
		# Run the convenience alias 'nz'
		#
	END
)

# Go back
popd >/dev/null

# Generate a .zshrc from a template, REPLACING in ${USER}-specific values.
# Pass an allow-list so envsubst only substitutes our REPLACE_* placeholders
# and leaves runtime shell variables like ${PATH}, ${TERM}, ${TMUX}, and
# zsh loop variables like ${file} untouched.
envsubst '
	${REPLACE_warning}
	${REPLACE_dotfiles_path}
	${REPLACE_source}
	${REPLACE_home}
	${REPLACE_path}
	${REPLACE_file}
	${REPLACE_p10k_home}
	${REPLACE_p10k_prompt}
	${REPLACE_ostype}
	${REPLACE_dotfiles_shell_mode}
	${REPLACE_tmux}
' <~/.zshrc_template >~/.zshrc

# for interactive shells
if [[ $- == *i* ]]; then
	# add zsh to valid login shells
	command -v zsh | sudo tee -a /etc/shells
	# make zsh the default shell
	chsh -s $(which zsh) $USER
fi
