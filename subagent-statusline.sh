#!/opt/homebrew/bin/bash
# settings.json 的 subagentStatusLine hook：harness 在 footer 的 agent tree 為每個 subagent
# 顯示一行，這支 script 決定那一行的內容。
#
# stdin（實測 v2.1.222）：
#   {session_id, transcript_path, cwd, prompt_id, columns,
#    tasks:[{id, type, status, description, label, startTime, model,
#            contextWindowSize, tokenCount, tokenSamples[], cwd}]}
# stdout：每行一個 {"id","content"}；id 必須是 stdin 給的 tasks[].id。
#
# harness 側的硬限制（實測自 v2.1.222 binary）：
#   - content 會「取代」預設的 name/描述/耗時/token 欄位，只保留 ● 前綴，
#     所以想看的資訊都得自己印。
#   - 最多同時顯示 5 行，其餘折成「N more」。
#   - content 為空字串 = 隱藏該行（不是顯示空白）。
#   - 逐行 JSON.parse + schema 驗證 {id:string, content:string}；壞行靜默丟棄，
#     只在 claude --debug 留 error log。
#   - timeout 5s，非零 exit 會清掉「所有」行並退回預設渲染 → 這支要保持輕量。
#   - 首次於 tasks 出現後 300ms 執行，之後每 5s 一次。
#   - agentType === "main-session" 被 harness 排除，主 agent 那行拿不到 decoration。
#
# 顯示 ⬢ 42% 84.1k ⟳1 ▲6.2k 3m12s opus · 描述
#   %      以 contextWindowSize 為分母。不同 model 的 window 不同（opus/sonnet 可能是 1M），
#          所以跨 model 時百分比不可比，絕對值才可比。40%/70% 分級上色。
#   ⟳n     這個 agent 已 auto-compact 過 n 次——用量看起來健康的一行，可能已經丟掉前面的內容。
#   ▲      最近約 80 秒的 context 成長量（tokenSamples 是 16 格滑動窗口，tick 5s）。
#          整個窗口沒動就不顯示，所以「▲ 不見 + 時間持續累積」= agent 卡住。
set -uo pipefail

input=$(cat)

# state 檔：compact 次數必須跨 tick 累積——tokenSamples 只涵蓋最近 80 秒，
# 更早發生的壓縮會隨窗口滑走而消失。只保留當前 tasks 的 id，結束的 agent 自動淘汰。
STATE_DIR=${TMPDIR:-/tmp}/cc-subagent-compact
mkdir -p "$STATE_DIR" 2>/dev/null
S="$STATE_DIR/$(jq -r '.session_id // "unknown"' <<<"$input").json"
[ -f "$S" ] || printf '{}' > "$S"

out=$(jq -c \
   --slurpfile prev "$S" \
   --argjson now "$(( $(date +%s) * 1000 ))" \
   --argjson cols "$(jq -r '.columns // 120' <<<"$input")" '
  def esc: "\u001b[" + . + "m";
  def short:
    if . >= 1000 then (((. / 100) | floor) / 10 | tostring) + "k"
    else (. | tostring) end;
  def dur:
    if . < 60 then "\(.)s"
    elif . < 3600 then "\((. / 60) | floor)m\(. % 60)s"
    else "\((. / 3600) | floor)h\(((. % 3600) / 60) | floor)m" end;
  def clip($n): if (. | length) > $n then (.[0:$n] + "…") else . end;

  (((($cols - 44) / 2) | floor) as $w | (if $w < 12 then 12 else $w end)) as $dw
  | ("0" | esc) as $rst | ("2" | esc) as $dim
  | ($prev[0] // {}) as $old
  | [ .tasks[]? ] as $tasks
  # tokenCount 只會單調成長，除非 compact。掉超過 1000 就記一次（1000 是噪音餘裕）。
  | (reduce $tasks[] as $t ({};
      .[$t.id] = {
        last: ($t.tokenCount // 0),
        count: (($old[$t.id].count // 0)
                + (if (($old[$t.id].last // 0) - ($t.tokenCount // 0)) > 1000
                   then 1 else 0 end))
      })) as $new
  | { state: $new,
      rows: [ $tasks[]
        | . as $t
        | (($t.contextWindowSize // 200000) | if . == 0 then 200000 else . end) as $win
        | ($t.tokenCount // 0) as $tok
        | (($tok * 100 / $win) | floor) as $pct
        | (if $pct >= 70 then "31;1" elif $pct >= 40 then "33" else "32" end | esc) as $col
        | ($new[$t.id].count // 0) as $cmp
        | (if $cmp > 0 then " \("35;1" | esc)⟳\($cmp)\($rst)" else "" end) as $compact
        # 開頭的 0（agent 剛啟動）要濾掉，否則首次成長會被算成「從 0 長到全部」
        | (($t.tokenSamples // []) | map(select(. > 0))) as $samples
        | (if ($samples | length) >= 2 then ($samples[-1] - $samples[0]) else 0 end) as $delta
        | (if $delta > 0 then " \($dim)▲\($delta | short)\($rst)" else "" end) as $growth
        | (((($now - ($t.startTime // $now)) / 1000) | floor) as $sec
           | if $sec > 0 then " \($dim)\($sec | dur)\($rst)" else "" end) as $age
        | (($t.model // "") | if test("haiku") then "haiku"
             elif test("sonnet") then "sonnet"
             elif test("opus") then "opus"
             elif test("fable") then "fable"
             else (split("-") | .[1] // "?") end) as $model
        | (if $t.status == "running" then "⬢" else "✓" end) as $mark
        | (($t.description // $t.label // "") | clip($dw)) as $desc
        | { id: $t.id,
            content: "\($mark) \($col)\($pct)%\($rst) \($tok | short)\($compact)\($growth)\($age) \($dim)\($model)\($rst) \($dim)·\($rst) \($desc)" } ] }
' <<<"$input")

printf '%s' "$out" | jq -c '.state' > "$S"
printf '%s' "$out" | jq -c '.rows[]'
