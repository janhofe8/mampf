#!/bin/bash
#
# Optimize MAMPF restaurant photos: HEIC/PNG/JPG → JPEG 1080px q80 + upload to
# Supabase Storage. Default is dry-run; pass --apply to actually upload.
#
# Usage:
#   ./scripts/optimize-photos.sh              # dry-run
#   ./scripts/optimize-photos.sh --apply      # apply (skip already-optimized)
#   ./scripts/optimize-photos.sh --apply --force   # re-upload everything
#
set -euo pipefail

PHOTO_DIR="${HOME}/Food Bilder"
SUPABASE_URL="https://nuriruulwjjpycdszdrn.supabase.co"
SIZE_THRESHOLD=600000
MAX_DIM=1080
JPEG_QUALITY=80

# Manual overrides for filenames the auto-matcher can't resolve unambiguously.
# Format: "FILE_BASENAME|DB_RESTAURANT_NAME"
MANUAL_MAPPING=(
  "Atlantik BistrOcean|Atlantik Fisch & BistrOceaN"
  "Hofbräu Esplanade|Hofbräu Hamburg"
  "Nord Coast Hoheluft|Nord Coast Coffee"
  "NY Bagel bar Sternschanze|New York Bagel Bar"
  "NY Bagel Bar Gänsemarkt|New York Bagel Bar Gänsemarkt"
  "Rice Brothers Schanze|Ricebrothers"
  "Siggys Gemüse Kebab|Siggys Gemüse Kebap"
)

manual_mapping_for() {
  local b="$1" entry key
  for entry in "${MANUAL_MAPPING[@]}"; do
    key="${entry%%|*}"
    if [[ "$key" == "$b" ]]; then printf '%s' "${entry#*|}"; return; fi
  done
}

APPLY=false
FORCE=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=true; shift ;;
    --force) FORCE=true; shift ;;
    -h|--help)
      sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

# shellcheck disable=SC1090
source ~/.zshenv
: "${SUPABASE_SECRET_KEY:?SUPABASE_SECRET_KEY not set in ~/.zshenv}"

command -v jq >/dev/null   || { echo "jq required" >&2; exit 1; }
command -v sips >/dev/null || { echo "sips required (macOS)" >&2; exit 1; }
[[ -d "$PHOTO_DIR" ]] || { echo "Photo dir not found: $PHOTO_DIR" >&2; exit 1; }

# Write the jq normalization+match filter to a temp file so we don't have to fight
# bash quoting around backticks/apostrophes inside the regex character class.
JQ_FILTER=$(mktemp -t mampf-match-XXXXXX.jq)
trap 'rm -f "$JQ_FILTER"' EXIT
cat >"$JQ_FILTER" <<'JQ'
def norm(s): s
  | gsub("ä"; "ae") | gsub("Ä"; "ae")
  | gsub("ö"; "oe") | gsub("Ö"; "oe")
  | gsub("ü"; "ue") | gsub("Ü"; "ue")
  | gsub("ß"; "ss")
  | gsub("[éèêë]"; "e") | gsub("[ÉÈÊË]"; "e")
  | gsub("[áàâã]"; "a") | gsub("[ÁÀÂÃ]"; "a")
  | gsub("[íìîï]"; "i") | gsub("[ÍÌÎÏ]"; "i")
  | gsub("[óòôõ]"; "o") | gsub("[ÓÒÔÕ]"; "o")
  | gsub("[úùû]"; "u")  | gsub("[ÚÙÛ]"; "u")
  | gsub("ñ"; "n")      | gsub("ç"; "c")
  | gsub("[Ææ]"; "ae")  | gsub("[Œœ]"; "oe") | gsub("[Øø]"; "o")
  | ascii_downcase
  | gsub("[’‘'`\\[\\]()]"; "")
  | gsub("[!?,.&\\-]"; " ")
  | gsub("\\s+"; " ")
  | sub("^\\s+"; "") | sub("\\s+$"; "");

# Tier 1: exact normalized match.
# Tier 2: file-name (normalized) is a substring of exactly one DB name (e.g. "Lookma" → "Lookma Berlin Hamburg…").
# Tier 3: a single DB name (normalized) is a substring of the file name (e.g. "NY Bagel bar Sternschanze" → "NY Bagel Bar Sternschanze").
# Only emit a match when the candidate set has exactly one element — anything else is genuinely ambiguous and stays unmatched.
. as $rows
| (norm($n)) as $fn
| (
    [ $rows[] | select(norm(.name) == $fn) ]
  | if length == 1 then . else
      [ $rows[] | select(norm(.name) | contains($fn)) ]
      | if length == 1 then . else
          [ $rows[] | (norm(.name)) as $rn | select($rn != "" and ($fn | contains($rn))) ]
          | if length == 1 then . else [] end
        end
    end
  )
