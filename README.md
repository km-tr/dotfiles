# dotfiles

[chezmoi](https://www.chezmoi.io/) で管理している Mac の設定ファイル。新しい Mac は、このリポジトリを入口にして次の役割分担で立ち上げる。

| 対象 | 担当 |
|---|---|
| `.zshrc`、`.gitconfig`、`.Brewfile`、mise の設定 | chezmoi（このリポジトリ） |
| CLI、アプリ、App Store アプリ | Homebrew（`~/.Brewfile`） |
| 版を固定する開発ツール（Node、Bun、pnpm、APM） | mise（`~/.config/mise/config.toml`） |
| Homebrew の導入、ai-config と docs の取得、AI 設定の symlink、plugin と LaunchAgent | mise bootstrap（`~/.config/mise/conf.d/bootstrap.toml`） |
| 署名鍵と SSH の push | マシンごとの `~/.gitconfig.local`（管理外） |

## 新しい Mac での初回セットアップ

始める前に App Store にサインインしておく。Brewfile の App Store アプリ（Bitwarden、Tailscale）を入れるのに使う。

### 1. chezmoi を一度だけ実行する

Homebrew がまだないので、公式スクリプトで取得した chezmoi を一度だけ実行する。リポジトリは public なので認証はいらない。途中で管理者パスワードと gh のブラウザでのログインを聞かれる。

```sh
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- init --apply --purge-binary km-tr
```

chezmoi は設定ファイルを配置した後、`run_once_after_mise-bootstrap.sh` を実行する。このスクリプトは公式スクリプトで mise を入れて `mise bootstrap --skip-dirty` を実行し、終わったらその mise を消す。chezmoi と mise は Brewfile から入るので、`--purge-binary` と合わせて、公式スクリプトで入れた本体はどちらも残らない。

途中で失敗したら、原因を直して `chezmoi apply` を実行し直す。Homebrew の mise がもう入っている場合はスクリプトが何もしないので、`mise bootstrap --skip-dirty` を手で実行する。

### 2. mise bootstrap が行うこと

`~/.config/mise/conf.d/bootstrap.toml` に従って、次を順に行う。何度実行しても、足りないものだけを入れる。

1. Homebrew を入れ、Brewfile のうち入っていないものを入れる（既存のパッケージは更新しない）。gh にログインする
2. `~/hoge/ai-config` と `~/docs` を clone し、`~/.claude/CLAUDE.md` や `~/.agents/skills` などの symlink を張る
3. `config.toml` の開発ツールと npm の CLI を入れる
4. `bootstrap` タスクで、次を入れる
   - 公式のインストーラーで入れる CLI（claude、cursor-agent、devin、grok、coderabbit、blacksmith）
   - bun で入れる npm の CLI（下の表）
   - Claude Code・Codex・Pi の自作 hooks（ai-config の plugin と package）と、外部の plugin・package（ponytail など）
   - ai-config の `launchd/` にある自作の LaunchAgent

`--skip-dirty` は、未コミットの変更があるリポジトリで止まらずにスキップするための指定。

bootstrap の後に手で行うこと:

- Codex の hooks は承認するまで動かないので、`codex` を起動して `/hooks` で kmtr-codex-hooks の hook を承認する
- `reason` と `ara` は Reason アプリが置くリンクなので、アプリを入れて揃える
- claude.ai の組織から配布される plugin は、claude.ai へのログインで入る

npm の CLI のうち次の8つは mise の npm では入らないか動かないので、bun で入れている。

| 理由 | パッケージ |
|---|---|
| 自動更新の LaunchAgent（`codex-update`）が bun で更新する | codex |
| mise の npm はインストール後のスクリプトを実行せず、動かない（または遅くなる） | reason, opencode-ai, agent-desktop |
| 週のダウンロード数が少なく、mise の npm が安全確認で拒否する | ncli, figma-reader |
| mise の npm で依存関係を解決できない | lighthouse, vercel |

### 3. SSH 鍵と署名を設定する

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

### 4. 確認する

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
| Brewfile の不足、ai-config と docs、symlink、plugin、LaunchAgent をまとめて揃える | `mise bootstrap --skip-dirty` |
