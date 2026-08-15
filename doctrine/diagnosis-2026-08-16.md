# Harness 診斷（2026-08-16，由 Fable 5 撰寫）

本檔是 2026-08-16 這輪 §1 改寫的依據。歷史文件，基本不改。前一輪見 `diagnosis-2026-08.md`。

## 問題

船長的原始目標一直是**主對話 context 精簡**（context 大→降智）。兩版派工原則都沒把這件事寫進判準，只在管「誰做什麼」，於是鐘擺：

- V1（07-12）硬門檻「不下場」→ 過度派工：subagent 任務太大（p90 20+ 分）、連讀計畫都外包、subagent 再派工（68 個巢狀案例）。
- V2（08-08）勞動/理解分類 + 一堆「不要過度派工」反例 + 把冷啟動很貴寫進條文 → 完全不派：視窗修正後 08-09～15 七日 self-exec share 99%、主 ctx p90 542k、subagent 僅 14 個；使用者一次給兩件可平行的事，主對話 inline 串行做、做完第一件停下等、修改幾輪後忘了第二件。
- 兩版都是用散文調權重，模型讀到最新強調就過衝。滑坡入口是例外條款：「位置已知直接做」「單檔小修直接做」——每件事都能講成小修，inline 進入改→跑→錯→再改。

## 決策

- **不用 context 大小當判準**（船長 2026-08-16）：會 Goodhart——模型為了數字藏 context。context 大小只當關帳指標。
- 判準改成**看動詞**：探索（找/查/追）→ 派 Explore；執行（改/跑/修，有回饋迴圈）→ 派 agent；運籌（定/寫 brief/審結論/答使用者）→ 自己。Read 只有三個合法用途（使用者指定段落、抽查回報引用、計畫/findings/交付物等文字產物）；唯一例外是「無回饋迴圈的一次 Edit」，判準是回饋迴圈不是「小」。
- **fork 不預設也不禁**（船長：預設不用太硬）：理解住在對話裡→ fork；住在檔案裡→ fresh + brief。fork 繼承主對話 context 與其降智，主對話跑過多輪迴圈後落檔再 fresh 派。fork 的機制細節不寫進 doctrine（schema 自帶）。
- 多任務三步（TaskCreate → 同訊息並行 → TaskList 清完才結束 turn）寫進 CLAUDE.md 與 §1。
- Explore 沒有 Agent 工具：巢狀問題從條文禁令升級為結構保證。

## 數據修正

`~/.claude/scripts/spawn-depth-stats.py` 的 7 日視窗原本用主 session 的**最後** timestamp 過濾，長命 session 會把修訂前的 subagent 全拖進視窗（08-15 報表 depth≥2=86，全來自 07-19～08-07 起跑的 subagent）。改成 subagent 用自己的第一個 timestamp 過濾後：08-08 後 26 個 subagent、depth 全 1、巢狀 0。

## 關帳（2026-09-15 後）

盯兩個結果指標：主 ctx p90（08-15 基線 542k，應明顯下降）與 self-exec share（基線 99%，應下降）；depth≥2 維持 0。舊指標「主對話 Bash/Edit/Read 次數」作廢——它量的是 V1 的門檻。
