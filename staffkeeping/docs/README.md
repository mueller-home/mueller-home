# StaffKeeping – zentrale Projektdokumentation

Stand: 09.10.2026 · Version 0.18 · **Designprototyp, nicht produktiv**.

Diese Dateien sind **bewusst öffentlichkeitsfähige Projektzusammenfassungen**. Werden sie im GitHub-Pages-Verzeichnis gespeichert, sind sie öffentlich abrufbar. Keine Passwörter, internen Schlüssel, Kundendaten oder nicht freigegebenen Originaldokumente hier ablegen.

## Dokumentationshierarchie

1. `staffkeeping/_bubble/staffkeeping_migrationskonzept.html`: **Vollständige Originalquelle** v2.2 (14.09.2026), lokal/gitignored, nicht online abrufbar.
2. `docs/`: Aktueller, nicht vertraulicher Projektstand / aktualisierte Entscheidungen und Regeln (öffentlich sichtbare Version).
3. `scripts/app.js`: Gleichlautende Projektübersicht für den Demo-Adminbereich. **Bis zu einem geschützten Dokumentenbackend besteht hier Duplikation; bei Releases beides nachführen.**

## Inhaltsübersicht
- `systemkonzept.md`: Ziel, Architektur, Migration, Verweis auf Original
- `entwicklungsstand.md`: Ist-Stand und nächste Phase
- `aufgaben-und-fragen.md`: Priorisierte TODO und offene Punkte
- `entwicklungsregeln.md`: Verbindliche ZIP-, Sicherheits-, CSS- und Release-Regeln
- `entscheidungen.md`: Beschlossene Vorgaben und Abgrenzungen
- `testplan.md`: Abnahmeplan und offene Tests
- `versionshistorie.md`: Bisherige Versionen
- `chat-uebergabe.md`: Einstieg in neuen Chat

**Geplant:** Supabase Auth + Admin-RLS + geschützte Speicherung/Auslieferung auch der vollständigen Konzeptdatei. Bis dahin sind die Online-Ansichten keine sichere Zugriffsbeschränkung.
