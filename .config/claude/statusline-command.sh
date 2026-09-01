#!/usr/bin/env bash
# Claude Code statusLine script
# Output format: Fable 5 xhigh | main | 10.2K (20%) | cache hit 94% | ttl 1h warm 43m | 5h 42% | 7d 86% | $19.13
# (" · N miss" appears after the hit ratio only when the session has cache misses;
#  trailing "$N.NN" is the session's estimated cost at API list prices)

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "Unknown"' | sed 's/^Claude //')

# effort is absent on models without the reasoning effort parameter
effort=$(echo "$input" | jq -r '.effort.level // empty')
fast_mode=$(echo "$input" | jq -r '.fast_mode // false')
model_part="$model"
[[ -n "$effort" ]] && model_part+=" $effort"
[[ "$fast_mode" == "true" ]] && model_part+=" fast"

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

# prompt_cache is absent until the main conversation's first response (v2.1.251+)
cache_ttl=$(echo "$input" | jq -r '.prompt_cache.ttl // empty')
cache_warm=$(echo "$input" | jq -r '.prompt_cache.warm // false')
pc_hit_ratio=$(echo "$input" | jq -r '.prompt_cache.hit_ratio // empty')
pc_misses=$(echo "$input" | jq -r '.prompt_cache.misses // 0')
pc_expires=$(echo "$input" | jq -r '.prompt_cache.expires_at // empty')

five_hour_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
seven_day_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
cost_usd=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

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
  printf "%s%s | %s (%b%s%%\033[0m)" "$model_part" "$branch_part" "$(fmt_k "$used_tokens")" "$(pct_color "$pct")" "$pct"
else
  printf "%s%s | --" "$model_part" "$branch_part"
fi

# session-wide hit ratio when available (v2.1.251+); last-response ratio as fallback
if [[ -n "$pc_hit_ratio" ]]; then
  hit=$(awk "BEGIN {printf \"%.0f\", $pc_hit_ratio * 100}")
  printf " | cache hit %b%s%%\033[0m" "$(cache_color "$hit")" "$hit"
  [[ "$pc_misses" -gt 0 ]] && printf " · %s miss" "$pc_misses"
elif [[ "$cache_total" -gt 0 ]]; then
  hit=$(( cache_read * 100 / cache_total ))
  printf " | cache hit %b%s%%\033[0m" "$(cache_color "$hit")" "$hit"
fi

if [[ -n "$cache_ttl" ]]; then
  if [[ "$cache_warm" == "true" ]]; then
    # countdown stays current only with statusLine.refreshInterval set
    ttl_left=""
    if [[ -n "$pc_expires" ]]; then
      secs=$(( pc_expires - $(date +%s) ))
      if (( secs >= 60 )); then
        ttl_left=" $(( secs / 60 ))m"
      elif (( secs > 0 )); then
        ttl_left=" <1m"
      fi
    fi
    printf " | ttl %s \033[32mwarm%s\033[0m" "$cache_ttl" "$ttl_left"
  else
    printf " | ttl %s \033[33mcold\033[0m" "$cache_ttl"
  fi
fi

if [[ -n "$five_hour_pct" ]]; then
  pct5=$(printf "%.0f" "$five_hour_pct")
  printf " | 5h (%b%s%%\033[0m)" "$(pct_color "$pct5")" "$pct5"
fi

if [[ -n "$seven_day_pct" ]]; then
  pct7=$(printf "%.0f" "$seven_day_pct")
  printf " | 7d (%b%s%%\033[0m)" "$(pct_color "$pct7")" "$pct7"
fi

if awk "BEGIN {exit !($cost_usd > 0)}"; then
  printf " | \$%.2f" "$cost_usd"
fi
