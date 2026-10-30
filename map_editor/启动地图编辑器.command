#!/bin/zsh
cd -- "${0:A:h}"
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
if ! command -v node >/dev/null; then
  echo '未找到 Node.js，请安装 Node.js 22 或更新版本。'
  read '?按回车关闭…'
  exit 1
fi
if [[ ! -d node_modules/@esotericsoftware/spine-webgl || ! -d node_modules/esbuild ]]; then
  npm ci --no-audit --no-fund || exit 1
fi
node scripts/launch.mjs /
if [[ $? != 0 ]]; then read '?按回车关闭…'; fi
