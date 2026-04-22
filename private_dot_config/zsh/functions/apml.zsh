: "${AI_CONFIG_DIR:=$HOME/hoge/ai-config}"

apml() {
  (cd "$AI_CONFIG_DIR" && apm "$@")
}
