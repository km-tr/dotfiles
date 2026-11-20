#!/bin/sh
set -eu

# Homebrew の mise があれば bootstrap は済んでいる。以後は手で `mise bootstrap --skip-dirty` を使う
[ -x /opt/homebrew/bin/mise ] && exit 0

# 常用の mise は Brewfile から入るので、公式スクリプトの mise は bootstrap を通すためだけに使って消す
[ -x "$HOME/.local/bin/mise" ] || curl https://mise.run | sh
"$HOME/.local/bin/mise" bootstrap --skip-dirty
rm -f "$HOME/.local/bin/mise"
