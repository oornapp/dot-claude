#!/usr/bin/env bash
# Claude Code status line — usage bar style
# Receives JSON on stdin from Claude Code

input=$(cat)
ESC=$'\033'

# --- Parse JSON ---
model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // "0"')
total_tokens=$(echo "$input" | jq -r '.context_window.context_window_size // "0"')
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# --- Build progress bar ---
bar_width=20
used_int=$(printf "%.0f" "$used_pct")
filled=$(( used_int * bar_width / 100 ))
empty=$(( bar_width - filled ))

# Color based on usage
if [ "$used_int" -lt 50 ]; then
  bar_color="${ESC}[32m"  # green
elif [ "$used_int" -lt 80 ]; then
  bar_color="${ESC}[33m"  # yellow
else
  bar_color="${ESC}[31m"  # red
fi

# Build bar string
bar_filled=""
bar_empty=""
for ((i=0; i<filled; i++)); do bar_filled+="█"; done
for ((i=0; i<empty; i++)); do bar_empty+=" "; done

# Format token counts (used/total)
format_tokens() {
  local t=$1
  if [ "$t" -ge 1000 ] 2>/dev/null; then
    echo "$(( t / 1000 ))k"
  else
    echo "$t"
  fi
}

used_tokens=$(( total_tokens * used_int / 100 ))
used_display=$(format_tokens "$used_tokens")
total_display=$(format_tokens "$total_tokens")

# --- Rate limits ---
rate_info=""
if [ -n "$five_pct" ]; then
  five_int=$(printf "%.0f" "$five_pct")
  # Countdown to 5h reset
  countdown=""
  if [ -n "$five_reset" ]; then
    now=$(date +%s)
    secs_left=$(( five_reset - now ))
    if [ "$secs_left" -gt 0 ]; then
      hrs=$(( secs_left / 3600 ))
      mins=$(( (secs_left % 3600) / 60 ))
      countdown=" (${hrs}h${mins}m)"
    else
      countdown=" (now)"
    fi
  fi
  rate_info="${ESC}[36m5h:${five_int}%${countdown}${ESC}[0m"
fi
if [ -n "$week_pct" ]; then
  week_int=$(printf "%.0f" "$week_pct")
  [ -n "$rate_info" ] && rate_info="$rate_info "
  rate_info="${rate_info}${ESC}[36m7d:${week_int}%${ESC}[0m"
fi
if [ -n "$rate_info" ]; then
  rate_info=" ${ESC}[90m|${ESC}[0m ${rate_info}"
fi

# --- Output ---
printf "%s ${ESC}[90m|${ESC}[0m [%s%s%s${ESC}[0m] %s%% ${ESC}[90m|${ESC}[0m %s/%s%s\n" \
  "$model" \
  "$bar_color" \
  "$bar_filled" \
  "$bar_empty" \
  "$used_int" \
  "$used_display" \
  "$total_display" \
  "$rate_info"
