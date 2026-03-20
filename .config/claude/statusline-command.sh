#!/usr/bin/env bash
# Claude Code statusLine script
# Output format: Sonnet 4.6 | main | 10.2K (20%) | 5h 42% | 7d 86%

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "Unknown"' | sed 's/^Claude //')

used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
# used_tokens = input + cache_creation + cache_read (matches used_percentage formula per docs)
used_tokens=$(echo "$input" | jq -r '
  (.context_window.current_usage.input_tokens // 0)
  + (.context_window.current_usage.cache_creation_input_tokens // 0)
  + (.context_window.current_usage.cache_read_input_tokens // 0)
  | if . == 0 then empty else . end
')

five_hour_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
seven_day_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

branch=$(git branch --show-current 2>/dev/null)
branch_part=${branch:+" | $branch"}

pct_color() {
  local pct=$1
  if [[ "$pct" -ge 90 ]]; then printf '\033[31m'
  elif [[ "$pct" -ge 70 ]]; then printf '\033[33m'
  else printf '\033[32m'; fi
}

if [[ -n "$used_pct" && -n "$used_tokens" ]]; then
  pct=$(printf "%.0f" "$used_pct")
  fmt_k=$(awk "BEGIN {printf \"%.1fK\", $used_tokens / 1000}" | sed 's/\.0K/K/')
  printf "%s%s | %s (%b%s%%\033[0m)" "$model" "$branch_part" "$fmt_k" "$(pct_color "$pct")" "$pct"
else
  printf "%s%s | --" "$model" "$branch_part"
fi

if [[ -n "$five_hour_pct" ]]; then
  pct5=$(printf "%.0f" "$five_hour_pct")
  printf " | 5h (%b%s%%\033[0m)" "$(pct_color "$pct5")" "$pct5"
fi

if [[ -n "$seven_day_pct" ]]; then
  pct7=$(printf "%.0f" "$seven_day_pct")
  printf " | 7d (%b%s%%\033[0m)" "$(pct_color "$pct7")" "$pct7"
fi
