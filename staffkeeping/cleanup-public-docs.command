#!/bin/bash
# StaffKeeping 0.28 – öffentlicher Markdown-Altbestand, mit Backup und Freigabe.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
cd "$REPO"
if ! git rev-parse --show-toplevel >/dev/null 2>&1; then echo 'Kein Git-Repository gefunden; Abbruch.'; exit 1; fi
if [[ ! -d "$HERE/docs" ]]; then echo 'Keine alten docs vorhanden.'; exit 0; fi
if ! git ls-files --error-unmatch staffkeeping/docs/*.md >/dev/null 2>&1; then
  echo 'Keine entsprechenden in Git erfassten Markdown-Dateien vorhanden.'; exit 0
fi
printf '\nVORHER PRÜFEN: Admin → Projektdoku enthält die Kapitel nach SQL 0.28.\n'
printf 'Original v2.2 ist im privaten Bucket abrufbar und separat gesichert.\n'
printf 'Dateien, die aus der aktuellen Git-Version verschwinden sollen:\n'
git ls-files -- 'staffkeeping/docs/*.md'
printf '\nWICHTIG: Git-Historie und bereits veröffentlichte Kopien werden dadurch NICHT bereinigt.\n'
read -r -p 'Hast du die Kapitel und die private Originalquelle überprüft? Exakt ENTFERNEN eingeben: ' answer
[[ "$answer" == 'ENTFERNEN' ]] || { echo 'Abgebrochen.'; exit 0; }
archive="$HERE/_bubble/docs-archiv-028-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$archive"
cp -p "$HERE"/docs/*.md "$archive"/
git rm -- 'staffkeeping/docs/*.md'
printf '\nLokale Sicherung: %s\n' "$archive"
printf 'Jetzt in GitHub Desktop den Commit und Push durchführen.\n'
printf 'Danach über eine nicht angemeldete Browser-Sitzung die alten GitHub-Pages-URLs prüfen.\n'
read -r -p 'Enter zum Schliessen ... ' _
