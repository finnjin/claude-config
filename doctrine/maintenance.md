# Doctrine 維護協議

本目錄（`~/.claude/doctrine/`）與 `~/.claude/CLAUDE.md` 是跨 session 的制度檔。改壞的代價是之後每個 session 都變笨，所以更新要照本協議。

## 檔案清單與角色

| 檔案 | 角色 |
|---|---|
| `~/.claude/CLAUDE.md` | 每 session 載入的路由 + 一行版規則。**保持精簡**（≤ 45 行）。 |
| `diagnosis.md` | 制度的依據（2026-07 的問題診斷）。歷史文件，基本不改。 |
| `diagnosis-2026-08.md` | 2026-08 修訂輪的診斷與決策紀錄（發包權單層化、驗證分級、superpowers ablation）。歷史文件，基本不改。其中發包權單層化與 depth≥2 類指標已被取代——現行判準是交付物型態（model-dispatch.md §0），letter/diagnosis 裡的舊指標勿再執行。 |
| `diagnosis-2026-08-16.md` | 2026-08-16 §1 改寫的診斷與決策（看動詞判準、context 不當判準、fork 取捨、多任務三步）。歷史文件，基本不改。 |
| `engineering.md` | 工程原則完整版。 |
| `model-dispatch.md` | 派工與模型選擇。 |
| `judgment.md` | 判斷 rubric。 |
| `templates.md` | 派工模板。 |
| `maintenance.md` | 本協議。 |
| `letter.md` | 給未來 session 的信（2026-07）。歷史文件，不改。 |
| `letter-2026-08.md` | 給未來 session 的信（2026-08）。歷史文件，不改。 |

## 可以自行改（不用問使用者；本節權限僅主對話適用，subagent 一律不改 doctrine，發現問題寫進回報）

- **修正已驗證的事實錯誤**：路徑不存在、工具名/參數名變了、模型型號下架。條件：先實際驗證新事實（跑命令、查文件），改動處註記日期。
- **補範例**：在既有規則下新增正例/反例，不改變規則語意。
- **新增踩坑教訓**：見下方「教訓寫回哪裡」。

## 動之前必須先問使用者

- 改變任何規則的**語意**（放寬、收緊、刪除），包括升降級門檻、驗收標準、「該問使用者」的清單本身。
- 改 CLAUDE.md 的路由結構或 Git 紅線、「是的船長」等使用者個人規則。
- 大規模精簡/重組（見下方精簡協議）。

判斷不確定時 → 當作要問。

## 教訓寫回哪裡（踩坑後的標準動作）

1. **原始教訓**寫到 memory：`~/.claude/projects/-Users-finnjin/memory/` 新增 `feedback_*.md` 或 `project_*.md`（照該目錄既有 frontmatter 格式），並在 `MEMORY.md` 加一行索引。
2. **只有當教訓可一般化成規則**（同類坑會再發生、判準能寫成可執行條件），才回寫 doctrine：
   - 派工/模型相關 → `model-dispatch.md`
   - 何時停/何時算完成 → `judgment.md`
   - 測試/commit/介面相關 → `engineering.md`
3. 回寫格式：融入既有章節（附正例/反例），不要在檔尾另開「雜項教訓」清單——清單會無限膨脹且沒人讀。
4. 一次踩坑 = 最多一條規則。不要因為一次事故加三條防禦性規定（違反使用者的「不要沒意義的防呆」原則）。

## 修改的標準流程

`~/.claude` 已是 git repo（2026-07-13 起，origin: github.com/finnjin/claude-config，private）。git 取代舊的 `.bak` 備份機制。

1. 確認 working tree 乾淨（`git -C ~/.claude status`），不乾淨先弄清楚為什麼。
2. 修改。
3. 自我檢查三件事：新舊規則有無互相矛盾、引用的路徑/工具名是否存在（實際驗證）、弱模型讀了會不會誤解（有沒有模糊詞）。
4. 涉及語意變更的，派一個 fresh agent read-back 審查後才算完成。
5. Commit（訊息寫改了哪條規則、為什麼）並 push。本 repo 是個人設定 repo，預設直接 commit 到 main——這是「不 commit 主線」規則的顯式例外；船長若不同意，改掉本條即可。

## 精簡協議（何時瘦身）

- 觸發條件：CLAUDE.md 超過 45 行，或單一 doctrine 檔超過 200 行，或範例出現重複。
- 精簡是語意判斷，**必須先問使用者**，並由當時可用的最強模型執行，完成後 fresh agent 對照新舊版確認沒有規則遺失。
- 精簡方向：合併重複範例、把過時內容移到 `檔案.archive.md`，不直接刪。

## 備份清理

舊制的 `doctrine/*.bak-*` 檔已被 git 取代，看到可直接刪（git history 是唯一備份機制）。例外：`~/.claude/CLAUDE.md.pre-doctrine-bak` 是 doctrine 化之前的原版 CLAUDE.md、被 `letter.md` 引用且未入版控，**不可刪**。
