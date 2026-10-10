#!/bin/bash
# StaffKeeping: neuestes Update-ZIP aus Downloads in lokalen Projektordner einspielen.
# Akzeptiert ZIPs mit relativen Projektpfaden, mit oder ohne obersten staffkeeping/-Ordner.
# Keine Git-Aktionen, keine Löschung bestehender Projektdateien.
set -euo pipefail

DOWNLOADS='/Users/mueller-home/Downloads'
PROJECT_DIR='/Users/mueller-home/Documents/mueller-home/staffkeeping'
ZIP_LOCAL=''
TMP=''
# Fenster-ID beim Start erfassen, damit nicht versehentlich ein anderes Fenster geschlossen wird.
TERMINAL_WINDOW_ID=''
if [ -n "${TERM_SESSION_ID:-}" ]; then
  TERMINAL_WINDOW_ID="$(osascript -e 'tell application "Terminal" to get id of front window' 2>/dev/null || true)"
fi

finish() {
  result=$?
  if [ -n "$TMP" ] && [ -d "$TMP" ]; then rm -rf "$TMP"; fi
  if [ "$result" -ne 0 ]; then
    printf '\nFEHLER: Update nicht abgeschlossen.\n'
    if [ -n "$ZIP_LOCAL" ] && [ -f "$ZIP_LOCAL" ]; then
      printf 'ZIP zur Kontrolle: %s\n' "$ZIP_LOCAL"
    fi
  fi
  printf '\nZum Schliessen Enter drücken ... '
  IFS= read -r _key || true
  # Nur das aktuelle Terminalfenster schliessen; andere Fenster offen lassen.
  # osascript startet im Hintergrund, damit die Shell zuerst enden kann.
  if [[ "$TERMINAL_WINDOW_ID" =~ ^[0-9]+$ ]]; then
    ( sleep 0.3; osascript -e "tell application \"Terminal\" to close (first window whose id is $TERMINAL_WINDOW_ID)" >/dev/null 2>&1 ) </dev/null >/dev/null 2>&1 &
  fi
}
trap finish EXIT

printf '\n==========================================\n StaffKeeping – ZIP-Update installieren\n==========================================\n\n'
printf 'Downloads: %s\nProjekt:   %s\n\n' "$DOWNLOADS" "$PROJECT_DIR"

if [ ! -d "$DOWNLOADS" ] || [ ! -d "$PROJECT_DIR" ]; then
  echo 'Downloads- oder Projektverzeichnis existiert nicht. Abbruch.'
  exit 1
fi

