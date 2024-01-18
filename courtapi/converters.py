from .dict_db import (
    pronomen_ersetzungen_m,
    pronomen_ersetzungen_w,
    ocr_ersetzungen,
    verben_ersetzung_praesens,
    verben_ersetzung_praeteritum,
    verben_zusammenfuegung
)
import re


def ersetze_wort(textstelle, ausgangswort, ersetzung, ocr_ersetzung=False, hervorhebung=False):
    """
        Ersetzt das Ausgangswort in einem Textstelle-String durch die angegebene Ersetzung.

        Args:
            textstelle (str): Der Textstelle-String, in dem das Ausgangswort ersetzt werden soll.
            ausgangswort (str): Das Ausgangswort, das ersetzt werden soll.
            ersetzung (str): Die Ersetzung für das Ausgangswort.
            ocr_ersetzung (bool): Falls es sich um die OCR Ersetzung handelt, sollte hier auf True gesetzt werden.
                                  Dann wird die Methode capitalize nicht verwendet (weil oft grossgeschriebene Wörter) falsch
                                  erkannt werden
            hervorhebung (bool): umklammert die Ersetzung mit einem span html-tag, um die Änderungen hervorzuheben

        Returns:
            str: Der modifizierte Textstelle-String mit der durchgeführten Ersetzung.

        Ersetzt das Ausgangswort mit der Ersetzung, wenn es von Leerzeichen umgeben ist.
        Ersetzt das Ausgangswort mit der Ersetzung, wenn es von einem Komma gefolgt ist.
        Ersetzt das Ausgangswort mit der Ersetzung, wenn es von einem Punkt gefolgt ist.
        Ersetzt das Ausgangswort mit der Ersetzung, wenn es am Satzanfang steht und großgeschrieben wird.
        (Bei OCR-Ersetzung: True) wird kein capitalize durchgeführt
        """
    if hervorhebung:
        # Ersetze das Ausgangswort mit der Ersetzung, wenn es von Leerzeichen umgeben ist
        textstelle = textstelle.replace(" " + ausgangswort + " ", ' <span class="ersetzung">' + ersetzung + "</span> ")
        # Ersetze das Ausgangswort mit der Ersetzung, wenn es von einem Komma gefolgt ist
        textstelle = textstelle.replace(" " + ausgangswort + ",", ' <span class="ersetzung">' + ersetzung + "</span>,")
        # Ersetze das Ausgangswort mit der Ersetzung, wenn es von einem Punkt gefolgt ist
        textstelle = textstelle.replace(" " + ausgangswort + ".", ' <span class="ersetzung">' + ersetzung + "</span>.")
        # Ersetze das Ausgangswort mit der Ersetzung, wenn es von einem Strichpunkt gefolgt ist
        textstelle = textstelle.replace(" " + ausgangswort + ";", ' <span class="ersetzung">' + ersetzung + "</span>;")
        # Ersetze das Ausgangswort mit der Ersetzung, wenn es von einem Fragezeichen gefolgt ist
        textstelle = textstelle.replace(" " + ausgangswort + "?", ' <span class="ersetzung">' + ersetzung + "</span>?")
        # Ersetze das Ausgangswort mit der Ersetzung, wenn es von einem Ausrufezeichen gefolgt ist
        textstelle = textstelle.replace(" " + ausgangswort + "!", ' <span class="ersetzung">' + ersetzung + "</span>!")
        # Ersetze ein Wort, obwohl es zuvor zusammengesetzt worden ist
        textstelle = textstelle.replace(" " + ausgangswort[:-1] + '<span class="ersetzung">' + ausgangswort[-1] + "</span>", ' <span class="ersetzung">' + ersetzung + "</span> ")
    else:
        # Ersetze das Ausgangswort mit der Ersetzung, wenn es von Leerzeichen umgeben ist
        textstelle = textstelle.replace(" " + ausgangswort + " ", " " + ersetzung + " ")
        # Ersetze das Ausgangswort mit der Ersetzung, wenn es von einem Komma gefolgt ist
        textstelle = textstelle.replace(" " + ausgangswort + ",", " " + ersetzung + ",")
        # Ersetze das Ausgangswort mit der Ersetzung, wenn es von einem Punkt gefolgt ist
        textstelle = textstelle.replace(" " + ausgangswort + ".", " " + ersetzung + ".")
        # Ersetze das Ausgangswort mit der Ersetzung, wenn es von einem Strichpunkt gefolgt ist
        textstelle = textstelle.replace(" " + ausgangswort + ";", " " + ersetzung + ";")
        # Ersetze das Ausgangswort mit der Ersetzung, wenn es von einem Fragezeichen gefolgt ist
        textstelle = textstelle.replace(" " + ausgangswort + "?", " " + ersetzung + "?")
        # Ersetze das Ausgangswort mit der Ersetzung, wenn es von einem Ausrufezeichen gefolgt ist
        textstelle = textstelle.replace(" " + ausgangswort + "!", " " + ersetzung + "!")

    # Ersetze das Ausgangswort mit der Ersetzung, wenn es am Satzanfang steht und großgeschrieben wird
    if not ocr_ersetzung:
        if hervorhebung:
            textstelle = textstelle.replace(ausgangswort.capitalize() + " ", '<span class="ersetzung">' + ersetzung.capitalize() + "</span> ")
        else:
            textstelle = textstelle.replace(ausgangswort.capitalize() + " ", ersetzung.capitalize() + " ")
    else:
        if hervorhebung:
            textstelle = textstelle.replace(ausgangswort + " ", '<span class="ersetzung">' + ersetzung + "</span> ")
            textstelle = textstelle.replace(ausgangswort.capitalize() + " ", '<span class="ersetzung">' + ersetzung.capitalize() + "</span> ")
        else:
            textstelle = textstelle.replace(ausgangswort + " ", ersetzung + " ")
            textstelle = textstelle.replace(ausgangswort.capitalize() + " ", ersetzung.capitalize() + " ")

    return textstelle

