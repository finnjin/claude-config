#!/opt/homebrew/bin/bash
input=$(cat)

# 取消下行註解可 dump 真實 payload 來校準欄位路徑
# printf '%s' "$input" > /tmp/cc_statusline_input.json 2>/dev/null

readarray -t F < <(jq -r '
  .model.display_name // "?",
  .workspace.current_dir // "",
  (.cost.total_cost_usd // 0),
  (.cost.total_lines_added // 0),
  (.cost.total_lines_removed // 0),
  ((.cost.total_duration_ms // 0) | floor),
  ((.context_window.used_percentage // 0) | floor),
  ((.rate_limits.five_hour.used_percentage // 0) | floor),
  ((.rate_limits.seven_day.used_percentage // 0) | floor),
  ((.rate_limits.five_hour.resets_at // 0) | floor),
  ((.rate_limits.seven_day.resets_at // 0) | floor),
  ((.context_window.current_usage.cache_read_input_tokens // 0) | floor),
  ((.context_window.total_input_tokens // 0) | floor),
  ((.context_window.current_usage.input_tokens // 0) | floor),
  ((.context_window.current_usage.output_tokens // 0) | floor)
' <<<"$input")
MODEL=${F[0]}
DIR=${F[1]}
COST=$(printf '%.2f' "${F[2]}")
ADDED=${F[3]}
REMOVED=${F[4]}
DURATION=$(( ${F[5]} / 1000 ))
CTX=${F[6]}
FIVE=${F[7]}
SEVEN=${F[8]}
FIVE_RESET=${F[9]}
SEVEN_RESET=${F[10]}
CACHE_READ=${F[11]}
TOTAL_INPUT=${F[12]}
TURN_IN=${F[13]}
TURN_OUT=${F[14]}


RESET='\033[0m'; CYAN='\033[36m'
GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; TAN='\033[38;5;180m'; PURPLE='\033[38;5;141m'

# detached HEAD（checkout tag/sha、rebase 中）時 --show-current 回空，退回 short SHA
BRANCH=$(git branch --show-current 2>/dev/null)
[ -z "$BRANCH" ] && BRANCH=$(git rev-parse --short HEAD 2>/dev/null)
[ -z "$BRANCH" ] && BRANCH="no git"

# bar PCT [WIDTH] -> colored progress bar (green<70<=yellow<90<=red)
bar() {
  local pct=$1 width=${2:-10} color halves full half empty
  if   [ "$pct" -ge 90 ]; then color=$RED
  elif [ "$pct" -ge 70 ]; then color=$YELLOW
  else color=$GREEN; fi
  # 半格精度：先換算成「半格數」，再拆成整格 + 一個可選的左半格 ▌
  halves=$(( pct * width * 2 / 100 ))
  full=$(( halves / 2 )); half=$(( halves % 2 )); empty=$(( width - full - half ))
  local fbar ebar hbar=""
  printf -v fbar "%${full}s" ""; fbar=${fbar// /█}
  printf -v ebar "%${empty}s" ""; ebar=${ebar// /░}
  [ "$half" -gt 0 ] && hbar="▌"
  # 輸出會被外層 printf 當 format 再解析一次（共兩層），故 %%%% 兩次收斂為單一 %
  printf "${color}${fbar}${hbar}${ebar} ${pct}%%%%${RESET}"
}

# human N -> 1234->1.2K, 1500000->1.5M
human() {
  local n=$1
  if   [ "$n" -ge 1000000 ]; then printf '%d.%dM' $((n/1000000)) $(((n%1000000)/100000))
  elif [ "$n" -ge 1000 ];    then printf '%d.%dK' $((n/1000)) $(((n%1000)/100))
  else printf '%d' "$n"; fi
}

countdown() {
  printf $(( $1 - $(date +%s) ))
}

show_time() {
  local s=$1
  d=$(( $1 / 86400 )); h=$(( $1 % 86400 / 3600 ));
  m=$(( $1 % 3600 / 60 )) s=$(( $1 % 60 ))
  if   [ "$d" -gt 0 ]; then printf "${d}d${h}h"
  elif [ "$h" -gt 0 ]; then printf "${h}h${m}m"
  else printf "${m}m${s}s"; fi
}

cache_info() {
  local pct
  if [ "$TOTAL_INPUT" -eq 0 ]; then pct=0
  else pct=$(( CACHE_READ * 100 / TOTAL_INPUT )); fi
  printf "${TAN}${pct}%%%% cached${RESET}"
}


# line 1: model, dir, branch
printf "${CYAN}[$MODEL]${RESET} 📁 ${DIR##*/} | 🌿 $BRANCH"
printf "\n"

# line 2: context window — 多滿 + 這坨 input 有多少來自 cache（與 ctx bar 同一坨 token）
printf "ctx $(bar "$CTX" 20) - $(human "$TOTAL_INPUT") / $(cache_info)"
printf "\n"

# line 3: 5h / 7d bars (+ reset countdown)
printf "5h  $(bar "$FIVE") - $(show_time $(countdown $FIVE_RESET))"
printf " │ "
printf "7d  $(bar "$SEVEN") - $(show_time $(countdown $SEVEN_RESET))"
printf "\n"

# line 4: cost | +/- lines | turn I/O (⬆in ⬇out) | time
printf "💰 ${YELLOW}$COST${RESET}"
printf " │ "
printf "${GREEN}+$ADDED${RESET} ${RED}-$REMOVED${RESET}"
printf " │ "
printf "${CYAN}⬆ $(human "$TURN_IN")${RESET} ${PURPLE}⬇ $(human "$TURN_OUT")${RESET}"
printf " │ "
printf "⏱️ $(show_time "$DURATION")"
printf "\n"
