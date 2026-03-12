#!/usr/bin/env bash
# Claude Code statusLine script
# Output format: Sonnet 4.6 | 10.2K tkns. (20%)

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "Unknown"' | sed 's/^Claude //')

used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
# used_tokens = input + cache_creation + cache_read (matches used_percentage formula per docs)
used_tokens=$(echo "$input" | jq -r '
  (.context_window.current_usage.input_tokens // 0)
  + (.context_window.current_usage.cache_creation_input_tokens // 0)
  + (.context_window.current_usage.cache_read_input_tokens // 0)
  | if . == 0 then empty else . end
')

branch=$(git branch --show-current 2>/dev/null)
branch_part=${branch:+" | $branch"}

if [[ -n "$used_pct" && -n "$used_tokens" ]]; then
  pct=$(printf "%.0f" "$used_pct")
  fmt_k=$(awk "BEGIN {printf \"%.1fK\", $used_tokens / 1000}" | sed 's/\.0K/K/')

  if [[ "$pct" -ge 90 ]]; then color='\033[31m'
  elif [[ "$pct" -ge 70 ]]; then color='\033[33m'
  else color='\033[32m'; fi

  printf "%s%s | %s (%b%s%%\033[0m)" "$model" "$branch_part" "$fmt_k" "$color" "$pct"
else
  printf "%s%s | --" "$model" "$branch_part"
fi