import re

def ersetze_vergangenheitsform(text, verb, verbersetzung, hilfsverb, hervorhebung=False):
    # Hier kann man Redewendungen wie z.B. "Kost und Logis", "nach und nach" ausklammern, das Wort nach "und" muss angegeben werden
    redewendungsausnahmen = r"(?!\s*Logis|\s*nach|\s*zu)"

    # Set the regex pattern to match the word bzw. verb and the rest of the clause until the occurrence of ".", ",", "!", "?" or "und" "oder" (the last occurrence ist die letzte Gruppe)
    pattern = fr"\b{verb}\b(.*?)(\.|,|!|\?|:|\bund\b{redewendungsausnahmen}|\boder\b)(.*?|$)(\.|,|!|\?|:|\bund\b{redewendungsausnahmen}|\boder\b|$)(.*?|$)(\.|,|!|\?|:|\bund\b{redewendungsausnahmen}|\boder\b|$)"
    regex = re.compile(pattern, re.MULTILINE | re.DOTALL)

    # Loop through all matches in the sentence
    for match in regex.finditer(text):
        groups = match.groups()

        if hervorhebung:
            # Der Punkt in groups(1) ist kein Satzende, sondern für die Indikation einer Abkürzung
            if any(groups[0].endswith(abbr) and groups[1] == '.' for abbr in ["Fr", "ca", "bzw", "vgl", "usw", "bspw", "etc", "dat", "insb", "Mio", "Tsd"]):
                # Wenn groups(3) ein Punkt ist und das Ende von groups(2) eine Zahl, dürfte es sich um eine Währungsangabe handeln
                if groups[3] == '.' and groups[2][-1].isdigit():
                    # Folgt nach der Abkürzung und Währungsangabe ein "und" oder "oder" als Satzteilende, muss der Leerschlag beim hilfsverb anders gesetzt werden
                    if groups[5] in ["und", "oder"]:
                        text = text.replace(match.group(0), f"""<span class="ersetzung">{verbersetzung}</span>{groups[0]}{groups[1]}{groups[2]}{groups[3]}{groups[4]}<span class="ersetzung">{hilfsverb}</span> {groups[5]}""")
                    else:
                        text = text.replace(match.group(0), f"""<span class="ersetzung">{verbersetzung}</span>{groups[0]}{groups[1]}{groups[2]}{groups[3]}{groups[4]} <span class="ersetzung">{hilfsverb}</span>{groups[5]}""")
                # wenn groups(3) ein "und" oder "oder" ist braucht es einen anderen Leerschlag beim hilfsverb
                elif groups[3] in ["und", "oder"]:
                    text = text.replace(match.group(0), f"""<span class="ersetzung">{verbersetzung}</span>{groups[0]}{groups[1]}{groups[2]}<span class="ersetzung">{hilfsverb}</span> {groups[3]}{groups[4]}{groups[5]}""")
                else:
                    text = text.replace(match.group(0), f"""<span class="ersetzung">{verbersetzung}</span>{groups[0]}{groups[1]}{groups[2]} <span class="ersetzung">{hilfsverb}</span>{groups[3]}{groups[4]}{groups[5]}""")
            # Wenn groups(1) ein Punkt ist und der letzte Charakter von groups(0) eine Zahl, dürfte es sich um einen Währungsbetrag ohne vorangehende Fr. Abkürzung handeln
            elif groups[1] == '.' and groups[0][-1].isdigit():
                # Folgt nach der Abkürzung und Währungsangabe ein "und" oder "oder" als Satzteilende, muss der Leerschlag beim hilfsverb anders gesetzt werden
                if groups[3] in ["und", "oder"]:
                    text = text.replace(match.group(0), f"""<span class="ersetzung">{verbersetzung}</span>{groups[0]}{groups[1]}{groups[2]}{hilfsverb} {groups[3]}{groups[4]}{groups[5]}""")
                # wenn zusätzlich noch groups(3) ein Punkt ist und der letzte Charakter von Groups(2) eine Zahl, dürfte es sich um einen Datumsabkürzung "08.08.2001" handeln
                elif groups[3] == '.' and groups[2][-1].isdigit():
                    text = text.replace(match.group(0), f"""<span class="ersetzung">{verbersetzung}</span>{groups[0]}{groups[1]}{groups[2]}{groups[3]}{groups[4]} <span class="ersetzung">{hilfsverb}</span>{groups[5]}""")
                else:
                    text = text.replace(match.group(0), f"""<span class="ersetzung">{verbersetzung}</span>{groups[0]}{groups[1]}{groups[2]} <span class="ersetzung">{hilfsverb}</span>{groups[3]}{groups[4]}{groups[5]}""")
            # ist groups(1) ein "und" oder "oder" müssen die Leerzeichen anders gesetzt werden
            elif groups[1] in ["und", "oder"]:
                text = text.replace(match.group(0), f"""<span class="ersetzung">{verbersetzung}</span>{groups[0]} <span class="ersetzung">{hilfsverb}</span>{groups[1]}{groups[2]}{groups[3]}{groups[4]}{groups[5]}""")
            # Es wurde keine Abkürzung erkannt
            else:
                text = text.replace(match.group(0), f"""<span class="ersetzung">{verbersetzung}</span>{groups[0]} <span class="ersetzung">{hilfsverb}</span>{groups[1]}{groups[2]}{groups[3]}{groups[4]}{groups[5]}""")
        # keine hervorhebung
        else:
            # Der Punkt in groups(1) ist kein Satzende, sondern für die Indikation einer Abkürzung
            if any(groups[0].endswith(abbr) and groups[1] == '.' for abbr in ["Fr", "ca", "bzw", "vgl", "usw", "bspw", "etc", "dat"]):
                # Wenn groups(3) ein Punkt ist und das Ende von groups(2) eine Zahl, dürfte es sich um eine Währungsangabe handeln
                if groups[3] == '.' and groups[2][-1].isdigit():
                    # Folgt nach der Abkürzung und Währungsangabe ein "und" oder "oder" als Satzteilende, muss der Leerschlag beim hilfsverb anders gesetzt werden
                    if groups[5] in ["und", "oder"]:
                        text = text.replace(match.group(0), f"{verbersetzung}{groups[0]}{groups[1]}{groups[2]}{groups[3]}{groups[4]}{hilfsverb} {groups[5]}")
                    else:
                        text = text.replace(match.group(0), f"{verbersetzung}{groups[0]}{groups[1]}{groups[2]}{groups[3]}{groups[4]} {hilfsverb}{groups[5]}")
                # wenn groups(3) ein "und" oder "oder" ist braucht es einen anderen Leerschlag beim hilfsverb
                elif groups[3] in ["und", "oder"]:
                    text = text.replace(match.group(0), f"{verbersetzung}{groups[0]}{groups[1]}{groups[2]}{hilfsverb} {groups[3]}{groups[4]}{groups[5]}")
                else:
                    text = text.replace(match.group(0), f"{verbersetzung}{groups[0]}{groups[1]}{groups[2]} {hilfsverb}{groups[3]}{groups[4]}{groups[5]}")
            # Wenn groups(1) ein Punkt ist und der letzte Charakter von groups(0) eine Zahl, dürfte es sich um einen Währungsbetrag ohne vorangehende Fr. Abkürzung handeln
            elif groups[1] == '.' and groups[0][-1].isdigit():
                # Folgt nach der Abkürzung und Währungsangabe ein "und" oder "oder" als Satzteilende, muss der Leerschlag beim hilfsverb anders gesetzt werden
                if groups[3] in ["und", "oder"]:
                    text = text.replace(match.group(0), f"{verbersetzung}{groups[0]}{groups[1]}{groups[2]}{hilfsverb} {groups[3]}{groups[4]}{groups[5]}")
                # wenn zusätzlich noch groups(3) ein Punkt ist und der letzte Charakter von Groups(2) eine Zahl, dürfte es sich um einen Datumsabkürzung "08.08.2001" handeln
                elif groups[3] == '.' and groups[2][-1].isdigit():
                    text = text.replace(match.group(0), f"{verbersetzung}{groups[0]}{groups[1]}{groups[2]}{groups[3]}{groups[4]} {hilfsverb}{groups[5]}")
                else:
                    text = text.replace(match.group(0), f"{verbersetzung}{groups[0]}{groups[1]}{groups[2]} {hilfsverb}{groups[3]}{groups[4]}{groups[5]}")
            # ist groups(1) ein "und" oder "oder" müssen die Leerzeichen anders gesetzt werden
            elif groups[1] in ["und", "oder"]:
                text = text.replace(match.group(0), f"{verbersetzung}{groups[0]} {hilfsverb}{groups[1]}{groups[2]}{groups[3]}{groups[4]}{groups[5]}")
            # Es wurde keine Abkürzung erkannt
            else:
                text = text.replace(match.group(0), f"{verbersetzung}{groups[0]} {hilfsverb}{groups[1]}{groups[2]}{groups[3]}{groups[4]}{groups[5]}")


    return text

