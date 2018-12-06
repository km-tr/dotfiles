#!/bin/bash

DOT_FILES=(.tmux.conf .tigrc .npmrc .gitconfig .gitignore_global)
for file in ${DOT_FILES[@]}
do
  dest=$HOME/$file
  rm -rf $dest
  ln -s $HOME/.dotfiles/$file $dest
done

DOTCONFIG_FILES=(fish/config.fish fish/fishfile)
for file in ${DOTCONFIG_FILES[@]}
do
 dest=$HOME/.config/$file
 rm -rf $dest
 ln -s $HOME/.dotfiles/$file $dest
done
