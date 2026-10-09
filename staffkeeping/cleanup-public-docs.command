#!/bin/bash
# StaffKeeping: öffentlich versionierte Alt-Dokumentation erst nach erfolgreichem Supabase-Import entfernen.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"
printf '\nDieses Werkzeug entfernt die alten öffentlichen StaffKeeping-docs aus Git.\n'
printf 'VORHER zwingend prüfen: Admin → Projektdoku enthält alle Kapitel, inklusive nach 0.27.1 ergänztem Abgleich.\n'
read -r -p 'Kapitel in Supabase geprüft und Original v2.2 privat gesichert? (JA): ' answer
if [[ "$answer" != 'JA' ]]; then echo 'Abgebrochen – keine Änderung.'; exit 1; fi
archive="$SCRIPT_DIR/_bubble/docs-archiv-027"
mkdir -p "$archive"
if [[ -d "$SCRIPT_DIR/docs" ]]; then
  cp -p "$SCRIPT_DIR"/docs/*.md "$archive"/ 2>/dev/null || true
  git rm -r -- staffkeeping/docs
else
  echo 'Kein staffkeeping/docs-Verzeichnis mehr vorhanden.'
fi
printf '\nFertig. Lokale Archivkopie in: %s\n' "$archive"
printf 'GitHub Desktop: Entfernen der Dateien prüfen, committen und pushen.\n'
printf 'Prüfen, ob zusätzliche öffentliche README/HTML-Kopien vertrauliche Texte enthalten.\n'
read -r -p 'Enter zum Schliessen ... ' _
