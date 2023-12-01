from django.core.management.base import BaseCommand, CommandError
from courtapi.models import PronomenErsetzungMaennlich, PronomenErsetzungWeiblich
from courtapi.dict_db import pronomen_ersetzungen_m, pronomen_ersetzungen_w

class Command(BaseCommand):
    help = "Stellt die Datenbank auf den Stand von der hardcoded aber gitignored dict_db.py"

    def handle(self, *args, **options):
        print(f"Beginne mit PronomenErsetzungMaennlich")
        for key, ersetzung_prioritaet_list in pronomen_ersetzungen_m.items():
            ersetzungswort = ersetzung_prioritaet_list[0]
            prioritaet = ersetzung_prioritaet_list[1]
            ersetzung = PronomenErsetzungMaennlich(wort=key, ersetzung=ersetzungswort, prioritaet=prioritaet)
            print(f"Speichere {key} -> {ersetzungswort} Ersetzung")
            ersetzung.save()
    
        print(f"Beginne mit PronomenErsetzungWeiblich")
        for key, ersetzung_prioritaet_list in pronomen_ersetzungen_w.items():
            ersetzungswort = ersetzung_prioritaet_list[0]
            prioritaet = ersetzung_prioritaet_list[1]
            ersetzung = PronomenErsetzungMaennlich(wort=key, ersetzung=ersetzungswort, prioritaet=prioritaet)
            print(f"Speichere {key} -> {ersetzungswort} Ersetzung")
            ersetzung.save()
    
        print(f"Programm updatedb erfolgreich beendet")
