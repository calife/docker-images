#!/bin/bash
#
# Require expect package
#

SSH_PORT=2222
SSH_HOST=localhost
SSH_USER=root
SSH_PASSWORD=aaa

type expect >/dev/null 2>&1 || { echo >&2 "I require package expect but it's not installed.\nTry with: > sudo apt-get install expect ; \nAborting."; exit 1; }

echo "ssh connection to $HOST port $PORT"

./ssh.exp $SSH_HOST $SSH_USER $SSH_PORT $SSH_PASSWORD
test $? -eq 0 && { echo "TEST PASSED ..." ; exit 0 ; }

ssh-keygen -f "~/.ssh/known_hosts" -R "[$SSH_HOST]:$SSH_PORT"

./ssh.exp $SSH_HOST $SSH_USER $SSH_PORT $SSH_PASSWORD
test $? -eq 0 && { echo "TEST PASSED ..." ; exit 0 ; } || { echo "TEST FAILED ..." ; exit 1 ; }

