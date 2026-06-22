#!/usr/bin/env bash
# Claude Code statusLine script
# Output format: Sonnet 4.6 | main | 10.2K (20%) | cache hit 94% (read 47.2K / write 2.6K) | 5h 42% | 7d 86%

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

# cache breakdown from the last API response (null before first call / right after /compact)
cache_read=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
cache_write=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
cache_input=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
cache_total=$(( cache_read + cache_write + cache_input ))

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

# inverse of pct_color: high cache hit rate is good (green)
cache_color() {
  local pct=$1
  if [[ "$pct" -ge 80 ]]; then printf '\033[32m'
  elif [[ "$pct" -ge 50 ]]; then printf '\033[33m'
  else printf '\033[31m'; fi
}

# format a token count as "12.3K" (drop the .0 for whole values)
fmt_k() {
  awk "BEGIN {printf \"%.1fK\", $1 / 1000}" | sed 's/\.0K/K/'
}

if [[ -n "$used_pct" && -n "$used_tokens" ]]; then
  pct=$(printf "%.0f" "$used_pct")
  printf "%s%s | %s (%b%s%%\033[0m)" "$model" "$branch_part" "$(fmt_k "$used_tokens")" "$(pct_color "$pct")" "$pct"
else
  printf "%s%s | --" "$model" "$branch_part"
fi

if [[ "$cache_total" -gt 0 ]]; then
  hit=$(( cache_read * 100 / cache_total ))
  printf " | cache hit %b%s%%\033[0m (read %s / write %s)" "$(cache_color "$hit")" "$hit" "$(fmt_k "$cache_read")" "$(fmt_k "$cache_write")"
fi

if [[ -n "$five_hour_pct" ]]; then
  pct5=$(printf "%.0f" "$five_hour_pct")
  printf " | 5h (%b%s%%\033[0m)" "$(pct_color "$pct5")" "$pct5"
fi

if [[ -n "$seven_day_pct" ]]; then
  pct7=$(printf "%.0f" "$seven_day_pct")
  printf " | 7d (%b%s%%\033[0m)" "$(pct_color "$pct7")" "$pct7"
fi