def ersetze_vergangenheitsform_old(textstelle, verb, verbersetzung, hilfsverb, hervorhebung=False):

    # Nachfolgend können Abkürzungen definiert werden, bei denen der Punkt nicht als Satzende verwechselt werden sollte
    # Der Nachvollziehbarkeit halber sollten diese mit dem Punkt reingeschrieben werden, der in der Folge für das Regexpattern entfernt wird
    # mehr als diese punktausnahmen geht momentan nicht
    punktausnahmen = [
        "Fr.",
        "\d.",
        "ca.",
    ]
    # punkt von Ppunktausnahmen entfernen
    punktausnahmen_ohne_punkt = [word[:-1] for word in punktausnahmen]
    def concatenate_strings_with_pipe(input_list):
        return "|".join(input_list)

    piped_ausnahmen = concatenate_strings_with_pipe(punktausnahmen_ohne_punkt)
    negative_lookbehind = "(?<!" + piped_ausnahmen + ")"
    regex_pattern = "(?<=\s)" + "\\b" + verb + "\\b" + "(.*?)(" + negative_lookbehind + "\.|,|!|\?|\sund\s|\soder\s)"

    # Erstelle ein Regex-Objekt
    regex = re.compile(
        regex_pattern,
        re.MULTILINE,
    )

    # Durchlaufe alle Übereinstimmungen im Text
    for match in regex.finditer(textstelle):
        groups = match.groups()
        # Je nachdem, ob ein Satzzeichen am Ende des Regex-Matches steht oder nicht
        # (d. h. "und" oder "oder" steht am Ende), muss das Leerzeichen anders eingefügt werden
        if hervorhebung:
            if groups[1] == "und" or groups[1] == "oder":
                textstelle = textstelle.replace(
                    match.group(),
                    '<span class="ersetzung">'
                    + verbersetzung
                    + "</span>"
                    + groups[0]
                    + '<span class="ersetzung">'
                    + hilfsverb
                    + "</span> "
                    + groups[1],
                )
            else:
                textstelle = textstelle.replace(
                    match.group(),
                    '<span class="ersetzung">'
                    + verbersetzung
                    + "</span>"
                    + groups[0]
                    + ' <span class="ersetzung">'
                    + hilfsverb
                    + "</span>"
                    + groups[1],
                )
        else:
            if groups[1] == "und" or groups[1] == "oder":
                textstelle = textstelle.replace(match.group(), verbersetzung + groups[0] + hilfsverb + " " + groups[1])
            else:
                textstelle = textstelle.replace(match.group(), verbersetzung + groups[0] + " " + hilfsverb + groups[1])

    return textstelle


