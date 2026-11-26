: "${AI_CONFIG_DIR:=$HOME/hoge/ai-config}"

# APM の依存を更新し、APM が置くファイルだけをコミットして push する
apmup() {
  (
    set -e
    cd "$AI_CONFIG_DIR"
    apm update --yes

    # 0.35 系で登録済みスキルが消えた不具合があったため、スキルや agent が消えていたらコミットしない
    local removed
    removed=$(git diff --name-only --diff-filter=D -- '.agents/skills/*/SKILL.md' '.codex/agents/*')
    if [[ -n $removed ]]; then
      print -u2 "apmup: 消えたスキルがあるのでコミットしない:\n$removed"
      return 1
    fi

    # 新旧の lock に載っているスキル・agent のフォルダだけを対象にし、手元のローカルスキルの変更を混ぜない
    # lock の長いパスは YAML で折り返されるので、ファイル名ではなく先頭のフォルダ名だけを使う
    local -a paths
    paths=("${(@f)$( { git show HEAD:apm.lock.yaml; cat apm.lock.yaml; } \
      | sed -nE 's#^[[:space:]]*value: [\x27"]?(\.agents/skills/[^/[:space:]]+|\.codex/agents/[^/[:space:]]+).*#\1#p' \
      | sort -u)}")
    git add -A -- apm.lock.yaml "${paths[@]}"
    if git diff --cached --quiet; then
      print "apmup: 変更なし"
      return 0
    fi
    git commit -q -m "chore: update skills installed by apm" -m "🤖 Generated with AI"
    git push -q
    git log --oneline -1
  )
}
