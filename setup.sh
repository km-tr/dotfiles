#!/bin/bash

DOT_FILES=`find home -type f -exec basename {} \;`
for file in ${DOT_FILES[@]}
do
  target=$HOME/.dotfiles/home/$file
  dest=$HOME/$file
  rm -rf $dest
  echo "${target} -> ${dest}"
  ln -s $target $dest
done

DOTCONFIG_FILES=`find .config -type f`
for file in ${DOTCONFIG_FILES[@]}
do
  target=$HOME/.dotfiles/$file
  dest=$HOME/$file
  rm -rf $dest
  echo "${target} -> ${dest}"
  ln -s $target $dest
done
