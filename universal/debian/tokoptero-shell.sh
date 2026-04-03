#!/bin/bash

export PATH="${HOME}/.local/bin:/home/container/.local/bin:${PATH}"
export HOSTNAME="tokoptero"
export PS1='\[\e[1;32m\]\u@tokoptero\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '

alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
