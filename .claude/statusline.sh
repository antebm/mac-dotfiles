#!/usr/bin/env bash
# Claude Code status line — Ayu Dark palette.
#
# Reads the session JSON on stdin and prints a single line to stdout:
#   MODEL │ PATH │ GIT DIRTY │ ADD DEL │ COST │ CTX │ LIMITS │ WARN
#
# Requires: jq, git. Truecolor terminal recommended.

input=$(cat)

#-------------------------------------------------------------------------------
# Palette — Ayu Dark (https://github.com/ayu-theme/ayu-colors)
#-------------------------------------------------------------------------------

C_MODEL=$'\033[1;38;2;230;180;80m'    # accent  #E6B450, bold
C_PATH=$'\033[38;2;89;194;255m'       # entity  #59C2FF
C_GIT=$'\033[38;2;170;217;76m'        # string  #AAD94C
C_DIRTY=$'\033[38;2;255;180;84m'      # func    #FFB454
C_ADD=$'\033[38;2;127;217;98m'        # vcs.added    #7FD962
C_DEL=$'\033[38;2;242;109;120m'       # vcs.removed  #F26D78
C_COST=$'\033[38;2;149;230;203m'      # regexp  #95E6CB
C_SEP=$'\033[38;2;98;106;115m'        # comment #626A73
C_DIM=$'\033[38;2;98;106;115m'        # comment #626A73
C_OK=$'\033[38;2;210;166;255m'        # constant #D2A6FF
C_WARN=$'\033[38;2;255;143;64m'       # keyword #FF8F40
C_CRIT=$'\033[1;38;2;217;87;87m'      # error   #D95757, bold
R=$'\033[0m'

SEP="${C_SEP}│${R}"

#-------------------------------------------------------------------------------
# Parse stdin. @sh quotes every value, so eval is safe against odd branch names.
# Percentages use "" rather than 0 when absent: the docs note context_window and
# rate_limits fields are null early in a session, and rate_limits only appears
# for Claude.ai subscribers. Empty means "hide the segment", not "zero".
#-------------------------------------------------------------------------------

MODEL="?" CWD="" SESSION="nosession"
ADDED=0 REMOVED=0 COST=0
PCT="" CTXSIZE=0 OVER="false"
L5="" L5R="" L7="" L7R=""

