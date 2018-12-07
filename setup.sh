#!/bin/bash

DOT_FILES=(.tmux.conf .tigrc .npmrc .gitconfig .gitignore_global)
for file in ${DOT_FILES[@]}
do
  target=$HOME/.dotfiles/$file
  dest=$HOME/$file
  rm -rf $dest
  echo "${target} -> ${dest}"
  ln -s $target $dest
done

DOTCONFIG_FILES=`find .config -type f | sed 's/.config\\///'`
for file in ${DOTCONFIG_FILES[@]}
do
  target=$HOME/.dotfiles/.config/$file
  dest=$HOME/.config/$file
  rm -rf $dest
  echo "${target} -> ${dest}"
  ln -s $target $dest
done
