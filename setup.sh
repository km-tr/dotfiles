#!/bin/bash

DOT_FILES=(.bash_profile .tmux.conf .zprezto .tigrc .npmrc .gitconfig .gitignore_global)
for file in ${DOT_FILES[@]}
do
  dest=$HOME/$file 
  rm -rf $dest
  ln -s $HOME/.dotfiles/$file $dest
done

ZSH_FILES=(zlogin zlogout zpreztorc zprofile zshenv zshrc)
for file in ${ZSH_FILES[@]}
do
 dest=$HOME/.$file 
 rm -rf $dest
 ln -s $HOME/.zprezto/runcoms/$file $dest 
done

DOTCONFIG_FILES=(nvim powerline)
for file in ${DOTCONFIG_FILES[@]}
do
 dest=$HOME/.config/$file
 rm -rf $dest
 ln -s $HOME/.dotfiles/$file $dest
done
