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

    # 新旧の lock に載っているファイルだけを対象にし、手元のローカルスキルの変更を混ぜない
    local -a paths
    paths=("${(@f)$(python3 -I -c '
import re, subprocess, sys, os
def deployed(text):
    return set(re.findall(r"^\s*value: (\.agents/\S+|\.codex/\S+)$", text, re.M))
old = subprocess.run(["git", "show", "HEAD:apm.lock.yaml"], capture_output=True, text=True).stdout
new = open("apm.lock.yaml").read()
tracked = set(subprocess.run(["git", "ls-files"], capture_output=True, text=True).stdout.split())
for p in sorted(deployed(old) | deployed(new)):
    if os.path.isfile(p) or p in tracked:
        print(p)
')}")
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
