# Agent Session Bridge

[English](README.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md)

為 macOS 應用程式提供本機 Claude Code 與 Codex 工作階段資訊，包含 Swift 函式庫與輕量 CLI
各應用程式可共用工作階段偵測與 hooks，並獨立安裝、執行

需要 macOS 14+ 與 Swift 6（Xcode Command Line Tools），沒有額外套件依賴，也不需要背景常駐服務

## 建置與安裝

```sh
git clone https://github.com/chesterXalan/agent-session-bridge.git
cd agent-session-bridge
make build
.build/release/agent-session-bridge install
```

`install` 會將執行檔複製到 `~/Library/Application Support/AgentSessionBridge/bin/agent-session-bridge`，
並設定兩種 CLI 的 hooks；完成後請重開 CLI 工作階段，若出現更新後的 hooks 確認提示，請允許
`install-runtime` 只複製執行檔，不修改 hooks

```sh
"$HOME/Library/Application Support/AgentSessionBridge/bin/agent-session-bridge" list
```

`list` 輸出六個以 tab 分隔的欄位：CLI 種類、PID、狀態、標題、工作目錄，以及選用的 cmux 位置
狀態為 `working`、`waiting`、`idle` 或 `unknown`；缺少 hooks 資訊或無法明確比對時，會維持 `unknown`
`record --provider claude|codex` 從 stdin 接收 hook JSON，只儲存工作階段資訊，並一律以成功狀態結束
Codex 會收到 `{}` 回應；可用 `--home DIR` 在獨立的家目錄中測試

`uninstall` 會移除**所有使用此 bridge 的應用程式**所共用的 hooks，保留執行檔與紀錄
安裝或移除時可加上 `--provider claude|codex`，只處理其中一種 CLI
刪除使用此 bridge 的應用程式，不會移除共用執行檔或 hooks

## 整合

使用此 bridge 的專案透過 Git submodule，將指定版本放在 `vendor/agent-session-bridge`
Clone 時請加上 `--recurse-submodules`，已有的 checkout 則執行 `git submodule update --init --recursive`
Swift 應用程式可透過本機 Swift package 依賴使用 `AgentSessionCore` 函式庫
其他執行環境則直接呼叫獨立 CLI，不經過 shell

測試使用此 bridge 的應用程式後，再更新 submodule 指向的 commit；建置腳本不會自動追蹤最新分支
各專案可建置並附帶自己鎖定版本的 helper，再明確安裝到共用路徑
在目前的初版協定中，CLI 輸出與紀錄格式應保持向下相容

## 資料與隱私

工作階段資訊儲存在 `~/Library/Application Support/AgentSessionBridge/sessions/`
安裝 hooks 時會保留其他設定與 hooks，並在修改前備份成 `*.agent-session-bridge-<time>.bak`
舊版安裝的相容處理請見[遷移指南（英文）](docs/migration.md)

工作階段比對優先使用 PID 與啟動時間，再使用明確的對話 ID
Codex 的目錄備援比對僅適用於同目錄只有一個符合條件的程序與一段近期對話時，不會猜測多個工作階段的對應關係
會保留 tmux 與 cmux 的位置資訊，但此套件不負責切換終端或控制視窗

不儲存或輸出提示詞、工具參數、終端輸出或對話內容
易讀標題取自 Codex 的標題索引，以及有限範圍內的 Claude 對話檔標題資訊
Bridge 不發送網路請求；cmux 標題透過其本機 CLI 查詢

## 開發

執行 `make test` 與 `make build`
測試涵蓋不同 CLI／終端／目錄組合、無法明確比對的工作階段、標題查詢、舊版遷移、保留其他 hooks，以及獨立安裝執行檔

變更設定方式或行為時，請同步更新英文、繁體中文與日文 README
技術文件與程式註解維持英文

## 致謝

抽取自 [MH Desk Pets](https://github.com/chesterXalan/mh-desk-pets)，原始基礎為 [youngOman/desk-pets](https://github.com/youngOman/desk-pets)
以 [MIT License](LICENSE) 發布，保留兩份著作權聲明
