#!/bin/bash
# StaffKeeping ZIP updater (macOS)
# Update-ZIP nach erfolgreicher Installation dauerhaft loeschen.
set -euo pipefail

DOWNLOADS='/Users/mueller-home/Downloads'
PROJECT_DIR='/Users/mueller-home/Documents/mueller-home/staffkeeping'
ZIP_LOCAL=''
TMP=''

finish() {
  result=$?
  trap - EXIT
  if [ -n "$TMP" ] && [ -d "$TMP" ]; then rm -rf -- "$TMP"; fi
  if [ "$result" -ne 0 ]; then
    printf '\nFEHLER: Update nicht abgeschlossen.\n'
    if [ -n "$ZIP_LOCAL" ] && [ -f "$ZIP_LOCAL" ]; then
      printf 'ZIP zur Kontrolle: %s\n' "$ZIP_LOCAL"
    fi
  fi
  printf '\nEnter druecken, um Apple Terminal zu beenden ... '
  IFS= read -r _key || true
  ( sleep 0.5; osascript -e 'tell application "Terminal" to quit' >/dev/null 2>&1 ) </dev/null >/dev/null 2>&1 &
}
trap finish EXIT

printf '\n==========================================\n StaffKeeping - ZIP-Update installieren\n==========================================\n\n'
printf 'Downloads: %s\nProjekt:   %s\n\n' "$DOWNLOADS" "$PROJECT_DIR"

if [ ! -d "$DOWNLOADS" ] || [ ! -d "$PROJECT_DIR" ]; then
  echo 'Downloads- oder Projektverzeichnis existiert nicht. Abbruch.'
  exit 1
fi

shopt -s nullglob
archives=("$DOWNLOADS"/staffkeeping-update-*.zip "$DOWNLOADS"/sk-update-*.zip)
shopt -u nullglob
if [ ${#archives[@]} -eq 0 ]; then
  echo 'Kein StaffKeeping-Update-ZIP gefunden.'
  exit 1
fi

ZIP_SOURCE="$(stat -f '%m %N' "${archives[@]}" | sort -nr | head -n 1 | cut -d' ' -f2-)"
ZIP_NAME="$(basename "$ZIP_SOURCE")"
printf 'Gefunden: %s\n' "$ZIP_NAME"

if ! unzip -tqq "$ZIP_SOURCE"; then
  echo 'ZIP ist beschaedigt. Abbruch.'
  exit 1
fi

# Wichtig: awk-Bedingung auf EINER Zeile (kompatibel mit macOS awk).
if ! unzip -Z -1 "$ZIP_SOURCE" | awk '
  BEGIN { ok=1 }
  {
    p=$0
    if (p=="" || p ~ /^\// || p ~ /\\/ || p ~ /(^|\/)\.\.?($|\/)/ || p ~ /^[A-Za-z]:/ || p ~ /[[:cntrl:]]/) {
      printf "Unsicherer Pfad im ZIP: %s\n", p > "/dev/stderr"
      ok=0
    }
  }
  END { exit !ok }
'; then
  echo 'Unsichere ZIP-Dateipfade. Abbruch.'
  exit 1
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp/}staffkeeping-update.XXXXXX")"
unzip -qq "$ZIP_SOURCE" -d "$TMP"
if [ -n "$(find "$TMP" -type l -print -quit)" ]; then
  echo 'Symbolische Links im ZIP sind nicht erlaubt. Abbruch.'
  exit 1
fi
if [ -z "$(find "$TMP" -type f -print -quit)" ]; then
  echo 'ZIP enthaelt keine Dateien. Abbruch.'
  exit 1
fi

SOURCE_DIR="$TMP"
first_dir=''
all_wrapped=1
while IFS= read -r relative; do
  relative="${relative#"$TMP"/}"
  case "$relative" in
    staffkeeping/*) current='staffkeeping' ;;
    StaffKeeping/*) current='StaffKeeping' ;;
    *) all_wrapped=0; break ;;
  esac
  if [ -z "$first_dir" ]; then first_dir="$current"; fi
  if [ "$first_dir" != "$current" ]; then all_wrapped=0; break; fi
done < <(find "$TMP" -type f)
if [ "$all_wrapped" -eq 1 ] && [ -n "$first_dir" ]; then
  SOURCE_DIR="$TMP/$first_dir"
fi
if [ "$SOURCE_DIR" = "$TMP" ]; then
  if [ -d "$TMP/staffkeeping" ] || [ -d "$TMP/StaffKeeping" ]; then
    echo 'ZIP enthaelt gemischte Projektverzeichnisse. Abbruch.'
    exit 1
  fi
fi

ZIP_LOCAL="$PROJECT_DIR/$ZIP_NAME"
if [ -e "$ZIP_LOCAL" ]; then
  echo 'ZIP existiert bereits im Projektordner. Abbruch.'
  ZIP_LOCAL=''
  exit 1
fi

NEW_COUNT=0
CHANGED_COUNT=0
UNCHANGED_COUNT=0
printf '\nDateiuebersicht dieses Updates:\n\n'
while IFS= read -r -d '' source_file; do
  relative="${source_file#"$SOURCE_DIR"/}"
  target_file="$PROJECT_DIR/$relative"
  if [ ! -e "$target_file" ]; then
    printf '  [NEU]          %s\n' "$relative"
    NEW_COUNT=$((NEW_COUNT + 1))
  elif [ -f "$target_file" ] && cmp -s "$source_file" "$target_file"; then
    printf '  [UNVERAENDERT] %s\n' "$relative"
    UNCHANGED_COUNT=$((UNCHANGED_COUNT + 1))
  else
    printf '  [GEAENDERT]    %s\n' "$relative"
    CHANGED_COUNT=$((CHANGED_COUNT + 1))
  fi
done < <(find "$SOURCE_DIR" -type f -print0)

printf '\nZusammenfassung: %d neu, %d geaendert, %d unveraendert.\n' \
  "$NEW_COUNT" "$CHANGED_COUNT" "$UNCHANGED_COUNT"

printf '\nZIP in Projektordner verschieben ...\n'
mv -- "$ZIP_SOURCE" "$ZIP_LOCAL"
printf 'Projektdateien aktualisieren ...\n'
ditto "$SOURCE_DIR" "$PROJECT_DIR"

printf 'Update-ZIP endgueltig loeschen ...\n'
rm -- "$ZIP_LOCAL"
ZIP_LOCAL=''
printf '\nFERTIG: StaffKeeping-Dateien aktualisiert.\n'
printf 'Installiert: %d neue und %d geaenderte Dateien (%d unveraendert).\n' \
  "$NEW_COUNT" "$CHANGED_COUNT" "$UNCHANGED_COUNT"
printf 'Update-ZIP wurde endgueltig geloescht.\n'
printf 'Kein automatischer Git-Commit / Push.\n'
