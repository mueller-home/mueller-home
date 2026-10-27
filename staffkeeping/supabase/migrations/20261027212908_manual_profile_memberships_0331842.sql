BEGIN;
UPDATE sk_internal.help_chapters SET
 title='Meine Mitgliedschaft und Preise',
 page_key='account',
 body=$manual$
# Wie verwalte ich meine Mitgliedschaft?

1. Öffne «Mein Profil».
2. Im Bereich «Meine Mitgliedschaft» siehst du deinen Mitgliedschaftsstatus und die angebotenen Tarife.
3. Bei Fragen zur Freigabe oder zur Abrechnung hilft dir die StaffKeeping-Administration.
4. Unter «Meine Betriebe» verwaltest du deine separat genehmigten Betriebe.

Eine Mitgliedschaft gehört zu deinem persönlichen Benutzerprofil und gilt für die ihm zugeordneten Betriebe. Jeder Betrieb wird einzeln freigegeben. Wenn für einen Betrieb eine eigenständige Mitgliedschaft verlangt wird, benötigst du dafür ein weiteres Benutzerprofil.

![Mitgliedschaft im Profil](screenshot:mitgliedschaft-profil-01)
$manual$,updated_at=now()
WHERE slug='sk-guide-membership';
COMMIT;