if parsed=$(printf '%s' "$input" | jq -r '
      "MODEL="   + ((.model.display_name // "?")                       | @sh),
      "CWD="     + ((.workspace.current_dir // .cwd // "")             | @sh),
      "SESSION=" + ((.session_id // "nosession")                       | @sh),
      "ADDED="   + ((.cost.total_lines_added   // 0)        | tostring | @sh),
      "REMOVED=" + ((.cost.total_lines_removed // 0)        | tostring | @sh),
      "COST="    + ((.cost.total_cost_usd      // 0)        | tostring | @sh),
      "PCT="     + ((.context_window.used_percentage   // "") | tostring | @sh),
      "CTXSIZE=" + ((.context_window.context_window_size // 0) | tostring | @sh),
      "OVER="    + ((.exceeds_200k_tokens // false)         | tostring | @sh),
      "L5="      + ((.rate_limits.five_hour.used_percentage // "") | tostring | @sh),
      "L5R="     + ((.rate_limits.five_hour.resets_at       // "") | tostring | @sh),
      "L7="      + ((.rate_limits.seven_day.used_percentage // "") | tostring | @sh),
      "L7R="     + ((.rate_limits.seven_day.resets_at       // "") | tostring | @sh)
    ' 2>/dev/null); then
  eval "$parsed"
fi

[ -n "$CWD" ] && [ -d "$CWD" ] && cd "$CWD" 2>/dev/null

#-------------------------------------------------------------------------------
# Helpers
#-------------------------------------------------------------------------------

# Truncate "23.5" -> 23. Empty stays empty.
as_int() {
  local v="${1%%.*}"
  case "$v" in (''|*[!0-9-]*) printf '' ;; (*) printf '%s' "$v" ;; esac
}

# Escalating colour: dim under 50, accent to 75, orange to 90, red above.
pct_color() {
  local p="$1"
  if   [ "$p" -ge 90 ] 2>/dev/null; then printf '%s' "$C_CRIT"
  elif [ "$p" -ge 75 ] 2>/dev/null; then printf '%s' "$C_WARN"
  elif [ "$p" -ge 50 ] 2>/dev/null; then printf '%s' "$C_OK"
  else                                   printf '%s' "$C_DIM"
  fi
}

# Epoch seconds -> compact countdown ("2h14m", "45m", "now").
eta() {
  local target="$1" now delta h m
  case "$target" in (''|*[!0-9]*) printf '' ; return ;; esac
  now=$(date +%s)
  delta=$(( target - now ))
  [ "$delta" -le 0 ] && { printf 'now'; return; }
  h=$(( delta / 3600 )); m=$(( (delta % 3600) / 60 ))
  if [ "$h" -gt 0 ]; then printf '%dh%02dm' "$h" "$m"; else printf '%dm' "$m"; fi
}

#-------------------------------------------------------------------------------
# PATH — home-relative, trimmed to the last two components when deep.
#-------------------------------------------------------------------------------

short_path() {
  local p="${1:-$PWD}"
  case "$p" in
    "$HOME") printf '~' ; return ;;
    "$HOME"/*) p="~/${p#"$HOME"/}" ;;
  esac
  local depth="${p//[!\/]/}"
  if [ "${#depth}" -gt 3 ]; then
    local parent="${p%/*}"
    printf '%s/…/%s/%s' "${p%%/*}" "${parent##*/}" "${p##*/}"
  else
    printf '%s' "$p"
  fi
}

DIR_DISPLAY=$(short_path "$PWD")

#-------------------------------------------------------------------------------
# GIT + DIRTY — cached for 5s; `git status` on every render is what lags.
#-------------------------------------------------------------------------------

CACHE="${TMPDIR:-/tmp}/claude-statusline-${SESSION//[^A-Za-z0-9_-]/_}"
CACHE_TTL=5

file_mtime() {
  stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0
}

BRANCH="" DIRTY_COUNT=0

if [ -f "$CACHE" ] && [ $(( $(date +%s) - $(file_mtime "$CACHE") )) -lt "$CACHE_TTL" ]; then
  IFS=$'\t' read -r BRANCH DIRTY_COUNT < "$CACHE"
else
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    BRANCH=$(git symbolic-ref --quiet --short HEAD 2>/dev/null \
             || git rev-parse --short HEAD 2>/dev/null)
    DIRTY_COUNT=$(git status --porcelain 2>/dev/null | grep -c .)
  fi
  printf '%s\t%s\n' "$BRANCH" "$DIRTY_COUNT" > "$CACHE" 2>/dev/null
fi

DIRTY_COUNT=${DIRTY_COUNT:-0}

#-------------------------------------------------------------------------------
# Assemble
#-------------------------------------------------------------------------------

segments=()

segments+=("${C_MODEL}${MODEL}${R}")
segments+=("${C_PATH}${DIR_DISPLAY}${R}")

if [ -n "$BRANCH" ]; then
  git_seg="${C_GIT}⎇ ${BRANCH}${R}"
  if [ "$DIRTY_COUNT" -gt 0 ] 2>/dev/null; then
    git_seg+=" ${C_DIRTY}●${DIRTY_COUNT}${R}"     # DIRTY
  else
    git_seg+=" ${C_GIT}✓${R}"
  fi
  segments+=("$git_seg")
fi

# ADD / DEL — session line churn, hidden until something changes.
if [ "${ADDED:-0}" -gt 0 ] 2>/dev/null || [ "${REMOVED:-0}" -gt 0 ] 2>/dev/null; then
  segments+=("${C_ADD}+${ADDED}${R} ${C_DEL}-${REMOVED}${R}")
fi

# COST
COST_FMT=$(awk -v c="${COST:-0}" 'BEGIN {
  if (c <= 0)        printf "$0.00";
  else if (c < 0.01) printf "<$0.01";
  else               printf "$%.2f", c;
}')
segments+=("${C_COST}${COST_FMT}${R}")

# CTX — context window used. Absent until the first API response.
PCT_INT=$(as_int "$PCT")
if [ -n "$PCT_INT" ]; then
  ctx_label="ctx ${PCT_INT}%"
  # Note which window we are filling when it is not the default 200k.
  [ "${CTXSIZE:-0}" -ge 1000000 ] 2>/dev/null && ctx_label="ctx ${PCT_INT}%/1M"
  segments+=("$(pct_color "$PCT_INT")${ctx_label}${R}")
fi

# LIMITS — Claude.ai subscribers only; each window independently optional.
L5_INT=$(as_int "$L5")
L7_INT=$(as_int "$L7")
limit_parts=()
[ -n "$L5_INT" ] && limit_parts+=("$(pct_color "$L5_INT")5h ${L5_INT}%${R}")
[ -n "$L7_INT" ] && limit_parts+=("$(pct_color "$L7_INT")7d ${L7_INT}%${R}")
if [ "${#limit_parts[@]}" -gt 0 ]; then
  lim="${limit_parts[0]}"
  [ "${#limit_parts[@]}" -gt 1 ] && lim+="${C_DIM} · ${R}${limit_parts[1]}"
  segments+=("$lim")
fi

# WARN — single most urgent condition, with a reset countdown for rate limits.
warn=""
if [ "$OVER" = "true" ]; then
  warn="${C_CRIT}⚠ 200k+${R}"
elif [ -n "$L5_INT" ] && [ "$L5_INT" -ge 90 ] 2>/dev/null; then
  warn="${C_CRIT}⚠ 5h limit${R}${C_DIM} ↻$(eta "$L5R")${R}"
elif [ -n "$L7_INT" ] && [ "$L7_INT" -ge 90 ] 2>/dev/null; then
  warn="${C_CRIT}⚠ 7d limit${R}${C_DIM} ↻$(eta "$L7R")${R}"
elif [ -n "$PCT_INT" ] && [ "$PCT_INT" -ge 90 ] 2>/dev/null; then
  warn="${C_CRIT}⚠ context${R}"
elif [ -n "$PCT_INT" ] && [ "$PCT_INT" -ge 75 ] 2>/dev/null; then
  warn="${C_WARN}⚠ context${R}"
fi
[ -n "$warn" ] && segments+=("$warn")

out=""
for s in "${segments[@]}"; do
  [ -n "$out" ] && out+=" ${SEP} "
  out+="$s"
done

printf '%s\n' "$out"
