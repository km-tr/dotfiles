function peco_insert_selected_git_files
  commandline | read -l buffer
  commandline (peco_select_from_git_status)
end