# Harness 診斷（2026-07-12，由 Fable 5 撰寫）

本檔是後面所有 doctrine 檔的依據。三個問題按嚴重度排序，每個附證據與修法。
修法的落地位置標在各節末尾。

## 問題 1：主對話自己下場讀檔掃 repo（最大 token 漏）

**證據**：
- permissions allowlist 裡塞滿 `cat/head/tail/find/grep/rg`——歷史上大量主對話直接讀檔。
- memory 有「不要用 sed 讀檔」的 feedback，代表發生過。
- 工作場域是 `~/Repos/deliverables` 下 27 個 .NET repo。主對話一次 grep + 連環 Read 就能吃掉幾萬 token，而且讀進來的原始碼 90% 對最終結論沒貢獻，卻永久佔住 context。
- 1M context 的主模型會讓這個問題更隱蔽：不會立刻爆，但每輪推理都被無關內容稀釋，注意力品質下降、成本上升。

**修法**：主對話是指揮官，不下場。凡是「找東西」「讀超過 3 個檔」「掃 repo」「查網頁」「批次改檔」一律派 subagent，主對話只收結論與 `檔案:行號`。具體門檻與派工規格 → `model-dispatch.md`。
（2026-07-13 船長澄清：token 費用非瓶頸，瓶頸是時間。本問題的實際代價是注意力稀釋與重試時間，修法不變。）

## 問題 2：失敗重試不換路、完成宣稱不驗證（最容易出錯）

**證據**：
- memory 記錄過「用 macOS /bin/bash 3.2 測 production script」的踩坑——自己寫、自己測、自己過，測試環境還是錯的。
- CLAUDE.md 有「測試先行」「codex review」原則，但沒有升降級路徑：弱模型卡住時的預設行為是換個寫法再試一次，同一個錯誤重試 3-5 輪，token 燒掉、方向沒換。
- 「驗收」目前依賴模型自己宣稱，沒有 fresh-context 驗證的制度。寫程式的 agent 帶著「我剛寫完所以它是對的」的偏見驗自己，等於沒驗。

**修法**：
- 升降級路徑寫死：haiku/sonnet 錯一次就升級；同一子任務連錯兩次，帶完整失敗軌跡升級或換路；同一件事最多重試兩輪。→ `model-dispatch.md`
- 完成的定義改成可驗證的判準（測試實跑、read-back、第二意見），不是模型的自我感覺。→ `judgment.md`
- ~~codex-rescue agent 是現成的異質第二意見管道，寫進驗收流程。~~（2026-07-13 船長指示：codex-rescue 不穩定，不列入常規流程；第二意見改用 fresh opus 多答案評審。）

## 問題 3：Plugin/skill 生態的固定稅與誤觸（最容易失焦）

**證據**：
- superpowers 的 SessionStart hook 每個 session 注入大段強制文字（「1% 可能適用就 MUST invoke」），對弱模型是強力誤導：回答一個問題也會被拉去跑 brainstorming，讀個 code 也想先進 skill。
- 6 個 plugin 全開（atlassian/playwright/gmail/gdrive/codex/superpowers），deferred tool 超過 100 個。弱模型會在不需要時 ToolSearch 亂載 schema，或在 Jira/瀏覽器工具間迷路。
- skill 之間有重疊（cr vs code-review vs review；openspec 全域版 vs .claude scoped 版），弱模型選錯的成本是整條 workflow 跑偏。

**修法**：
- CLAUDE.md 給一張明確的 skill 優先序表：哪些情境用哪個、哪些情境明確不要進 skill。使用者指示 > CLAUDE.md > skill 自我宣傳文字。
- MCP 工具只在任務明確需要該外部系統時才 ToolSearch；「可能有用」不是理由。
- 長期解法（需要船長決定）：關掉不常用的 plugin，見 `letter.md`。

## 誠實條款：這套制度補得了什麼、補不了什麼

**補得了**：執行品質。拆解、驗證、fresh-context 驗收、多樣本評審，能把弱模型的錯誤率壓下來，把 token 花在刀口上。

**補不了**：
- **模糊題**：需求本身不清楚時，弱模型照著 checklist 也會把錯的東西做得很標準。對策：`judgment.md` 的「何時停下來問」。
- **品味判斷**：API 設計的優雅度、抽象層次的取捨、「這個方向對不對」的直覺。對策：升級模型、多答案評審選優、或問船長——但要明白這些是緩解，不是等價替代。遇到明顯是品味題的決策，寧可停下來問船長，不要讓 sonnet 假裝有品味。
