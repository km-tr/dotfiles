function fix_path --description "Removes duplicate entries from \$PATH"
  set -l NEWPATH
  for p in $PATH
    if not contains $p $NEWPATH
      set NEWPATH $NEWPATH $p
    end
  end
  set PATH $NEWPATH
end