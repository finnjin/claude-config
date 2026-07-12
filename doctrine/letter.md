# 給未來 Session 的信

寫於 2026-07-12，Fable 5 的唯一一次 session。這封信是歷史文件，不要修改；要更新制度去改其他 doctrine 檔。

## 這套制度是什麼

船長要求把一次性的高階判斷力轉成可長期沿用的制度。產出：`diagnosis.md`（依據）、`engineering.md`（工程原則）、`model-dispatch.md`（派工）、`judgment.md`（判斷 rubric）、`templates.md`（派工模板）、`maintenance.md`（維護協議）、本信。CLAUDE.md 已改寫為路由（原版備份在 `~/.claude/CLAUDE.md.pre-doctrine-bak`）。

## 三件我沒問、但認為對這個環境最重要的事

### 1. Plugin 固定稅該盤點了（需要船長決定）

6 個 plugin 全開：atlassian、superpowers、codex、code-simplifier、pyright-lsp、playwright，外加 Gmail/Calendar/Drive MCP。每個 session 光 deferred tool 清單就超過 100 個，superpowers 的 SessionStart hook 再注入一大段強制文字。對弱模型這是雙重稅：context 被佔用，且「1% 可能適用就 MUST invoke skill」的措辭會把它拉去在不適用的場景跑 brainstorming/TDD 流程。建議船長跑一次 `/plugin` 盤點：三個月沒用的關掉；若保留 superpowers，知道 CLAUDE.md 的「Skill 與工具優先序」段就是為了對沖它的過度觸發而寫的。

### 2. 把 ~/.claude 納入 git（需要船長決定）

doctrine、skills（尤其 cr-core 規則庫）、settings.json 是這個環境最有價值的資產，但目前只有散落的 `.bak` 檔保護。建議 `git init` ~/.claude，用 `.gitignore` 排除 `history.jsonl`、`sessions/`、`session-env/`、`paste-cache/`、`file-history/`、`shell-snapshots/`、`telemetry/`、`usage-data/`、`stats-cache.json`、`projects/`（含對話痕跡）。制度檔改壞可回滾，`maintenance.md` 的備份協議就可以簡化成 git。這件事我沒做，因為初始化 repo 是改變系統狀態的決定，且哪些目錄含敏感資訊該由船長確認。

### 3. 成本模式決定 opus 的用量（我查不到的事）

`model-dispatch.md` 的模型選擇表假設「opus 用於難題與驗收」是可負擔的。如果帳號是按 API token 計費且預算緊，應把驗收的預設從 opus 降到 sonnet、只有高風險判斷才上 opus；如果是訂閱制吃到飽，反而應該更大方地用 opus 驗收。這件事環境裡查不到，船長請直接改 `model-dispatch.md` §3 的表（這屬於語意變更，但船長本人改不用問任何人）。

## 這套制度最可能的退化方式與預防

1. **規則膨脹**：每次踩坑加一條，CLAUDE.md 變成 200 行，弱模型讀不完等於全部失效。預防已寫進 `maintenance.md`：一坑最多一條、行數上限、精簡協議。膨脹訊號出現時優先執行精簡，不要再加。
2. **儀式化**：模板照抄但驗收條件填成「做完即可」、read-back 變成「看過了沒問題」四個字。這是最陰險的退化——形式都在，功能全失。預防：`templates.md` 的審查模板強制「試著推翻」立場、PASS 必附執行證據。如果你發現自己收到的驗收報告沒有命令輸出原文，那就是儀式化正在發生，退回重驗。
3. **路由失聯**：session 忙起來就不讀 doctrine，CLAUDE.md 的觸發表變擺設。預防：觸發條件已寫成具體情境而非抽象原則。如果你此刻在讀這封信卻想不起來上次讀 `judgment.md` 是什麼時候，就是這個退化。
4. **過度派工反噬**：trivial 小事也開三個 agent 加 fresh 驗收，延遲與成本讓船長受不了而整套棄用。預防：`model-dispatch.md` §1 的「不派清單」和 `judgment.md` §3 的「不該問清單」跟正面清單同等重要，別只執行正面那半。

## 交接狀態

- A–G 全部落檔完成。
- 收尾三步（對抗審查、read-back、總結）：若本信之後沒有其他標記，表示已在原 session 完成；若你發現 doctrine 檔之間有明顯矛盾或路徑錯誤，可能是審查被中斷，照 `maintenance.md` 流程修正即可。

## 最後一句

這套制度的核心只有一句話：**主對話保持乾淨，判斷交給判準，驗收交給別人。** 檔案都可以改，這句不要丟。

---

## 後記（2026-07-13，原 session 追加；三件事均已有著落）

- §1 plugin 盤點：已用 session transcript 的實際使用數據掃描，結果與建議見當日回報。
- §2 ~/.claude 入 git：已完成，repo 為 github.com/finnjin/claude-config（private）。範圍經船長裁定收斂為 harness 制度與設定四樣：CLAUDE.md、doctrine/、settings.json、.gitignore（白名單式）。客製化 command/skill/agent、memory、statusline 等不屬於本 repo——船長另外版控（如 cc-statusline）。
- §3 成本模式：船長確認 token 非瓶頸，瓶頸是**時間**（主對話歷來全用 opus 4.8）。`model-dispatch.md` §3 已改為「需要判斷就用 opus、小模型只為快」。opus 的幻覺是模型本身的 bug（context 污染後自擬工具輸出），船長明確指示：**不要**在 doctrine 加防幻覺規則——加了對它沒用，反而增加健康 context 的負擔。
- 另：codex-rescue 經船長指示（不穩定）已移出常規流程；`model-dispatch.md` 與 `judgment.md` 已改為每 session 經 CLAUDE.md `@import` 自動載入。
