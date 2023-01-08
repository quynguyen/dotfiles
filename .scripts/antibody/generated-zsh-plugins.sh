#!/bin/bash

# Take the list of plugins in `.zsh_plugins.txt`, and turn that into a `.sh` file that will get sourced in `.zshrc`
antibody bundle < ~/.zsh_plugins.txt > ~/.zsh_plugins.sh
