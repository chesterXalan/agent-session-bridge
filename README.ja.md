# Agent Session Bridge

[English](README.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md)

macOS アプリ向けに、ローカルの Claude Code と Codex のセッション情報を提供する Swift ライブラリと軽量 CLI です。
各アプリはセッション検出とフックを共有しながら、独立してインストール・実行できます。

macOS 14 以降と Swift 6（Xcode Command Line Tools）が必要です。追加のパッケージ依存や常駐デーモンはありません。

## ビルドとインストール

```sh
git clone https://github.com/chesterXalan/agent-session-bridge.git
cd agent-session-bridge
make build
.build/release/agent-session-bridge install
```

`install` は実行ファイルを `~/Library/Application Support/AgentSessionBridge/bin/agent-session-bridge` にコピーし、
両方の CLI のフックを設定します。完了後に CLI セッションを再起動し、更新されたフックの確認が表示された場合は許可してください。
`install-runtime` は実行ファイルのみをコピーし、フック設定は変更しません。

```sh
"$HOME/Library/Application Support/AgentSessionBridge/bin/agent-session-bridge" list
```

`list` はタブ区切りで、CLI の種類、PID、状態、タイトル、作業ディレクトリ、任意の cmux 位置情報の 6 項目を出力します。
状態は `working`、`waiting`、`idle`、`unknown` のいずれかです。フック情報がない場合や対応関係が曖昧な場合は `unknown` のままになります。
`record --provider claude|codex` は標準入力からフックの JSON を受け取り、メタデータのみを保存して常に正常終了します。
Codex には `{}` を返します。`--home DIR` を指定すると、独立したホームディレクトリでテストできます。

`uninstall` は**この bridge を利用するすべてのアプリ**の共有フックを削除し、実行ファイルと記録は残します。
インストール・削除時に `--provider claude|codex` を指定すると、一方の CLI のみを対象にできます。
利用アプリを削除しても、共有の実行ファイルやフックは削除されません。

## 組み込み

利用するプロジェクトは Git submodule を使い、指定したバージョンを `vendor/agent-session-bridge` に配置します。
Clone 時には `--recurse-submodules` を付け、既存の checkout では `git submodule update --init --recursive` を実行してください。
Swift アプリはローカルの Swift package 依存関係として `AgentSessionCore` ライブラリを利用します。
その他の実行環境では、シェルを介さずに独立した CLI を呼び出します。

利用アプリをテストしてから、submodule が参照する commit を明示的に更新してください。
ビルドスクリプトが最新ブランチを自動追従することはありません。
各プロジェクトは固定したバージョンの helper をビルド・同梱し、明示的な操作で共有パスにインストールできます。
この初版プロトコルでは、CLI の出力形式と保存形式の後方互換性を維持してください。

## データとプライバシー

セッション情報は `~/Library/Application Support/AgentSessionBridge/sessions/` に保存されます。
フック設定時は他の設定やフックを保持し、変更前に `*.agent-session-bridge-<time>.bak` としてバックアップします。
以前のインストールからの移行については、[移行ガイド（英語）](docs/migration.md)を参照してください。

セッションの照合では PID と起動時刻を優先し、次に明示的な会話 ID を使います。
Codex のディレクトリによる補完は、同じディレクトリに該当プロセスと最近の会話がそれぞれ 1 つだけある場合に限定されます。
複数のセッションから推測で選ぶことはありません。
tmux と cmux の位置情報は保持しますが、このパッケージはターミナルの切り替えやウィンドウ操作を行いません。

プロンプト、ツールの引数、ターミナル出力、会話内容は保存・公開しません。
表示用タイトルは Codex のタイトル索引と、読み取り範囲を制限した Claude の会話ファイル内のタイトル情報から取得します。
Bridge はネットワーク通信を行わず、cmux のタイトルはローカル CLI で取得します。

## 開発

`make test` と `make build` を実行してください。
テストでは CLI・ターミナル・ディレクトリの組み合わせ、曖昧な識別情報、タイトル取得、旧版からの移行、
他のフックの保持、実行ファイルの独立したインストールを確認します。

設定手順や動作を変更するときは、英語・繁体字中国語・日本語の README を同時に更新してください。
技術文書とコードコメントは英語で記述します。

## クレジット

[MH Desk Pets](https://github.com/chesterXalan/mh-desk-pets) から抽出したコードで、[youngOman/desk-pets](https://github.com/youngOman/desk-pets) を基にしています。
両者の著作権表示を保持し、[MIT License](LICENSE) で配布しています。