def zeilenumbrueche_entfernen(textstelle, hervorhebung=False):
    # Allfällige Leerzeichen am Ende der Zeile löschen
    textstelle = re.sub(r'\s+$', '', textstelle, flags=re.MULTILINE)
    # Wenn Buchstabe, Ziffer oder Unterstrich am Ende der Zeile (ausser Bindestrich), Leerschlag hinzufügen
    textstelle = re.sub(r'([^-])$', r'\1 ', textstelle, flags=re.MULTILINE)
    
    # Bindestriche am Ende der Zeile entfernen
    if hervorhebung:
        # Prüfen, ob ein Bindestrich am Ende der Zeile steht
        if re.search(r"-$", textstelle, flags=re.MULTILINE):
            # Wenn True, das vorherige Zeichen mit dem span-Tag umklammern
            textstelle = re.sub(
                r"(.)(-)$", r'<span class="ersetzung">\1</span>', textstelle, flags=re.MULTILINE
            )
            # Bindestrich am Ende der Zeile löschen
            textstelle = re.sub(r"-$", "", textstelle, flags=re.MULTILINE)
    else:
        # Bindestrich am Ende der Zeile löschen
        textstelle = re.sub(r'-$', '', textstelle, flags=re.MULTILINE)

    # Zeilenumbrüche (andere Art) entfernen
    if hervorhebung:
        if re.search(r"\n", textstelle, flags=re.MULTILINE):
            # Wenn True, das vorherige Zeichen mit dem span-Tag umklammern, die regex-Ausnahme [^>] ist gesetzt, damit verhindert wird, dass ein vorherig eingesetzter </span>-tag
            # bearbeitet wird.
            textstelle = re.sub(
                r"(.[^>])(\n)", r'<span class="ersetzung">\1</span>', textstelle, flags=re.MULTILINE
            )
            # Zeilenumbruch entfernen
            textstelle = re.sub(r"\n", "", textstelle, flags=re.MULTILINE)
    else:
        #Zeilenumbruch entfernen
        textstelle = textstelle.replace('\n', '')

    # Carriage breaks (Zeilenumbrüche) entfernen
    if hervorhebung:
        if re.search(r"\r", textstelle, flags=re.MULTILINE):
            # Wenn True, das vorherige Zeichen mit dem span-Tag umklammern, die regex-Ausnahme [^>] ist gesetzt, damit verhindert wird, dass ein vorherig eingesetzter </span>-tag
            # bearbeitet wird.
            textstelle = re.sub(
                r"(.[^>])(\r)", r'<span class="ersetzung">\1</span>', textstelle, flags=re.MULTILINE
            )
            # Zeilenumbruch entfernen
            textstelle = re.sub(r"\r", "", textstelle, flags=re.MULTILINE)
    else:
        #Zeilenumbruch entfernen
        textstelle = textstelle.replace('\r', '')
    

    # doppelte und dreifache Leerzeichen ersetzen
    textstelle = textstelle.replace('  ', ' ')
    textstelle = textstelle.replace('   ', ' ')

    # gekreuzte Anführungs- und Schlusszeichenformatierung ersetzen
    textstelle = textstelle.replace(chr(171), chr(34))
    textstelle = textstelle.replace(chr(187), chr(34))

    # Frankenformatierung
    textstelle = textstelle.replace(' CHF ', ' Fr. ')
    textstelle = textstelle.replace(' SFR ', ' Fr. ')
    textstelle = textstelle.replace('.00 ', '.-- ')

    # entferne Platzhalterquadrat für unbekanntes Zeichen
    textstelle = textstelle.replace(chr(0), '')

    # Ersetze getrennte Wörter, z.B. "Jung- geselle" zu "Jungeselle"
    if hervorhebung:
        if re.search(r'(\w)-\s(\w)', textstelle, flags=re.MULTILINE):
            # Wenn True, das vorherige Zeichen mit dem span-Tag umklammern
            textstelle = re.sub(
                r"(\w)-\s(\w)", r'<span class="ersetzung">\1\2</span>', textstelle, flags=re.MULTILINE
            )
            # Bindestrich am Ende der Zeile löschen
            textstelle = re.sub(r"-$", "", textstelle, flags=re.MULTILINE)
    else:
        textstelle = re.sub(r'(\w)-\s(\w)', r'\1\2', textstelle)

    return textstelle


