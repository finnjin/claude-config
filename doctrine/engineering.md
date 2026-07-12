# 工程原則（完整版）

CLAUDE.md 只放一行版；這裡是完整判準與範例。改動本檔前先讀 `maintenance.md`。

## 測試先行

先寫測試、建立 baseline，再做變更。改完才補測試只能證明「新版能跑」，不能證明「跟舊版行為一致」。

- 如果測試不可行，必須在回覆裡說明原因並記錄，不能自己默默跳過。
- 禁止 tautological test：在測試裡重新實作一遍邏輯來驗自己。
  - 反例：`assert Calc(x) == x * rate + fee`（把公式抄進測試）。
  - 正例：`assert Calc(100) == 105`（寫死已知正確的具體值）。
- 禁止 over-mocking：只驗 mock 接線，沒驗行為。
  - 反例：mock 掉 repository 後只 assert `repo.Save` 被呼叫一次。
  - 正例：用 in-memory/測試 DB 驗存進去的資料真的是預期內容。
- 測 script 必須用 production 實際的 interpreter。macOS `/bin/bash` 是 3.2，沒有 `readarray`；CI 上是新版 bash。用錯環境測等於沒測。

## Commit 自洽

每個 commit 同時滿足 reviewable + deployable：

- Reviewer 看單一 commit 就能完整理解變更。
- 修正必須 squash 回原 commit，不另開 fixup commit。
- 不混雜無關異動。順手修的小東西（見童子軍守則）如果和主變更無關，開獨立 commit。

## 對外介面不變

遷移或重構時，對外行為（API、routes、response 格式、錯誤碼）預設保留，除非明確討論後決定改變。

- 正例：重構 controller 內部結構，response JSON 欄位順序與名稱不動。
- 反例：「順便」把 snake_case 改成 camelCase——這是 breaking change，必須先問。

## 不修改團隊共用檔案

`.gitignore`、CI 設定、`*.sln`、共用 config 等團隊共用檔案，不為本地一時方便而改動。本地需求用本地機制解（如 `.git/info/exclude`）。

## 童子軍守則

離開時讓營地比進來時乾淨。順手修正路徑上的小問題（rename、移除 dead code、cosmetic、typo fix）是 acceptable 的。

- 邊界判準：改動能一眼看懂、不需要額外測試、不會引出討論——才算「順手」。
- 一旦改動規模變大、或小問題背後暴露更深的設計問題，停下來，獨立處理（另開 commit/branch，或先回報）。

## Code review：第一性原理 > status-quo 一致性

看到「但 codebase 既有慣例是這樣」是警訊，不是理由。發現缺陷就指出；方向對的 comment 即便 scope 大、actionable 度低，也比沉默有價值。

- 「破一致性」不是反對 comment 的理由——一致性不該綁住對的方向。
- Review 是知識同步工具，可以接受「這次不改、但記下來」。
- 邊界：純粹個人偏好（風格、命名品味）不在此列，這條只針對技術正確性。

## Code review：push back 要有 evidence

被 challenge 時先檢查自己的論點站不站得住，站得住就堅守。不能因為對方語氣強、或對方是 PR 作者就軟掉。

- 站得住但被 challenge → 用更具體的證據回應（跑 test、查文件、grep code），不是換個說法重講一遍。
- 讓步前強制問自己：「對方論點哪一段比我的強？具體在哪？」答得出來才能 concede。
- 對方提供新事實（org context、團隊政策、framework 限制）→ update 自己的判斷；對方只是語氣強烈 → 不 update。
