# Harness 診斷（2026-08-08，由 Fable 5 撰寫）

本檔是 2026-08-08 這輪 doctrine 修訂的依據。歷史文件，基本不改。前一輪見 `diagnosis.md`（2026-07-12）。

## 數據（2026-08-08 重算，樣本 2026-07-07 ~ 08-07；腳本已實跑驗證）

130 個主 session（77 個有派工）、主對話 Agent 呼叫 703 次、subagent transcript 751 份。

- **P1 發包權失控**：68 個 subagent 自行再呼叫 Agent 共 173 次，且**存在第三層**（meta.json spawnDepth：depth2=141、depth3=30；舊報告稱「無第三層」是用目錄結構判斷的方法錯誤——所有層級的 transcript 平放在同一個 `subagents/` 目錄）。三個案例抽查證實：巢狀派工**皆非 prompt 授權**、也**不是 superpowers skill 誘發**（`dispatching-parallel-agents` 只出現在被動 skill listing，從未被 invoke）——是 subagent 拿到大範圍盤點任務時的自發行為。修法依據的機制事實：**subagent 的 context 載入完整 CLAUDE.md + doctrine**（2026-08-08 實測），所以「指揮官模式→派 subagent」的指令 subagent 也讀得到、也會照做。修法：model-dispatch.md §0 執行者守則（身分判別＋禁止再派工），寫在 subagent 讀得到的位置。
- **P2 指揮官無 ground-truth 接觸點**：素材是摘要（深至第三層時是摘要的摘要的摘要），驗收外包。修法：§1 勞動/理解分類——勞動照派，決策素材親讀原文，verifier 回報抽查 `檔案:行號`。
- **P3 延遲結構**：opus 佔派工 80%（08 月 92%）× worker→verifier 一律串行。TaskOutput 僅 4 次、TaskStop 7 次＝fire-and-forget；07-27 另有主對話 sleep/輪詢空轉實錄。修法：§8 驗證分級（低風險不開 verifier）、§4 時間預算與同步選項、§5 等待紀律。
- **P4 規則太絕對導致陽奉陰違**：「不下場」門檻下，主對話仍自己跑了 Bash 3361 / Edit 1165 / Read 675 次。一刀切的「>3 檔就派」在時間壓力下必被繞過。修法：把硬門檻換成可核對的分類判準（勞動 vs 理解）＋護欄（一次讀 >5 檔或 >500 行還沒到決策點就改派工），讓規則形狀貼近實際會被遵守的行為。

## 決策紀錄

- **superpowers plugin 移除（船長 2026-08-08 決定）**：乾淨移除、不蒸餾、不補償——這是 ablation 實驗。理由：(a) brainstorming 船長已改用 /opsx:explore；(b) systematic-debugging 的價值是混淆變數，蒸餾等於把混淆永久化；(c) doctrine 只收船長確認過的判斷。若日後除錯/需求釐清品質可觀察退化，憑證據再決定是否引入對應流程。附帶：其 SessionStart hook 的強制注入（「1% 適用就 MUST」）同時消失；P1 已證實與該 plugin 無關，但注入稅仍省下。
- **上一輪修訂方向 7 條全數採納**，無推翻。修正兩處事實：無第三層→實有 30 個 depth3；superpowers 誘發 P1 假說→數據推翻（見上）。
- 「可腳本化卻派 n 個 agent」數據不支持為現行問題，§6 為預防性短條款。
- **plugin 與 skill 路由（船長 2026-08-08 逐項確認）**：atlassian plugin 停用（船長已改用 acli，/jira 命令同步改寫）；codex plugin 保留（CC 外仍有 codex 工作流）；/cr 系列停用（船長：「沒時間優化，都用原生 /code-review」），CLAUDE.md 路由同步改。settings.json 中船長先前未 commit 的本地調整（defaultMode、connectors、skillOverrides、i-have-adhd plugin）依船長指示一併入版控，獨立 commit。

## 驗證方式（供未來重算）

主對話：`~/.claude/projects/<proj>/<session-uuid>.jsonl`；subagent：`<proj>/<session-uuid>/subagents/agent-*.jsonl`（**各層平放**，層級看 `agent-*.meta.json` 的 `spawnDepth`）。巢狀發包＝agent 檔內 `message.content[].type=="tool_use"` 且 name 為 Agent/Task。重算腳本樣本：scratchpad `restat/restat.py`（session 目錄會輪替，過期就重寫）。
