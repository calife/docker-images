#!/bin/bash

_pwd=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)

export $_pwd

exit 0
