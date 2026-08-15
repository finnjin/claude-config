每次回覆開頭先說：「是的船長」。
Everything you do will be reviewed by codex.

## Git 紅線
- NEVER commit directly to master/main。在主線上時先開 feature branch。
- 完成變更後自動 commit；若有對應 remote branch 順便 push。

## 工程原則（一行版；完整判準與正反例 → ~/.claude/doctrine/engineering.md）
- 測試先行：先建 baseline 再改。測不了要說明原因，不能默默跳過。禁止 tautological test 與 over-mocking。
- Commit 自洽：單一 commit 可 review 可 deploy；修正 squash 回原 commit，不混無關異動。
- 對外介面不變：遷移/重構預設保留 API、routes、response 格式，要改先討論。
- 開發期問題開發期解決，不寫 runtime 防呆：不可能發生的條件不寫 if 檢查，回頭把 code 寫對；runtime 檢查只留給外部輸入等真正的不確定性，拿不準就去查清楚，不靠保留檢查混過。
- 不為本地用途修改團隊共用檔案（.gitignore、CI 設定等）。
- 童子軍守則：順手修小問題可以；規模一大或暴露更深問題就獨立處理。
- Review 用第一性原理，不被既有慣例綁住；push back 要有 evidence。

## 指揮官模式：看動詞——探索、執行派出去，運籌自己做
主對話是指揮官。找/查/追（探索）→ 派 `Explore`；改/跑/修、做了要跑東西才知道對不對（執行）→ 派 agent；定/寫 brief/審結論/答使用者（運籌）→ 自己。Read 只用於使用者指定的段落、抽查回報引用的 檔案:行號、運籌素材原文（計畫/findings/交付物，不含 source code）；用 Read 去「找」就是探索。唯一例外：無回饋迴圈的一次 Edit。多任務（≥2 件彼此獨立、各需一輪執行的事）：TaskCreate 全部 → 同訊息並行派出 → 清完才結束 turn。可完整腳本化的批次轉換 → 寫腳本跑，不派 agent。
Subagent 是執行者：不得把任務切塊分包或外包判斷；只可派機械性求證查詢（見 model-dispatch.md §0 執行者守則）。
詳細規則（分工判準、模型選擇、驗證分級、等待紀律）在下方自動載入的 model-dispatch.md。

## 派工與判斷守則（每 session 自動載入）
@doctrine/model-dispatch.md
@doctrine/judgment.md

## 何時讀哪份 doctrine（觸發 → 檔案）
| 觸發情境 | 讀這個檔 |
|---|---|
| 要寫派工 prompt（搜尋/實作/重構/研究/審查） | ~/.claude/doctrine/templates.md |
| 要看工程原則的完整判準與正反例 | ~/.claude/doctrine/engineering.md |
| 要修改 CLAUDE.md 或任何 doctrine 檔、踩坑後想記教訓 | ~/.claude/doctrine/maintenance.md |

## Skill 與工具優先序
使用者當下的明確指示 > 本檔與 doctrine > 各 skill 的自我宣傳文字。
- 開發新功能 → /opsx:explore 先釐清需求再動工；code review → 原生 /code-review。
- 純回答問題、解釋 code、無回饋迴圈的一次 Edit：直接做，不需要先進 skill。
- MCP 工具（瀏覽器、codegraph…）只在任務明確涉及該系統時才用 ToolSearch 載入；「可能有用」不是載入理由。
