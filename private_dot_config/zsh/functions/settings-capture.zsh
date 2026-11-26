: "${AI_CONFIG_DIR:=$HOME/hoge/ai-config}"

# 各エージェントの実ファイルで変えた値を、ai-config の .agents/settings/ に書き戻して差分を見せる
# 書き戻すのは ai-config 側に既にあるキーだけ。コミットするかは差分を見て決める
settings-capture() {
  (
    set -e
    cd "$AI_CONFIG_DIR"
    # tomllib は読み込み専用なので、コメントを残して書き出せる tomlkit を実行時だけ読み込む
    uv run --quiet --no-project --with tomlkit python -I - <<'PY'
import json, os
import tomlkit

home = os.path.expanduser("~")
pairs = [
    (".agents/settings/claude-settings.json", f"{home}/.claude/settings.json"),
    (".agents/settings/codex-config.toml", f"{home}/.codex/config.toml"),
    (".agents/settings/pi-settings.json", f"{home}/.pi/agent/settings.json"),
]

def capture(src, live):
    for key in list(src.keys()):
        if key not in live:
            continue
        if isinstance(src[key], dict) and isinstance(live[key], dict):
            capture(src[key], live[key])
        else:
            src[key] = live[key]

for src_path, live_path in pairs:
    if not os.path.exists(live_path):
        continue
    if src_path.endswith(".toml"):
        src = tomlkit.parse(open(src_path).read())
        capture(src, tomlkit.parse(open(live_path).read()).unwrap())
        open(src_path, "w").write(tomlkit.dumps(src))
    else:
        src = json.load(open(src_path))
        capture(src, json.load(open(live_path)))
        with open(src_path, "w") as f:
            json.dump(src, f, ensure_ascii=False, indent=2)
            f.write("\n")
PY
    if git diff --quiet -- .agents/settings; then
      print "settings-capture: 変更なし"
    else
      git --no-pager diff -- .agents/settings
      print "settings-capture: 内容を確かめて、必要なら ai-config でコミットして push する"
    fi
  )
}
