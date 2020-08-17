if status --is-interactive
  set -x EDITOR vim

  # direnv
  eval (direnv hook fish)

  # android studio
  set -x ANDROID_HOME $HOME/Library/Android/sdk

  # PATH
  set PATH $HOME/.nodenv/bin $PATH
  set PATH $HOME/.rbenv/bin $PATH
  set PATH $HOME/.pyenv/bin $PATH
end