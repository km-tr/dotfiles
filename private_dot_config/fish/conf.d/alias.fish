if status --is-interactive
  ## tig
  abbr -a tis 'tig status'

  ## npm
  abbr -a nr 'npm run'
  abbr -a ns 'npm start'
  abbr -a nrb 'npm run build'
  abbr -a nrw 'npm run watch'
  abbr -a nrt 'npm run test'

  ## yarn
  abbr -a yr 'yarn run'
  abbr -a ys 'yarn start'
  abbr -a yrb 'yarn run build'
  abbr -a yrw 'yarn run watch'
  abbr -a yrt 'yarn run test'

  ## docker
  abbr -a dc 'docker-compose'

  ## fzf
  abbr -a fgco 'git branch | fzf | xargs git switch'

  ## git commitzen
  abbr -a gcmf -m 'git commit -m \'feat: \''

  ## others
  abbr -a fb 'fish_abbr'
end
