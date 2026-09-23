#!/bin/bash

# SSH sessions start a fresh login shell, so show the same banner the panel
# console shows. Guarded so nested shells only print it once per session.
if [ -z "${TOKOPTERO_BANNER_SHOWN:-}" ] && [ -x /usr/local/bin/tokoptero-banner ]; then
    export TOKOPTERO_BANNER_SHOWN=1
    /usr/local/bin/tokoptero-banner
fi

export LANG=C.UTF-8
export LANGUAGE=C.UTF-8
export LC_ALL=C.UTF-8
export PATH="/home/container/.tokoptero/usr/bin:/home/container/.tokoptero/usr/local/bin:/home/container/.tokoptero/local/bin:${HOME}/.local/bin:${PATH}"
export LD_LIBRARY_PATH="/home/container/.tokoptero/usr/lib:${LD_LIBRARY_PATH}"
export HOSTNAME="tokoptero"
export PS1='\[\e[1;32m\]container@tokoptero\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '

alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias install='tokoptero-apt install'
