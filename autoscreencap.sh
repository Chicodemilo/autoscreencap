#!/bin/zsh
#
# autoscreencap — Auto-copy macOS screenshots to clipboard with terminal links
# ==============================================================================
#
# Watches a directory for new screenshots. When one lands:
#   1. Copies the image to the system clipboard
#   2. Plays a confirmation sound
#   3. Prints clickable terminal links (Open file / Show in Finder)
#
# Designed to run in iTerm2 (or any terminal supporting OSC 8 hyperlinks).
#
# ==============================================================================

# ── Configuration ──────────────────────────────────────────────────────────────
# Override these with environment variables before running, e.g.:
#   SCREENCAP_DIR=~/Screenshots SCREENCAP_SOUND=Submarine ./autoscreencap.sh

WATCH_DIR="${SCREENCAP_DIR:-$HOME/Desktop/ScreenCap}"
LOGFILE="${SCREENCAP_LOG:-$HOME/autoscreencap.log}"
SOUND_NAME="${SCREENCAP_SOUND:-Glass}"
DEBOUNCE_SEC="${SCREENCAP_DEBOUNCE:-2}"

# ── Detect tool paths ─────────────────────────────────────────────────────────
# fswatch — try Homebrew ARM first, then Intel
if [[ -x /opt/homebrew/bin/fswatch ]]; then
  FSWATCH=/opt/homebrew/bin/fswatch
elif [[ -x /usr/local/bin/fswatch ]]; then
  FSWATCH=/usr/local/bin/fswatch
else
  echo "ERROR: fswatch not found. Install it with: brew install fswatch" >&2
  exit 1
fi

# python3 — used for URL-encoding paths (optional, has fallback)
PYTHON3=""
for p in /opt/homebrew/bin/python3 /usr/local/bin/python3; do
  [[ -x "$p" ]] && PYTHON3="$p" && break
done

# macOS system binaries (fixed paths)
FIND=/usr/bin/find
STAT=/usr/bin/stat
OSASCRIPT=/usr/bin/osascript
AFPLAY=/usr/bin/afplay

# ── Preflight checks ──────────────────────────────────────────────────────────
if [[ ! -d "$WATCH_DIR" ]]; then
  echo "Creating watch directory: $WATCH_DIR"
  mkdir -p "$WATCH_DIR"
fi

# ── Colors ─────────────────────────────────────────────────────────────────────
GREEN=$'\033[0;32m'
BOLD_CYAN=$'\033[1;36m'
ORANGE=$'\033[38;5;208m'
NC=$'\033[0m'

printf "%b\n" "${GREEN}Watching $WATCH_DIR for new screenshots...${NC}"
printf "%b\n" "${ORANGE}Cmd+click links to open${NC}"

LAST_FILE=""
LAST_MOD=0

# ── Main loop ──────────────────────────────────────────────────────────────────
$FSWATCH -0 "$WATCH_DIR" | while read -d "" event; do

  # Find the most recently modified PNG
  latest_file=$(
    $FIND "$WATCH_DIR" -type f -iname "*.png" -exec $STAT -f "%m %N" {} \; \
    | sort -nr | head -n1 | cut -d' ' -f2-
  )

  [[ -z "$latest_file" ]] && continue

  mod_time=$($STAT -f "%m" "$latest_file")

  # Debounce duplicate events
  if [[ "$latest_file" == "$LAST_FILE" ]] && (( mod_time - LAST_MOD < DEBOUNCE_SEC )); then
    continue
  fi

  LAST_FILE="$latest_file"
  LAST_MOD="$mod_time"

  # Copy image to clipboard
  $OSASCRIPT -e "set the clipboard to (read (POSIX file \"$latest_file\") as «class PNGf»)" \
    >> "$LOGFILE" 2>&1

  # Play confirmation sound
  $AFPLAY "/System/Library/Sounds/${SOUND_NAME}.aiff" &

  timestamp=$(date "+%m/%d %I:%M%p")
  base_name=$(basename -- "$latest_file")
  latest_dir=$(dirname -- "$latest_file")
  dir_name=$(basename -- "$latest_dir")

  # URL-encode paths for file:// links
  if [[ -x "$PYTHON3" ]]; then
    enc_file_path=$($PYTHON3 -c 'import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1], safe="/"))' "$latest_file" 2>/dev/null)
    enc_dir_path=$($PYTHON3 -c 'import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1], safe="/"))' "$latest_dir" 2>/dev/null)
  fi
  # Fallback: simple space encoding
  [[ -z "$enc_file_path" ]] && enc_file_path="${latest_file// /%20}"
  [[ -z "$enc_dir_path" ]] && enc_dir_path="${latest_dir// /%20}"

  file_url="file://$enc_file_path"
  dir_url="file://$enc_dir_path/"

  # Print status + clickable OSC 8 hyperlinks
  echo -e "${GREEN}[$timestamp] Copied to clipboard:${NC}" | tee -a "$LOGFILE"
  printf "\033]8;;%s\a%b%s%b\033]8;;\a\n" "$file_url" "$BOLD_CYAN" "  Open file: $base_name" "$NC" | tee -a "$LOGFILE"
  printf "\033]8;;%s\a%b%s%b\033]8;;\a\n" "$dir_url" "$BOLD_CYAN" "  Show in Finder: $dir_name" "$NC" | tee -a "$LOGFILE"

  echo "Processed $latest_file" >> "$LOGFILE"

done
