wi() {
  local base
  base="$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null)"
  if [[ -z "$base" ]]; then
    echo "ERROR: cannot detect origin default branch. Run: git remote set-head origin --auto" >&2
    return 1
  fi
  local launch=""   # codex | claude | ""
  local use_cmux=false

  local -a args
  args=()

  while (( $# )); do
    case "$1" in
      --base)
        base="${2:?missing value for --base}"; shift 2 ;;
      --codex)
        if [[ -n "$launch" && "$launch" != "codex" ]]; then
          echo "ERROR: use only one of --codex or --claude" >&2
          return 1
        fi
        launch="codex"; shift ;;
      --claude)
        if [[ -n "$launch" && "$launch" != "claude" ]]; then
          echo "ERROR: use only one of --codex or --claude" >&2
          return 1
        fi
        launch="claude"; shift ;;
      --cmux)
        use_cmux=true; shift ;;
      --)
        shift; args+=("$@"); break ;;
      -*)
        echo "Unknown flag: $1" >&2; return 1 ;;
      *)
        args+=("$1"); shift ;;
    esac
  done

  local raw="${(j: :)args}"
  if [[ -z "${raw// }" ]]; then
    echo 'usage: wi "<title #111>" | wi "111" [--base origin/<default>] [--codex|--claude]' >&2
    return 1
  fi

  # issue番号を抽出（LLMに任せない）
  local issue
  issue="$(echo "$raw" | grep -Eo '#?[0-9]+' | head -n1 | tr -d '#')"

  # title: issueがあれば除去、なければrawをそのままトリム
  local title
  if [[ -n "$issue" ]]; then
    title="$(echo "$raw" | sed -E "s/(^|[^0-9])#?$issue([^0-9]|$)/ /" | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//')"
  else
    title="$(echo "$raw" | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//')"
  fi

  if [[ -z "$title" && -z "$issue" ]]; then
    echo 'ERROR: title and issue are empty. Include a title and/or "#111".' >&2
    return 1
  fi

  local rules_file="$HOME/docs/branch.md"
  [[ -f "$rules_file" ]] || { echo "ERROR: rules file not found: $rules_file" >&2; return 1; }
  command -v llm >/dev/null 2>&1 || { echo "ERROR: 'llm' not found. Install with: pipx install llm" >&2; return 1; }

  local rules out slug
  rules="$(cat "$rules_file")"

  out="$(
    printf "RULES:\n%s\n\nTASK:\nReturn ONLY a git branch name following the rules above.\nNo extra text.\n\nINPUT:\ntitle: %s\nissue: %s\n" \
      "$rules" "$title" "$issue" \
    | llm -m gemini-flash-latest -s "Output only: branch name, excluding ブランチマン" \
  )"

  slug="$(echo "$out" | tr -d '\r' | head -n1 | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"

  if [[ -z "$slug" || "$slug" =~ [[:space:]] ]]; then
    echo "ERROR: invalid slug: $slug" >&2
    return 1
  fi
  if [[ "$slug" == *"ブランチマン"* ]]; then
    echo "ERROR: invalid slug (contains ブランチマン): $slug" >&2
    return 1
  fi

  local branch="${slug}"

  echo "input : $raw"
  echo "title : $title"
  echo "issue : $issue"
  echo "base  : $base"
  echo "branch: $branch"

  if $use_cmux; then
    # wtp add（パイプで非TTYにしてcdを抑制）
    wtp add -b "$branch" "$base" | cat

    command -v cmux >/dev/null 2>&1 || { echo "ERROR: cmux not found in PATH" >&2; return 1; }
    local ws
    ws=$(cmux new-workspace 2>/dev/null | awk '{print $2}')
    if [[ -z "$ws" ]]; then
      echo "ERROR: failed to create cmux workspace" >&2
      return 1
    fi
    echo "cmux  : $ws"

    cmux send --workspace "$ws" "wtp cd $branch" 2>/dev/null
    cmux send-key --workspace "$ws" Enter 2>/dev/null

    # 起動（どちらか一方のみ）
    if [[ -n "$launch" ]]; then
      cmux send --workspace "$ws" "$launch" 2>/dev/null
      cmux send-key --workspace "$ws" Enter 2>/dev/null
    fi
  else
    # wtp add でworktree作成＋cd
    wtp add -b "$branch" "$base"

    # 起動
    [[ -n "$launch" ]] && "$launch"
  fi
}

wi-rm() {
  local -a rm_opts
  rm_opts=()
  while (( $# )); do
    case "$1" in
      -f|--force) rm_opts+=(--force); shift ;;
      *) echo "Unknown flag: $1" >&2; return 1 ;;
    esac
  done

  local selected
  selected=$(git worktree list | fzf -m) || return
  [[ -z "$selected" ]] && return
  echo "$selected" | while IFS= read -r line; do
    local wt_path wt_name
    wt_path=$(echo "$line" | awk '{print $1}')
    wt_name="${wt_path##*/}"
    git worktree remove "${rm_opts[@]}" "$wt_path" \
      && echo "Removed worktree: $wt_name"
  done
}

wi-cd() {
  local selected wt_path
  selected=$(git worktree list | fzf) || return
  [[ -z "$selected" ]] && return
  wt_path=$(echo "$selected" | awk '{print $1}')
  cd "$wt_path"
}
