function peco_select_from_git_status
  git status --porcelain | \
  peco | \
  awk -F ' ' '{print $NF}' | \
  tr '\n' ' '
end