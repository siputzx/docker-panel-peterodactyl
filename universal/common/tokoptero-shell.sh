#!/bin/bash

export PATH="/home/container/tokoptero-sys/usr/bin:/home/container/tokoptero-sys/usr/local/bin:${HOME}/.local/bin:/home/container/.local/bin:${PATH}"
export LD_LIBRARY_PATH="/home/container/tokoptero-sys/usr/lib:${LD_LIBRARY_PATH}"
export HOSTNAME="tokoptero"
export PS1='\[\e[1;32m\]\u@tokoptero\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '

alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias install='tokoptero-apt install'
