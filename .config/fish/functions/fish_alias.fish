function fish_alias -d "abbr --show | fzf"
  eval (abbr --show | fzf | sed "s/^.*'\(.*\)'.*/\1/")
end