| if length == 1 then .[0] | "\(.id)\t\(.name)\t\(.image_url // "")" else "" end
JQ

mode_label="DRY-RUN"
$APPLY && mode_label="APPLY"
echo "Mode: $mode_label   |   Threshold: ${SIZE_THRESHOLD}B   |   Force: $FORCE"
echo ""

echo "Fetching restaurants from Supabase…"
RESTAURANTS=$(curl -sf "${SUPABASE_URL}/rest/v1/restaurants?select=id,name,image_url" \
  -H "apikey: ${SUPABASE_SECRET_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SECRET_KEY}")
echo "Loaded $(jq 'length' <<<"$RESTAURANTS") restaurants."
echo ""

processed=0
skipped_already=0
no_match=0
non_own=0
upload_errors=0
unmatched_files=()

shopt -s nullglob nocaseglob
for file in "$PHOTO_DIR"/*.HEIC "$PHOTO_DIR"/*.JPG "$PHOTO_DIR"/*.JPEG "$PHOTO_DIR"/*.PNG; do
  [[ -f "$file" ]] || continue

  fname="${file##*/}"
  base="${fname%.*}"
  # macOS stores filenames in NFD (decomposed Unicode). DB stores NFC. Normalize before matching.
  base=$(printf '%s' "$base" | iconv -f UTF-8-MAC -t UTF-8)

  # Manual override wins; otherwise auto-match.
  lookup_name="$(manual_mapping_for "$base")"
  [[ -z "$lookup_name" ]] && lookup_name="$base"
  match=$(jq -r --arg n "$lookup_name" -f "$JQ_FILTER" <<<"$RESTAURANTS")

  if [[ -z "$match" ]]; then
    unmatched_files+=("$base")
    no_match=$((no_match + 1))
    continue
  fi

  IFS=$'\t' read -r rid rname rurl <<<"$match"

  if [[ "$rurl" != *"/restaurant-images/own/"* ]]; then
    echo "  ⚠  $rname → image_url not in own/, skipping"
    non_own=$((non_own + 1))
    continue
  fi

  path_enc="${rurl##*/restaurant-images/}"
  decoded_path=$(printf '%b' "${path_enc//%/\\x}")

  if ! $FORCE; then
    remote_size=$(curl -sI "$rurl" | awk 'tolower($1)=="content-length:"{print $2}' | tr -d '\r')
    if [[ -n "$remote_size" && "$remote_size" =~ ^[0-9]+$ && "$remote_size" -lt "$SIZE_THRESHOLD" ]]; then
      skipped_already=$((skipped_already + 1))
      continue
    fi
  fi

  if ! $APPLY; then
    echo "  • $rname  ←  $fname  (would upload to $decoded_path)"
    processed=$((processed + 1))
    continue
  fi

  tmpfile=$(mktemp -t mampf-photo-XXXXXX).jpg
  if ! sips -s format jpeg -s formatOptions "$JPEG_QUALITY" -Z "$MAX_DIM" "$file" --out "$tmpfile" >/dev/null 2>&1; then
    echo "  ✗  $rname → sips conversion failed"
    rm -f "$tmpfile"
    upload_errors=$((upload_errors + 1))
    continue
  fi

  new_size=$(stat -f%z "$tmpfile")
  resp=$(curl -s -X POST "${SUPABASE_URL}/storage/v1/object/restaurant-images/${decoded_path}" \
    -H "apikey: ${SUPABASE_SECRET_KEY}" \
    -H "Content-Type: image/jpeg" \
    -H "x-upsert: true" \
    --data-binary "@${tmpfile}")
  rm -f "$tmpfile"

  if grep -q '"Key"' <<<"$resp"; then
    printf "  ✓  %-45s  %7d B\n" "$rname" "$new_size"
    processed=$((processed + 1))
  else
    echo "  ✗  $rname → upload failed: $resp"
    upload_errors=$((upload_errors + 1))
  fi
done

echo ""
echo "─── Summary ──────────────────────────────────────────"
printf "  %-30s %5d\n" "Processed:"             "$processed"
printf "  %-30s %5d\n" "Skipped (optimized):"   "$skipped_already"
printf "  %-30s %5d\n" "Skipped (no DB match):" "$no_match"
printf "  %-30s %5d\n" "Skipped (non-own URL):" "$non_own"
$APPLY && printf "  %-30s %5d\n" "Upload errors:" "$upload_errors"

if (( ${#unmatched_files[@]} > 0 )); then
  echo ""
  echo "Files without DB match (rename file or fix DB row):"
  for u in "${unmatched_files[@]}"; do
    echo "  - $u"
  done
fi

if ! $APPLY && (( processed > 0 )); then
  echo ""
  echo "Run with --apply to upload."
fi