def umlautkorrektur(string, encoding='utf-8'):
    return (string.encode('latin1') # To bytes, required by 'unicode-escape'
             .decode('unicode-escape') # Perform the actual octal-escaping decode
             .encode('latin1') # 1:1 mapping back to bytes
             .decode(encoding))


def ocr_ersetzung(textstelle, hervorhebung=False):
    """
        Ersetzt typische Fehler, die bei der OCR Texterkennung entstehen (oft wird dass grossgeschriebene I als kleines l missinterpretiert)

        Args:
            textstelle (str): Die zu bearbeitende Textstelle.
            hervorhebung (bool): umklammert die Ersetzung mit einem span html-tag, um die Änderungen hervorzuheben.

        Returns:
            str: Der modifizierte Text mit den ersetzen Wörtern.

        """

    # Ersetzung einer fehlerhaften Interpretation des Anführungszeichens
    if hervorhebung:
        textstelle = textstelle.replace(",,", f'<span class="ersetzung">{chr(34)}</span>')
    else:
        textstelle = textstelle.replace(",,", chr(34))

    # Ersetzung einer fehlerhaften Interpretation des Prozentzeichens
    if hervorhebung:
        textstelle = textstelle.replace("o/o", f'<span class="ersetzung">%</span>')
    else:
        textstelle = textstelle.replace("o/o", "%")

    # Ersetzung der regelmässig falschen Erkennung des w im Wort  
    if hervorhebung:
        textstelle = textstelle.replace("nrv", '<span class="ersetzung">rw</span>')
        textstelle = textstelle.replace("nrv", '<span class="ersetzung">rw</span>')
        textstelle = textstelle.replace("nry", '<span class="ersetzung">rw</span>')  
    else:
        textstelle = textstelle.replace("nrv", "rw")
        textstelle = textstelle.replace("nrv", "rw")
        textstelle = textstelle.replace("nry", "rw")


    for ausgangswort, ersetzung in ocr_ersetzungen.items():
        textstelle = ersetze_wort(textstelle, ausgangswort, ersetzung, ocr_ersetzung=True, hervorhebung=hervorhebung)

    return textstelle


