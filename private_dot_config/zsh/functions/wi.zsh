wi() {
  local base
  base="$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null)"
  if [[ -z "$base" ]]; then
    echo "ERROR: cannot detect origin default branch. Run: git remote set-head origin --auto" >&2
    return 1
  fi
  local launch=""   # codex | claude | ""
  local use_cmux=false
  local prompt=""
  local branch=""
  local explicit_branch=false

  local -a args
  args=()

  while (( $# )); do
    case "$1" in
      --base)
        base="${2:?missing value for --base}"; shift 2 ;;
      --branch|-b)
        branch="${2:?missing value for --branch}"; explicit_branch=true; shift 2 ;;
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
      --prompt|-p)
        prompt="${2:?missing value for --prompt}"; shift 2 ;;
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
  if [[ -n "$branch" && ${#args[@]} -gt 0 ]]; then
    echo 'ERROR: --branch cannot be used with title/issue arguments' >&2
    echo 'usage: wi "<title #111>" | wi "111" [--base origin/<default>] [--codex|--claude] [--prompt|-p "..."] [--cmux]' >&2
    echo '       wi -b|--branch <branch> [--base origin/<default>] [--codex|--claude] [--prompt|-p "..."] [--cmux]' >&2
    return 1
  fi
  if [[ -z "$branch" && -z "${raw// }" ]]; then
    echo 'usage: wi "<title #111>" | wi "111" [--base origin/<default>] [--codex|--claude] [--prompt|-p "..."] [--cmux]' >&2
    echo '       wi -b|--branch <branch> [--base origin/<default>] [--codex|--claude] [--prompt|-p "..."] [--cmux]' >&2
    return 1
  fi

  if [[ -n "$prompt" && -z "$launch" ]]; then
    echo 'ERROR: --prompt requires --codex or --claude' >&2
    return 1
  fi

  local issue=""
  local title=""
  if [[ -z "$branch" ]]; then
    # issue番号を抽出（LLMに任せない）
    issue="$(echo "$raw" | grep -Eo '#?[0-9]+' | head -n1 | tr -d '#')"

    # title: issueがあれば除去、なければrawをそのままトリム
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
    echo "branch: generating from title..."

    out="$(
      printf "RULES:\n%s\n\nTASK:\nReturn ONLY a git branch name following the rules above.\nNo extra text.\n\nINPUT:\ntitle: %s\nissue: %s\n" \
        "$rules" "$title" "$issue" \
      | python3 -c 'import subprocess, sys
timeout = int(sys.argv[1])
cmd = sys.argv[2:]
try:
    raise SystemExit(subprocess.run(cmd, timeout=timeout).returncode)
except subprocess.TimeoutExpired:
    raise SystemExit(124)
' "${WI_LLM_TIMEOUT_SECONDS:-15}" llm -m gemini-flash-latest -s "Output only: branch name, excluding ブランチマン" \
    )"
    local llm_status=$?
    if [[ "$llm_status" -eq 124 ]]; then
      echo "ERROR: timed out generating branch name after ${WI_LLM_TIMEOUT_SECONDS:-15}s" >&2
      return 1
    fi
    if [[ "$llm_status" -ne 0 ]]; then
      echo "ERROR: failed to generate branch name" >&2
      return 1
    fi

    slug="$(echo "$out" | tr -d '\r' | head -n1 | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"

    if [[ -z "$slug" || "$slug" =~ [[:space:]] ]]; then
      echo "ERROR: invalid slug: $slug" >&2
      return 1
    fi
    if [[ "$slug" == *"ブランチマン"* ]]; then
      echo "ERROR: invalid slug (contains ブランチマン): $slug" >&2
      return 1
    fi

    branch="${slug}"
  fi

  if [[ -n "$raw" ]]; then
    echo "input : $raw"
    echo "title : $title"
    echo "issue : $issue"
  fi
  echo "base  : $base"
  echo "branch: $branch"

  local -a wtp_add_args
  wtp_add_args=(add -b "$branch" "$base")
  if $explicit_branch; then
    if git show-ref --verify --quiet "refs/heads/$branch"; then
      wtp_add_args=(add "$branch")
    else
      git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1
      local remote_status=$?
      if [[ "$remote_status" -eq 0 ]]; then
        wtp_add_args=(add "$branch")
      elif [[ "$remote_status" -ne 2 ]]; then
        echo "ERROR: failed to check whether branch exists on origin: $branch" >&2
        return 1
      fi
    fi
  fi

  if $use_cmux; then
    # wtp add（パイプで非TTYにしてcdを抑制）
    wtp "${wtp_add_args[@]}" | cat

    command -v cmux >/dev/null 2>&1 || { echo "ERROR: cmux not found in PATH" >&2; return 1; }
    local cwd workspace_name cmd wtp_cwd_raw
    wtp_cwd_raw="$(command wtp cd "$branch")" || return 1
    cwd="$(printf '%s\n' "$wtp_cwd_raw" | tr -d '\r' | awk 'NR == 1 { print; exit }')"
    if [[ -z "$cwd" ]]; then
      echo "ERROR: command wtp cd returned empty path for branch: $branch" >&2
      return 1
    fi
    if [[ -n "${WI_DEBUG:-}" ]]; then
      echo "DEBUG: wi cmux cwd: $cwd" >&2
    fi
    workspace_name="${title:-$branch}"
    local -a cmux_args
    cmux_args=(new-workspace --cwd "$cwd" --name "$workspace_name")
    local launch_cmd=""
    if [[ -n "$launch" ]]; then
      launch_cmd="$launch"
      if [[ -n "$prompt" ]]; then
        launch_cmd="$launch_cmd $(printf '%q' "$prompt")"
      fi
    fi
    local ws
    ws=$(cmux "${cmux_args[@]}" 2>/dev/null | awk '{print $2}')
    if [[ -z "$ws" ]]; then
      echo "ERROR: failed to create cmux workspace" >&2
      return 1
    fi
    echo "cmux  : $ws"
    if [[ -n "${WI_DEBUG:-}" ]]; then
      echo "DEBUG: wi cmux workspace: $ws" >&2
    fi
    if ! cmux workspace-action --workspace "$ws" --action set-color --color Teal 2>/dev/null; then
      echo "WARN: failed to set cmux workspace color: $ws" >&2
    fi
    if [[ -n "$launch_cmd" ]]; then
      local surface
      surface="$(cmux list-pane-surfaces --workspace "$ws" 2>/dev/null | awk '{for (i=1;i<=NF;i++) if ($i ~ /^surface:/) {print $i; exit}}')"
      if [[ -z "$surface" ]]; then
        echo "ERROR: failed to resolve cmux surface for workspace: $ws" >&2
        return 1
      fi
      if [[ -n "${WI_DEBUG:-}" ]]; then
        echo "DEBUG: wi cmux surface: $surface" >&2
        echo "DEBUG: wi cmux launch: $launch_cmd" >&2
      fi
      if ! cmux respawn-pane --workspace "$ws" --surface "$surface" --command "$launch_cmd" 2>/dev/null; then
        echo "ERROR: failed to launch command in cmux workspace: $ws" >&2
        return 1
      fi
    fi
  else
    # wtp add でworktree作成＋cd
    wtp "${wtp_add_args[@]}"

    # 起動
    if [[ -n "$launch" ]]; then
      if [[ -n "$prompt" ]]; then
        "$launch" "$prompt"
      else
        "$launch"
      fi
    fi
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
