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

  ## peco
  abbr -a pco 'git branch | peco | xargs git checkout'
  abbr -a psh 'peco_select_history'
end