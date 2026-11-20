# dotfiles

[chezmoi](https://www.chezmoi.io/) で管理している Mac の設定ファイル。新しい Mac は、このリポジトリを入口にして次の役割分担で立ち上げる。

| 対象 | 担当 |
|---|---|
| `.zshrc`、`.gitconfig`、`.Brewfile`、mise の設定 | chezmoi（このリポジトリ） |
| CLI、アプリ、App Store アプリ | Homebrew（`~/.Brewfile`） |
| 版を固定する開発ツール（Node、Bun、pnpm、APM） | mise（`~/.config/mise/config.toml`） |
| ai-config と docs の取得、AI 設定の symlink | mise bootstrap（`~/.config/mise/conf.d/bootstrap.toml`） |
| 署名鍵と SSH の push | マシンごとの `~/.gitconfig.local`（管理外） |

## 新しい Mac での初回セットアップ

始める前に App Store にサインインしておく。Brewfile の App Store アプリ（Bitwarden、Tailscale）を入れるのに使う。

### 1. chezmoi で設定ファイルを配置する

Homebrew がまだないので、公式スクリプトで取得した chezmoi を一度だけ実行する。`--purge-binary` で実行後にその本体を消し、常用する chezmoi は次の手順で Brewfile から入れる。リポジトリは public なので認証はいらない。

```sh
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- init --apply --purge-binary km-tr
```

ソース（`~/.local/share/chezmoi`）と設定は残るので、以後は Homebrew の chezmoi で `chezmoi update` などを使える。

### 2. Homebrew と Brewfile のパッケージを入れる

途中で管理者パスワードを聞かれる。

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
brew bundle --global
```

### 3. 開発ツールを入れて GitHub にログインする

```sh
mise install
gh auth login --web --git-protocol https
```

`.gitconfig` は GitHub への HTTPS 接続で `gh auth git-credential` を使う。gh にログインすると、private リポジトリも clone できるようになる。

### 4. ai-config と docs を取得し、AI 設定を配置する

```sh
mise bootstrap --skip-dirty
```

`~/hoge/ai-config` と `~/docs` を clone し、`~/.claude/CLAUDE.md` や `~/.agents/skills` などの symlink を張る。`--skip-dirty` は、未コミットの変更があるリポジトリで止まらずにスキップするための指定。

Claude Code・Codex・Pi の自作 hooks は ai-config の plugin（Pi は package）なので、続けて次を実行する。

```sh
claude plugin marketplace add ~/hoge/ai-config
claude plugin install kmtr-hooks@ai-config
codex plugin marketplace add ~/hoge/ai-config
codex plugin add kmtr-codex-hooks@ai-config
pi install ~/hoge/ai-config/pi
```

Codex の hooks は承認するまで動かないので、`codex` を起動して `/hooks` で kmtr-codex-hooks の hook を承認する。

外部の plugin と package は各ツールの設定ファイルにしか記録されないので、手で入れ直す。

```sh
claude plugin marketplace add DietrichGebert/ponytail
claude plugin install ponytail@ponytail
pi install npm:pi-web-access
pi install npm:pi-background-tasks
pi install npm:pi-subagents
pi install npm:pi-sandbox
pi install npm:@schultzp2020/pi-cursor
pi install npm:@commandcode/pi-commandcode-provider
pi install npm:@dietrichgebert/ponytail
```

claude.ai の組織から配布される plugin は、この一覧に含めない。

公式のインストーラーで `~/.local/bin` に入る CLI も、Brewfile と mise の外なので手で入れる。

```sh
curl -fsSL https://claude.ai/install.sh | bash             # claude
curl https://cursor.com/install -fsS | bash                # cursor-agent
curl -fsSL https://cli.devin.ai/install.sh | bash          # devin
curl -fsSL https://x.ai/cli/install.sh | bash              # grok（~/.grok/bin）
curl -fsSL https://cli.coderabbit.ai/install.sh | sh       # coderabbit, cr
curl -fsSL https://get.blacksmith.sh | BLACKSMITH_INSTALL_DIR="$HOME/.local/bin" sh  # blacksmith
```

`reason` と `ara` は Reason アプリが置くリンクなので、アプリを入れれば揃う。

自作の LaunchAgent は ai-config の `launchd/` にあり、手順は ai-config の README に書いてある。

### 5. SSH 鍵と署名を設定する

GitHub 用の SSH 鍵を `~/.ssh/github` に置き（または Bitwarden の SSH エージェントを使い）、`~/.gitconfig.local` を作る。このファイルは chezmoi で管理しない。

```ini
[user]
	signingkey = ~/.ssh/github.pub
[commit]
	gpgsign = true
[url "git@github.com:"]
	pushInsteadOf = https://github.com/
```

このファイルがない間は、署名なしでコミットし、HTTPS（gh の認証）で push する。

### 6. 確認する

新しいターミナルを開いて、次を確かめる。

```sh
apm --version                   # 0.34.0
git -C ~/docs fetch             # private リポジトリに HTTPS でつながる
ls -l ~/.claude/CLAUDE.md       # ai-config への symlink
```

## 普段の運用

| やりたいこと | コマンド |
|---|---|
| ローカルで編集した設定を反映する | `chezmoi apply` |
| 別の Mac での変更を取り込む | `chezmoi update` |
| アプリや CLI を入れた・消した後に Brewfile へ反映する | `bbd` の後に `chezmoi re-add ~/.Brewfile` してコミット |
| Brewfile の内容をまとめて入れる | `brew bundle --global` |
| ai-config と docs の取得、AI 設定の symlink | `mise bootstrap --skip-dirty` |
