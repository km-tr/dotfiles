function fish_abbr -d "Search and execute fish abbr using fzf."
  eval (abbr --show | fzf | sed "s/^.*'\(.*\)'.*/\1/")
end