shopt -s nullglob
archives=("$DOWNLOADS"/staffkeeping-update-*.zip "$DOWNLOADS"/sk-update-*.zip)
shopt -u nullglob
if [ ${#archives[@]} -eq 0 ]; then
  echo 'Kein ZIP gefunden (staffkeeping-update-*.zip oder sk-update-*.zip).'
  exit 1
fi
# Neueste Datei nach Änderungszeit, ohne ls-Parsing.
ZIP_SOURCE="$(stat -f '%m %N' "${archives[@]}" | sort -nr | head -n 1 | cut -d' ' -f2-)"
ZIP_NAME="$(basename "$ZIP_SOURCE")"
printf 'Update: %s\n' "$ZIP_NAME"

if ! unzip -tqq "$ZIP_SOURCE"; then
  echo 'ZIP ist beschädigt. Abbruch.'
  exit 1
fi

# Nur relative, sichere Dateien; keine gemischte Struktur mit/ohne Projekt-Ordner.
TMP="$(mktemp -d "${TMPDIR:-/tmp/}staffkeeping-update.XXXXXX")"
unzip -qq "$ZIP_SOURCE" -d "$TMP"
if [ -n "$(find "$TMP" -type l -print -quit)" ]; then
  echo 'Symbolische Links im ZIP sind nicht erlaubt. Abbruch.'
  exit 1
fi
if [ -z "$(find "$TMP" -type f -print -quit)" ]; then
  echo 'ZIP enthält keine Dateien. Abbruch.'
  exit 1
fi
if ! unzip -Z -1 "$ZIP_SOURCE" | awk '
  BEGIN { ok=1 }
  {
    p=$0
    if (p=="" || p ~ /^\// || p ~ /\\/ || p ~ /(^|\/)\.\.?($|\/)/ || p ~ /^[A-Za-z]:/ || p ~ /[[:cntrl:]]/) {
      printf "Unsicherer Pfad im ZIP: %s\n", p > "/dev/stderr"; ok=0
    }
  }
  END { exit !ok }
'; then
  echo 'Unsichere ZIP-Dateipfade. Abbruch.'
  exit 1
fi

# Falls alle enthaltenen Dateien innerhalb staffkeeping/ oder StaffKeeping/ liegen,
# wird dieser gemeinsame äussere Projektordner entfernt.
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

# Schutz vor versehentlichem Paket mit Dateien aus anderen Projekten.
if [ "$SOURCE_DIR" = "$TMP" ]; then
  if [ -d "$TMP/staffkeeping" ] || [ -d "$TMP/StaffKeeping" ]; then
    echo 'ZIP enthält gemischte Projektverzeichnisse. Abbruch.'
    exit 1
  fi
fi

ZIP_LOCAL="$PROJECT_DIR/$ZIP_NAME"
if [ -e "$ZIP_LOCAL" ]; then
  echo 'ZIP existiert bereits im Projektordner. Abbruch ohne Überschreiben.'
  ZIP_LOCAL=''
  exit 1
fi
# Vor dem Installieren anhand des tatsächlichen Dateiinhalts vergleichen.
# Die Liste bleibt auch nach der Installation zur Prüfung sichtbar.
NEW_COUNT=0
CHANGED_COUNT=0
UNCHANGED_COUNT=0
printf '\nDateiübersicht dieses Updates:\n'
while IFS= read -r -d '' source_file; do
  relative="${source_file#"$SOURCE_DIR"/}"
  target_file="$PROJECT_DIR/$relative"
  if [ ! -e "$target_file" ]; then
    printf '  [NEU]       %s\n' "$relative"
    NEW_COUNT=$((NEW_COUNT + 1))
  elif [ -f "$target_file" ] && cmp -s "$source_file" "$target_file"; then
    printf '  [UNVERÄNDERT] %s\n' "$relative"
    UNCHANGED_COUNT=$((UNCHANGED_COUNT + 1))
  else
    printf '  [GEÄNDERT]  %s\n' "$relative"
    CHANGED_COUNT=$((CHANGED_COUNT + 1))
  fi
done < <(find "$SOURCE_DIR" -type f -print0)
printf '\nZusammenfassung: %d neu, %d geändert, %d unverändert.\n' \
  "$NEW_COUNT" "$CHANGED_COUNT" "$UNCHANGED_COUNT"

printf '\nZIP in Projektordner verschieben ...\n'
mv "$ZIP_SOURCE" "$ZIP_LOCAL"
printf 'Projektdateien aktualisieren ...\n'
# ditto überschreibt gleiche Dateien, löscht jedoch keine anderen Projektdateien.
ditto "$SOURCE_DIR" "$PROJECT_DIR"

TRASH="$HOME/.Trash"
mkdir -p "$TRASH"
TRASH_FILE="$TRASH/$ZIP_NAME"
if [ -e "$TRASH_FILE" ]; then
  TRASH_FILE="$TRASH/${ZIP_NAME%.zip}-$(date +%Y%m%d-%H%M%S)-$$.zip"
fi
mv "$ZIP_LOCAL" "$TRASH_FILE"
ZIP_LOCAL=''
printf '\nFERTIG: StaffKeeping-Dateien aktualisiert.\n'
printf 'Installiert: %d neue und %d geänderte Dateien (%d unverändert).\n' \
  "$NEW_COUNT" "$CHANGED_COUNT" "$UNCHANGED_COUNT"
printf 'ZIP im Papierkorb: %s\n' "$(basename "$TRASH_FILE")"
printf 'Kein automatischer Git-Commit / Push.\n'
