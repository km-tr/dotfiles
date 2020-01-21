function fix_path --description "Removes duplicate entries from \$PATH"
  set -l NEWPATH
  for p in $PATH
    echo $p
    echo $NEWPATH
    if not contains $p $NEWPATH
      set NEWPATH $NEWPATH $p
    end
  end
  set PATH $NEWPATH
end