wi() {
  local base="origin/master"
  local launch=""   # codex | claude | ""

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
    echo 'usage: wi "<title #111>" | wi "111" [--base origin/master] [--codex|--claude]' >&2
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
    | llm -m claude-haiku-4.5 -s "Output only: branch name, excluding ブランチマン" \
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

  # wtp add は [<commit>] を第2引数で受ける
  wtp add -b "$branch" "$base"

  # # 遷移
  wtp cd "$branch"

  # 起動（どちらか一方のみ）
  case "$launch" in
    codex)
      command -v codex >/dev/null 2>&1 || { echo "ERROR: codex not found in PATH" >&2; return 1; }
      codex
      ;;
    claude)
      command -v claude >/dev/null 2>&1 || { echo "ERROR: claude not found in PATH" >&2; return 1; }
      claude
      ;;
    "")
      ;;
  esac
}

wi-rm() {
  local selected
  selected=$(git worktree list | awk '{sub(/.*\//, "", $1); print}' | fzf) || return
  [[ -z "$selected" ]] && return
  wtp rm "${selected%% *}"
}

wi-cd() {
  local selected
  selected=$(git worktree list | awk '{sub(/.*\//, "", $1); print}' | fzf) || return
  [[ -z "$selected" ]] && return
  wtp cd "${selected%% *}"
}
