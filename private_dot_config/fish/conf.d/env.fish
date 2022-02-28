if status --is-interactive
  set -x EDITOR vim

  # direnv
  eval (direnv hook fish)
  eval (nodenv init - | source)
  eval (rbenv init - | source)
  eval (goenv init - | source)

  # android studio
  set -x ANDROID_HOME $HOME/Library/Android/sdk
  
  # zoxide
  zoxide init fish | source
end
