#!/usr/bin/env bash
# Claude Code status line — usage bar style
# Receives JSON on stdin from Claude Code

input=$(cat)
ESC=$'\033'

# --- Parse JSON ---
model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
model_id=$(echo "$input" | jq -r '.model.id // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // "0"')
total_tokens=$(echo "$input" | jq -r '.context_window.context_window_size // "0"')
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# --- Mode detection ---
# Subscription plans populate rate_limits; API key usage does not
if [ -n "$five_pct" ] || [ -n "$week_pct" ]; then
  mode="subscription"
else
  mode="api"
fi

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

# --- Right-side info: rate limits (subscription) or cost estimate (API) ---
right_info=""

if [ "$mode" = "subscription" ]; then
  # Rate limits — subscription mode
  if [ -n "$five_pct" ]; then
    five_int=$(printf "%.0f" "$five_pct")
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
    right_info="${ESC}[36m5h:${five_int}%${countdown}${ESC}[0m"
  fi
  if [ -n "$week_pct" ]; then
    week_int=$(printf "%.0f" "$week_pct")
    [ -n "$right_info" ] && right_info="$right_info "
    right_info="${right_info}${ESC}[36m7d:${week_int}%${ESC}[0m"
  fi
elif [[ "$model_id" == claude-* ]]; then
  # Cost estimate — Anthropic API mode only
  # Pricing per million tokens (input/output). Approximate 70/30 split.
  input_price_per_mtok=3.0
  output_price_per_mtok=15.0

  case "$model_id" in
    claude-opus-4*)
      input_price_per_mtok=15.0
      output_price_per_mtok=75.0
      ;;
    claude-sonnet-4*|claude-sonnet-3-7*)
      input_price_per_mtok=3.0
      output_price_per_mtok=15.0
      ;;
    claude-haiku-4*|claude-haiku-3*)
      input_price_per_mtok=0.8
      output_price_per_mtok=4.0
      ;;
  esac

  # Estimate cost using 70/30 input/output split of used tokens
  cost=$(awk -v tokens="$used_tokens" \
             -v in_price="$input_price_per_mtok" \
             -v out_price="$output_price_per_mtok" \
    'BEGIN {
      input_tok  = tokens * 0.70
      output_tok = tokens * 0.30
      cost = (input_tok * in_price + output_tok * out_price) / 1000000
      printf "~$%.4f", cost
    }')

  right_info="${ESC}[36m${cost}${ESC}[0m"
# else: non-Anthropic API — tokens already shown in the bar, skip right_info
fi

if [ -n "$right_info" ]; then
  right_info=" ${ESC}[90m|${ESC}[0m ${right_info}"
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
  "$right_info"
