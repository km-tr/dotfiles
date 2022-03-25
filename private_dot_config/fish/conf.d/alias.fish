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
  abbr -a dc 'docker compose'

  ## fzf
  abbr -a fgco 'git branch | fzf | xargs git switch'

  ## git commitzen
  abbr -a gcmf 'git commit -m \'feat:'
  abbr -a gcmfi 'git commit -m \'fix:'
  abbr -a gcmd 'git commit -m \'docs:'
  abbr -a gcms 'git commit -m \'style:'
  abbr -a gcmr 'git commit -m \'refactor:'
  abbr -a gcmp 'git commit -m \'perf:'
  abbr -a gcmt 'git commit -m \'test:'
  abbr -a gcmb 'git commit -m \'build:'
  abbr -a gcmci 'git commit -m \'ci:'
  abbr -a gcmc 'git commit -m \'chore:'
  abbr -a gcmrv 'git commit -m \'revert:'


  ## others
  abbr -a fb 'fish_abbr'
end
