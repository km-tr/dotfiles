#!/bin/bash

DOT_FILES=(.bash_profile .tmux.conf .zprezto .tigrc)

for file in ${DOT_FILES[@]}
do
  ln -fs $HOME/.dotfiles/$file $HOME/$file
done

ZSH_FILES=(zlogin zlogout zpreztorc zprofile zshenv zshrc)

for file in ${ZSH_FILES[@]}
do
  ln -fs $HOME/.zprezto/runcoms/$file $HOME/.$file
done