def pronomen_ersetzung(textstelle, geschlecht='m', hervorhebung=False):
    """
        Ersetzt Pronomen in einer Textstelle entsprechend dem angegebenen Geschlecht.

        Args:
            textstelle (str): Die Textstelle, in der die Pronomen ersetzt werden sollen.
            geschlecht (str, optional): Das Geschlecht, für das die Pronomen ersetzt werden sollen.
                Akzeptierte Werte: 'm' (männlich) oder 'w' (weiblich). Standardmäßig ist das Geschlecht auf 'm' eingestellt.
            hervorhebung (bool): umklammert die Ersetzung mit einem span html-tag, um die Änderungen hervorzuheben

        Returns:
            str: Die Textstelle mit den vorgenommenen Pronomen-Ersetzungen.

        """
    if geschlecht == 'm':
        ersetzungen_dict = pronomen_ersetzungen_m
    else:
        ersetzungen_dict = pronomen_ersetzungen_w

    for ausgangswort, ersetzung in ersetzungen_dict.items():
        textstelle = ersetze_wort(textstelle, ausgangswort, ersetzung[0], hervorhebung=hervorhebung)

    return textstelle


def verben_ersetzung(textstelle, hervorhebung=False):
    # zuerst präteritum-Verben ersetzen
    for ausgangswort, ersetzungen in verben_ersetzung_praeteritum.items():
        textstelle = ersetze_vergangenheitsform(
            textstelle,
            ausgangswort,
            ersetzungen[0],
            ersetzungen[1],
            hervorhebung=hervorhebung,
        )

    # dann präsens verben ersetzen
    for ausgangswort, ersetzung in verben_ersetzung_praesens.items():
        textstelle = ersetze_wort(
            textstelle, ausgangswort, ersetzung, hervorhebung=hervorhebung
        )

    # schlussendlich noch verben zusammenfuegen
    if hervorhebung:
        for ausgangswort, ersetzung in verben_zusammenfuegung.items():
            split_list = ausgangswort.split()
            split_list[1] = '<span class="ersetzung">' + split_list[1] + '</span>'
            textstelle = ersetze_wort(
                textstelle, ' '.join(split_list), ersetzung, hervorhebung=hervorhebung
            )
    else:
        for ausgangswort, ersetzung in verben_zusammenfuegung.items():
            textstelle = ersetze_wort(
                textstelle, ausgangswort, ersetzung, hervorhebung=hervorhebung
            )

    return textstelle


def als_aussage_formatieren(textstelle, geschlecht='m', hervorhebung=False):
    # bei der FUnktions als_aussage_formatieren wird beim Zeilenumbruch entfernen wird hervorhebung bewusst auf
    # False gesetzt, weil die eingefügten html-tags
    # die erkennung der verben für die Verbenersetzung verhindert
    textstelle = zeilenumbrueche_entfernen(textstelle, hervorhebung=False)
    textstelle = ocr_ersetzung(textstelle, hervorhebung=hervorhebung)
    textstelle = pronomen_ersetzung(textstelle, geschlecht, hervorhebung=hervorhebung)
    textstelle = verben_ersetzung(textstelle, hervorhebung=hervorhebung)
    # textstelle = umlautkorrektur(textstelle)
    return textstelle

def von_pdf_einfuegen(textstelle, hervorhebung=False):
    textstelle = zeilenumbrueche_entfernen(textstelle, hervorhebung=hervorhebung)
    textstelle = ocr_ersetzung(textstelle, hervorhebung=hervorhebung)
    return textstelle