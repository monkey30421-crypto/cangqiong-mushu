#!/bin/zsh
cd -- "${0:A:h}"
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
node scripts/launch.mjs /monster-actions
if [[ $? != 0 ]]; then read '?按回车关闭…'; fi
