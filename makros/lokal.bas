'''Windows API für Zwischenablagaufruf, Deklarationen
Declare Function OpenClipboard Lib "User32" (ByVal hwnd As Long) _
   As Long
Declare Function CloseClipboard Lib "User32" () As Long
Declare Function GetClipboardData Lib "User32" (ByVal wFormat As _
   Long) As Long
Declare Function GlobalAlloc Lib "kernel32" (ByVal wFlags&, ByVal _
   dwBytes As Long) As Long
Declare Function GlobalLock Lib "kernel32" (ByVal hMem As Long) _
   As Long
Declare Function GlobalUnlock Lib "kernel32" (ByVal hMem As Long) _
   As Long
Declare Function GlobalSize Lib "kernel32" (ByVal hMem As Long) _
   As Long
Declare Function lstrcpy Lib "kernel32" (ByVal lpString1 As Any, _
   ByVal lpString2 As Any) As Long
 
Public Const GHND = &H42
Public Const CF_TEXT = 1
Public Const MAXSIZE = 4096

''' Funktion, um Zwischenablage abzurufen
'''
''' Diese Funktion ruft den Inhalt der Zwischenablage ab und gibt ihn als String zurück.
'''
''' Returns:
'''     String: Der Inhalt der Zwischenablage
'''
''' Hinweise:
'''     - Diese Funktion verwendet Windows-API-Aufrufe für den Zugriff auf die Zwischenablage.
'''     - Die Funktion gibt eine leere Zeichenkette zurück, wenn die Zwischenablage nicht zugänglich ist.
'''
Function ClipBoard_GetData()
   Dim hClipMemory As Long
   Dim lpClipMemory As Long
   Dim MyString As String
   Dim RetVal As Long
 
   If OpenClipboard(0&) = 0 Then
      MsgBox "Zwischenablage konnte nicht aufgerufen werden, vielleicht ist sie durch ein anderes Programm geöffnet?"
      Exit Function
   End If
          
   ' Obtain the handle to the global memory
   ' block that is referencing the text.
   hClipMemory = GetClipboardData(CF_TEXT)
   If IsNull(hClipMemory) Then
      MsgBox "Could not allocate memory"
      GoTo OutOfHere
   End If
 
   ' Lock Clipboard memory so we can reference
   ' the actual data string.
   lpClipMemory = GlobalLock(hClipMemory)
 
   If Not IsNull(lpClipMemory) Then
      MyString = Space$(MAXSIZE)
      RetVal = lstrcpy(MyString, lpClipMemory)
      RetVal = GlobalUnlock(hClipMemory)
       
   Else
      MsgBox "Could not lock memory to copy string from."
   End If
 
OutOfHere:
 
   RetVal = CloseClipboard()
   'Variable MyString in string konvertieren
   MyString = CStr(MyString)
   ClipBoard_GetData = MyString
 
End Function


Private Function ersetze(MyString As String, Muster As String, Ersatz As String)
'''Regex Funktion die bei der nachfolgenden Funktion FunctionZeilenumbruecheEntfernen benötigt wird'''

'Durch die folgende Initialisierung (2 Zeilen) des regexObject bedarf es keiner Einbindung durch Extras -> Verweise -> Microsoft VBScript Regular Expressions 5.5 mehr
Dim RegexObject As Object
Set RegexObject = CreateObject("VBScript.RegExp")
RegexObject.Global = True
RegexObject.MultiLine = True
RegexObject.Pattern = Muster
ersetze = RegexObject.Replace(MyString, Ersatz)

End Function


Private Function ersetzeVergangenheitsform(text As String, verb As String, verbersetzung As String, hilfsverb As String)

'Create a regex object
Set regex = CreateObject("VBScript.RegExp")
regex.Global = True
regex.MultiLine = True

'Hier kann man Redewendungen wie z.B. "Kost und Logis", "nach und nach", "ab und zu", "A und O" ausklammern, das Wort nach "und" muss angegeben werden
Dim redewendungsausnahmen As String
redewendungsausnahmen = "(?!\s*Logis|\s*nach|\s*zu|\s*O\s*)"

'Set the regex pattern to match the word bzw. verb and the rest of the clause until the occurence of ".", ",", "!", "?" or "und" "oder" (the last occurence ist die letzte Gruppe)
regex.Pattern = verb & _
                "(.*?)" & _
                "(\.|,|!|\?|:|\bund\b" & redewendungsausnahmen & "|\boder\b)" & _
                "(.*?|$)" & _
                "(\.|,|!|\?|:|\bund\b" & redewendungsausnahmen & "|\boder\b|$)" & _
                "(.*?|$)" & _
                "(\.|,|!|\?|:|\bund\b" & redewendungsausnahmen & "|\boder\b|$)"

'Loop through all matches in the sentence
    For Each match In regex.Execute(text)
    
        'Debug.Print "match.Value= " + match.Value
        
        Dim groups As Object
        ' nachfolgend werden die Gruppen des regex-patterns (welche mit den klammern bezeichnet werden) erfasst.
        Set groups = match.SubMatches
        
        'Debug.Print "verbersetzung= " + verbersetzung
        'Debug.Print "hilfsverb= " + hilfsverb
        'Debug.Print "groups(0)= " + groups(0)
        'Debug.Print "groups(1)= " + groups(1)
        'Debug.Print "groups(2)= " + groups(2)
        'Debug.Print "groups(3)= " + groups(3)
        'Debug.Print "groups(4)= " + groups(4)
        'Debug.Print "groups(5)= " + groups(5)
        
        'Der Punkt in groups(1) ist kein Satzende sondern für die Indikation einer abkürzung
        If groups(0) Like "*Fr" _
        Or groups(0) Like "*ca" _
        Or groups(0) Like "*bzw" _
        Or groups(0) Like "*vgl" _
        Or groups(0) Like "*usw" _
        Or groups(0) Like "*bspw" _
        Or groups(0) Like "*etc" _
        Or groups(0) Like "*dat" _
        Or groups(0) Like "*insb" _
        Or groups(0) Like "*Mio" _
        Or groups(0) Like "*Tsd" _
        Or groups(0) Like "*Jan" _
        Or groups(0) Like "*Feb" _
        Or groups(0) Like "*Jun" _
        Or groups(0) Like "*Jul" _
        Or groups(0) Like "*Aug" _
        Or groups(0) Like "*Sep" _
        Or groups(0) Like "*Okt" _
        Or groups(0) Like "*Nov" _
        Or groups(0) Like "*Dez" _
        And groups(1) = "." Then
            'wenn groups(3) ein Punkt ist und das Ende von groups(2) eine Zahl, dürfte es sich um eine währungsangabe handeln
            If groups(3) = "." And IsNumeric(Right(groups(2), 1)) Then
                'Folgt nach der Abkürzung und Währungsangabe ein "und" oder "oder" als Satzteilende, muss der Leerschlag beim hilfsverb anders gesetzt werden
                If groups(5) = "und" Or groups(5) = "oder" Then
                    text = Replace(text, match.Value, verbersetzung + groups(0) + groups(1) + groups(2) + groups(3) + groups(4) + hilfsverb + " " + groups(5))
                Else
                    text = Replace(text, match.Value, verbersetzung + groups(0) + groups(1) + groups(2) + groups(3) + groups(4) + " " + hilfsverb + groups(5))
                End If
            'wenn groups(3) ein "und" oder "oder" ist braucht es einen anderen leerschlag beim hilfsverb
            ElseIf groups(3) = "und" Or groups(3) = "oder" Then
                text = Replace(text, match.Value, verbersetzung + groups(0) + groups(1) + groups(2) + hilfsverb + " " + groups(3) + groups(4) + groups(5))
            Else
                text = Replace(text, match.Value, verbersetzung + groups(0) + groups(1) + groups(2) + " " + hilfsverb + groups(3) + groups(4) + groups(5))
            End If
        'Wenn  groups(1) ein Punkt ist und der letzte Charakter von groups(0) eine Zahl , dürfte es sich um einen Währungsbetrag ohne vorangehende Fr. abkürzung handeln
        ElseIf groups(1) = "." And IsNumeric(Right(groups(0), 1)) Then
            'Folgt nach der Abkürzung und Währungsangabe ein "und" oder "oder" als Satzteilende, muss der Leerschlag beim hilfsverb anders gesetzt werden
            If groups(3) = "und" Or groups(3) = "oder" Then
                text = Replace(text, match.Value, verbersetzung + groups(0) + groups(1) + groups(2) + hilfsverb + " " + groups(3) + groups(4) + groups(5))
            'wenn zusätzlich noch groups(3) ein Punkt ist und der letzte Charakter von Groups(2) eine Zahl, dürfte es sich um einen Datumsabkürzung "08.08.2001" handeln
            ElseIf groups(3) = "." And IsNumeric(Right(groups(2), 1)) Then
                text = Replace(text, match.Value, verbersetzung + groups(0) + groups(1) + groups(2) + groups(3) + groups(4) + " " + hilfsverb + groups(5))
            Else
                text = Replace(text, match.Value, verbersetzung + groups(0) + groups(1) + groups(2) + " " + hilfsverb + groups(3) + groups(4) + groups(5))
            End If
        'ist groups(1) ein "und" oder "oder" müssen die Leerzeichen anders gesetzt werden
        ElseIf groups(1) = "und" Or groups(1) = "oder" Then
            text = Replace(text, match.Value, verbersetzung + groups(0) + hilfsverb + " " + groups(1) + groups(2) + groups(3) + groups(4) + groups(5))
        'Es wurde keine Abkürzung erkannt
        Else
            text = Replace(text, match.Value, verbersetzung + groups(0) + " " + hilfsverb + groups(1) + groups(2) + groups(3) + groups(4) + groups(5))
        End If
    Next match
    
ersetzeVergangenheitsform = text

End Function



Function FunctionZeilenumbruecheEntfernen(ByVal textstelle As String) As String
    
    'Allfällige Leerzeichen am ende der Zeile löschen
    textstelle = ersetze(textstelle, "\s+$", "")
    'Wenn Buchstabe, Ziffer oder Unterstrich am Ende der Zeile (ausser Bindestriche - davon gibt es mehrere Arten), Leerschlag hinzufügen
    textstelle = ersetze(textstelle, "([^-­])$", "$1 ")
    'Bindestrich am Ende der Zeile löschen
    textstelle = ersetze(textstelle, "-$", "")

    'Zeilenumbrüche (andere Art) entfernen
    textstelle = Replace(textstelle, Chr(10), "")
    'Carriage breaks (Zeilenumbrüche) entfernen
    textstelle = Replace(textstelle, Chr(13), "")
    
    'doppelte und dreifache Leerzeichen ersetzen
    textstelle = Replace(textstelle, "  ", " ")
    textstelle = Replace(textstelle, "   ", " ")
    
    'gekreuzte Anführungs- und Schlusszeichenformatierung ersetzen
    textstelle = ersetze(textstelle, Chr(171), Chr(34))
    textstelle = ersetze(textstelle, Chr(187), Chr(34))
    
    'KRG Frankenformatierungen setzen
    textstelle = Replace(textstelle, " CHF ", " Fr. ")
    textstelle = Replace(textstelle, " SFR ", " Fr. ")
    textstelle = Replace(textstelle, ".00 ", ".-- ")
    
    'entferne Platzhalterquadrat für unbekanntes Zeichen
    textstelle = Replace(textstelle, ChrW(0), "")
    
    'Das Returnstatment funktioniert inden man den Namen der Funktion mit dem Return gleichsetzt
    FunctionZeilenumbruecheEntfernen = textstelle
    
End Function

Function EntferneWorttrennungenImText(ByVal inputText As String) As String
    'Da der PDF-X-Change Editor Leerzeichen mittlerweile selber löscht, aber Worttrennungen nicht, müssen im Text enthaltene Bindestriche entfernt werden
    'Allerdings sollten Zahlenräume wie z.b. 1-2 Minuten nicht zu 12 Minuten geändert werden, weshalb nur Worttrennungen entfernt werden sollten, die vorne
    'und hinten einen Charakter, keine Zahl, haben
    Dim words() As String
    Dim i As Integer
    
    ' Zerlege den Text in Wörter
    words = Split(inputText, " ")
    
    ' Iteriere durch die Wörter
    For i = 0 To UBound(words)
        'Debug.Print "Word before processing: " & words(i) ' Debugging-Print-Anweisung für das aktuelle Wort
        ' Suche nach Bindestrichen
        If InStr(words(i), "-") > 0 Then
            ' Prüfe, dass vor und nach dem Trennzeichen keine Nummer und kein Leerzeichen steht.
            If (Not IsNumeric(Left(words(i), 1)) And Left(words(i), 1) <> " ") _
                And (Not IsNumeric(Right(words(i), 1)) And Right(words(i), 1) <> " ") Then
                ' Prüfe, ob der Buchstabe vor oder nach dem Bindestrich großgeschrieben ist
                Dim prevChar As String
                Dim nextChar As String
                prevChar = Mid(words(i), InStrRev(words(i), "-") - 1, 1)
                nextChar = Mid(words(i), InStr(words(i), "-") + 1, 1)
                'Debug.Print "Prev Char: " & prevChar
                'Debug.Print "Next Char: " & nextChar
                
                If IsUpperCase(prevChar) Or IsUpperCase(nextChar) Then
                    ' Buchstaben sind großgeschrieben, daher Bindestrich nicht entfernen
                Else
                    ' Entferne den Bindestrich
                    'Debug.Print "Removing hyphen from word: " & words(i)
                    words(i) = Replace(words(i), "-", "")
                End If
            End If
        End If
        ' Suche nach Bindestrichen anderer Art (Unicode-Zeichen (U+00AD)- weiches Trennzeichen)
        If InStr(words(i), "­") > 0 Then
            ' Prüfe, dass vor und nach dem Trennzeichen keine Nummer und kein Leerzeichen steht.
            If (Not IsNumeric(Left(words(i), 1)) And Left(words(i), 1) <> " ") _
                And (Not IsNumeric(Right(words(i), 1)) And Right(words(i), 1) <> " ") Then
                ' Prüfe, ob der Buchstabe vor oder nach dem Bindestrich großgeschrieben ist
                Dim prevChar2 As String
                Dim nextChar2 As String
                prevChar2 = Mid(words(i), InStrRev(words(i), "­") - 1, 1)
                nextChar2 = Mid(words(i), InStr(words(i), "­") + 1, 1)
                Debug.Print "Prev Char2: " & prevChar2
                Debug.Print "Next Char2: " & nextChar2
                
                If IsUpperCase(prevChar2) Or IsUpperCase(nextChar2) Then
                    ' Buchstaben sind großgeschrieben, daher Bindestrich nicht entfernen
                Else
                    ' Entferne den Bindestrich
                    Debug.Print "Removing hyphen from word: " & words(i)
                    words(i) = Replace(words(i), "­", "")
                End If
            End If
        End If
    Next i
    
    ' Setze die Wörter wieder zusammen und entferne zusätzliche Leerzeichen
    EntferneWorttrennungenImText = Trim(Join(words, " "))
End Function

Function IsUpperCase(ByVal str As String) As Boolean
    ' Hilfsfunktion für EntferneWorttrennungenImText, prüft ob ein Charakter Grossgeschrieben ist.
    IsUpperCase = UCase(str) = str
End Function

Function SpezifischeFormatierungen(ByVal textstelle As String) As String
    
    'Frankenformatierung
    textstelle = Replace(textstelle, " CHF ", " Fr. ")
    textstelle = Replace(textstelle, " SFR ", " Fr. ")
    textstelle = Replace(textstelle, ".00 ", ".-- ")
    
    'Das Returnstatment funktioniert inden man den Namen der Funktion mit dem Return gleichsetzt
    SpezifischeFormatierungen = textstelle
    
End Function

Private Function RegelmaessigeOCRFehlerErsetzung(textstelle As String) As String

    'lch (Ich falsch geschrieben)
    textstelle = Replace(textstelle, "lch ", "Ich ")
    
    'fehlerhafte Interpretation des Anführungszeichens
    textstelle = ersetze(textstelle, ",,", Chr(34))
    
    'fehlerhafte Interpretation des Prozentzeichens
    textstelle = ersetze(textstelle, "o/o", "%")
    
    'regelmässige falsche Erkennung des w - test ohne Leerzeichen
    textstelle = Replace(textstelle, "nrv", "rw")
    textstelle = Replace(textstelle, "nru", "rw")
    textstelle = Replace(textstelle, "nry", "rw")
    
    'Ersetzung von OCR Fehlern: das grosse I wird fehlerhaft als l erkannt
    'In
    textstelle = Replace(textstelle, " ln ", " In ")
    textstelle = Replace(textstelle, " ln,", " In,")
    textstelle = Replace(textstelle, " ln.", " In.")
    'Information
    textstelle = Replace(textstelle, " lnformation ", " Information ")
    textstelle = Replace(textstelle, " lnformation,", " Information,")
    textstelle = Replace(textstelle, " lnformation.", " Information.")
    'Informationen
    textstelle = Replace(textstelle, " lnformationen ", " Informationen ")
    textstelle = Replace(textstelle, " lnformationen,", " Informationen,")
    textstelle = Replace(textstelle, " lnformationen.", " Informationen.")
    'Info
    textstelle = Replace(textstelle, " lnfo ", " Info ")
    textstelle = Replace(textstelle, " lnfo,", " Info,")
    textstelle = Replace(textstelle, " lnfo.", " Info.")
    'Infos
    textstelle = Replace(textstelle, " lnfos ", " Infos ")
    textstelle = Replace(textstelle, " lnfos,", " Infos,")
    textstelle = Replace(textstelle, " lnfos.", " Infos.")
    'Idee
    textstelle = Replace(textstelle, " ldee ", " Idee ")
    textstelle = Replace(textstelle, " ldee,", " Idee,")
    textstelle = Replace(textstelle, " ldee.", " Idee.")
    'Ideen
    textstelle = Replace(textstelle, " ldeen ", " Ideen ")
    textstelle = Replace(textstelle, " ldeen,", " Ideen,")
    textstelle = Replace(textstelle, " ldeen.", " Ideen.")
    'Insider
    textstelle = Replace(textstelle, " lnsider ", " Insider ")
    textstelle = Replace(textstelle, " lnsider,", " Insider,")
    textstelle = Replace(textstelle, " lnsider.", " Insider.")
    'Irrtum
    textstelle = Replace(textstelle, " lrrtum ", " Irrtum ")
    textstelle = Replace(textstelle, " lrrtum,", " Irrtum,")
    textstelle = Replace(textstelle, " lrrtum.", " Irrtum.")
    'Identifikation
    textstelle = Replace(textstelle, " ldentifikation ", " Identifikation ")
    textstelle = Replace(textstelle, " ldentifikation,", " Identifikation,")
    textstelle = Replace(textstelle, " ldentifikation.", " Identifikation.")
    'Instruktionen
    textstelle = Replace(textstelle, " lnstruktionen ", " Instruktionen ")
    textstelle = Replace(textstelle, " lnstruktionen,", " Instruktionen,")
    textstelle = Replace(textstelle, " lnstruktionen.", " Instruktionen.")
    'In (in am Satzanfang)
    textstelle = Replace(textstelle, " ln ", " In ")
    'Interesse
    textstelle = Replace(textstelle, " lnteresse ", " Interesse ")
    textstelle = Replace(textstelle, " lnteresse,", " Interesse,")
    textstelle = Replace(textstelle, " lnteresse.", " Interesse.")
    'Irgendwann
    textstelle = Replace(textstelle, " lrgendwann ", " Irgendwann ")
    textstelle = Replace(textstelle, " lrgendwann,", " Irgendwann,")
    textstelle = Replace(textstelle, " lrgendwann.", " Irgendwann.")
    'Inhalt
    textstelle = Replace(textstelle, " lnhalt ", " Inhalt ")
    textstelle = Replace(textstelle, " lnhalt,", " Inhalt,")
    textstelle = Replace(textstelle, " lnhalt.", " Inhalt.")
    'Inhaltlich
    textstelle = Replace(textstelle, " lnhaltlich ", " Inhaltlich ")
    textstelle = Replace(textstelle, " lnhaltlich,", " Inhaltlich,")
    textstelle = Replace(textstelle, " lnhaltlich.", " Inhaltlich.")
    'Interpretation
    textstelle = Replace(textstelle, " lnterpretation ", " Interpretation ")
    textstelle = Replace(textstelle, " lnterpretation,", " Interpretation,")
    textstelle = Replace(textstelle, " lnterpretation.", " Interpretation.")
    'Initiative
    textstelle = Replace(textstelle, " lnitiative ", " Initiative ")
    textstelle = Replace(textstelle, " lnitiative,", " Initiative,")
    textstelle = Replace(textstelle, " lnitiative.", " Initiative.")
    'Initiative
    textstelle = Replace(textstelle, " lhnen ", " Ihnen ")
    textstelle = Replace(textstelle, " lhnen,", " Ihnen,")
    textstelle = Replace(textstelle, " lhnen.", " Ihnen.")
    'erwähnt
    textstelle = Replace(textstelle, " enruähnt  ", " erwähnt ")
    textstelle = Replace(textstelle, " enruähnt,", " erwähnt,")
    textstelle = Replace(textstelle, " enruähnt.", " erwähnt.")
    'erwähnen
    textstelle = Replace(textstelle, " enruähnen ", " erwähnen ")
    textstelle = Replace(textstelle, " enruähnen,", " erwähnen,")
    textstelle = Replace(textstelle, " enruähnen.", " erwähnen.")
    'erwähnen
    textstelle = Replace(textstelle, " enryähnen ", " erwähnen ")
    textstelle = Replace(textstelle, " enryähnen,", " erwähnen,")
    textstelle = Replace(textstelle, " enryähnen.", " erwähnen.")
    'erwähnen
    textstelle = Replace(textstelle, " enrvähnen ", " erwähnen ")
    textstelle = Replace(textstelle, " enrvähnen,", " erwähnen,")
    textstelle = Replace(textstelle, " enrvähnen.", " erwähnen.")
    'erwartet
    textstelle = Replace(textstelle, " enruartet ", " erwartet ")
    textstelle = Replace(textstelle, " enruartet,", " erwartet,")
    textstelle = Replace(textstelle, " enruartet.", " erwartet.")
    'normalerweise
    textstelle = Replace(textstelle, " normalenrueise ", " normalerweise ")
    textstelle = Replace(textstelle, " normalenrueise,", " normalerweise,")
    textstelle = Replace(textstelle, " normalenrueise.", " normalerweise.")
    'Inhaber
    textstelle = Replace(textstelle, " lnhaber ", " Inhaber ")
    textstelle = Replace(textstelle, " lnhaber,", " Inhaber,")
    textstelle = Replace(textstelle, " lnhaber.", " Inhaber.")
    'verwenden
    textstelle = Replace(textstelle, " venruenden ", " verwenden ")
    textstelle = Replace(textstelle, " venruenden ,", " verwenden,")
    textstelle = Replace(textstelle, " venruenden .", " verwenden.")
    'Immobilie
    textstelle = Replace(textstelle, " lmmobilie ", " Immobilie ")
    textstelle = Replace(textstelle, " lmmobilie,", " Immobilie,")
    textstelle = Replace(textstelle, " lmmobilie.", " Immobilie.")
    'Immobilien
    textstelle = Replace(textstelle, " lmmobilien ", " Immobilien ")
    textstelle = Replace(textstelle, " lmmobilien,", " Immobilien,")
    textstelle = Replace(textstelle, " lmmobilien.", " Immobilien.")
    'Investition
    textstelle = Replace(textstelle, " lnvestition ", " Investition ")
    textstelle = Replace(textstelle, " lnvestition,", " Investition,")
    textstelle = Replace(textstelle, " lnvestition.", " Investition.")
    'Investitionen
    textstelle = Replace(textstelle, " lnvestitionen ", " Investitionen ")
    textstelle = Replace(textstelle, " lnvestitionen,", " Investitionen,")
    textstelle = Replace(textstelle, " lnvestitionen.", " Investitionen.")
    'Irgendwo
    textstelle = Replace(textstelle, " lrgendwo ", " Irgendwo ")
    textstelle = Replace(textstelle, " lrgendwo,", " Irgendwo,")
    textstelle = Replace(textstelle, " lrgendwo.", " Irgendwo.")
    'lrgendwann
    textstelle = Replace(textstelle, " lrgendwann ", " Irgendwann ")
    textstelle = Replace(textstelle, " lrgendwann,", " Irgendwann,")
    textstelle = Replace(textstelle, " lrgendwann.", " Irgendwann.")
    'lrgendwie
    textstelle = Replace(textstelle, " lrgendwie ", " Irgendwie ")
    textstelle = Replace(textstelle, " lrgendwie,", " Irgendwie,")
    textstelle = Replace(textstelle, " lrgendwie.", " Irgendwie.")
    'Internet
    textstelle = Replace(textstelle, " lnternet ", " Internet ")
    textstelle = Replace(textstelle, " lnternet,", " Internet,")
    textstelle = Replace(textstelle, " lnternet.", " Internet.")
    'Internetseite
    textstelle = Replace(textstelle, " lnternetseite ", " Internetseite ")
    textstelle = Replace(textstelle, " lnternetseite,", " Internetseite,")
    textstelle = Replace(textstelle, " lnternetseite.", " Internetseite.")
    'Internetauftritt
    textstelle = Replace(textstelle, " lnternetauftritt ", " Internetauftritt ")
    textstelle = Replace(textstelle, " lnternetauftritt,", " Internetauftritt,")
    textstelle = Replace(textstelle, " lnternetauftritt.", " Internetauftritt.")
    'erwähnt
    textstelle = Replace(textstelle, " enrvähnt ", " erwähnt ")
    textstelle = Replace(textstelle, " enrvähnt,", " erwähnt,")
    textstelle = Replace(textstelle, " enrvähnt.", " erwähnt.")
    'Vorwurf
    textstelle = Replace(textstelle, " Vonryurf ", " Vorwurf ")
    textstelle = Replace(textstelle, " Vonryurf,", " Vorwurf,")
    textstelle = Replace(textstelle, " Vonryurf.", " Vorwurf.")
    'Vorwurf
    textstelle = Replace(textstelle, " Vonrvurf ", " Vorwurf ")
    textstelle = Replace(textstelle, " Vonrvurf,", " Vorwurf,")
    textstelle = Replace(textstelle, " Vonrvurf.", " Vorwurf.")
    'Ihrer
    textstelle = Replace(textstelle, " lhrer ", " Ihrer ")
    textstelle = Replace(textstelle, " lhrer,", " Ihrer,")
    textstelle = Replace(textstelle, " lhrer.", " Ihrer.")
    'Ihren
    textstelle = Replace(textstelle, " lhren ", " Ihren ")
    textstelle = Replace(textstelle, " lhren,", " Ihren,")
    textstelle = Replace(textstelle, " lhren.", " Ihren.")
    'normalerweise
    textstelle = Replace(textstelle, " normalenrveise ", " normalerweise ")
    textstelle = Replace(textstelle, " normalenrveise,", " normalerweise,")
    textstelle = Replace(textstelle, " normalenrveise.", " normalerweise.")
    'International
    textstelle = Replace(textstelle, " lnternational ", " International ")
    textstelle = Replace(textstelle, " lnternational,", " International,")
    textstelle = Replace(textstelle, " lnternational.", " International.")
    'Ingenieur
    textstelle = Replace(textstelle, " lngenieur ", " Ingenieur ")
    textstelle = Replace(textstelle, " lngenieur,", " Ingenieur,")
    textstelle = Replace(textstelle, " lngenieur.", " Ingenieur.")
    'Ingenieure
    textstelle = Replace(textstelle, " lngenieure ", " Ingenieure ")
    textstelle = Replace(textstelle, " lngenieure,", " Ingenieure,")
    textstelle = Replace(textstelle, " lngenieure.", " Ingenieure.")
    'Ingenieuren
    textstelle = Replace(textstelle, " lngenieuren ", " Ingenieuren ")
    textstelle = Replace(textstelle, " lngenieuren,", " Ingenieuren,")
    textstelle = Replace(textstelle, " lngenieuren.", " Ingenieuren.")
    'Investition
    textstelle = Replace(textstelle, " lnvestition ", " Investition ")
    textstelle = Replace(textstelle, " lnvestition,", " Investition,")
    textstelle = Replace(textstelle, " lnvestition.", " Investition.")
    'Investitionen
    textstelle = Replace(textstelle, " lnvestitionen ", " Investitionen ")
    textstelle = Replace(textstelle, " lnvestitionen,", " Investitionen,")
    textstelle = Replace(textstelle, " lnvestitionen.", " Investitionen.")
    'Indien
    textstelle = Replace(textstelle, " lndien ", " Indien ")
    textstelle = Replace(textstelle, " lndien,", " Indien,")
    textstelle = Replace(textstelle, " lndien.", " Indien.")
    'ltalien
    textstelle = Replace(textstelle, " ltalien ", " Italien ")
    textstelle = Replace(textstelle, " ltalien,", " Italien,")
    textstelle = Replace(textstelle, " ltalien.", " Italien.")
    'erwarteten
    textstelle = Replace(textstelle, " enrvarteten ", " erwarteten ")
    textstelle = Replace(textstelle, " enrvarteten,", " erwarteten,")
    textstelle = Replace(textstelle, " enrvarteten.", " erwarteten.")
    'erwartet
    textstelle = Replace(textstelle, " enrvartet ", " erwartet ")
    textstelle = Replace(textstelle, " enrvartet,", " erwartet,")
    textstelle = Replace(textstelle, " enrvartet.", " erwartet.")
    'Investor
    textstelle = Replace(textstelle, " lnvestor ", " Investor ")
    textstelle = Replace(textstelle, " lnvestor,", " Investor,")
    textstelle = Replace(textstelle, " lnvestor.", " Investor.")
    'Investoren
    textstelle = Replace(textstelle, " lnvestoren ", " Investoren ")
    textstelle = Replace(textstelle, " lnvestoren,", " Investoren,")
    textstelle = Replace(textstelle, " lnvestoren.", " Investoren.")
    'Inhaberaktien
    textstelle = Replace(textstelle, " lnhaberaktien ", " Inhaberaktien ")
    textstelle = Replace(textstelle, " lnhaberaktien,", " Inhaberaktien,")
    textstelle = Replace(textstelle, " lnhaberaktien.", " Inhaberaktien.")
    'Igor
    textstelle = Replace(textstelle, " lgor ", " Igor ")
    textstelle = Replace(textstelle, " lgor,", " Igor,")
    textstelle = Replace(textstelle, " lgor.", " Igor.")
    'Interessent
    textstelle = Replace(textstelle, " lnteressent ", " Interessent ")
    textstelle = Replace(textstelle, " lnteressent,", " Interessent,")
    textstelle = Replace(textstelle, " lnteressent.", " Interessent.")
    'Interessenten
    textstelle = Replace(textstelle, " lnteressenten ", " Interessenten ")
    textstelle = Replace(textstelle, " lnteressenten,", " Interessenten,")
    textstelle = Replace(textstelle, " lnteressenten.", " Interessenten.")
    'Inhalte
    textstelle = Replace(textstelle, " lnhalte ", " Inhalte ")
    textstelle = Replace(textstelle, " lnhalte,", " Inhalte,")
    textstelle = Replace(textstelle, " lnhalte.", " Inhalte.")
    'Industrie
    textstelle = Replace(textstelle, " lndustrie ", " Industrie ")
    textstelle = Replace(textstelle, " lndustrie,", " Industrie,")
    textstelle = Replace(textstelle, " lndustrie.", " Industrie.")
    'Investment
    textstelle = Replace(textstelle, " lnvestment ", " Investment ")
    textstelle = Replace(textstelle, " lnvestment,", " Investment,")
    textstelle = Replace(textstelle, " lnvestment.", " Investment.")
    'Investments
    textstelle = Replace(textstelle, " lnvestments ", " Investments ")
    textstelle = Replace(textstelle, " lnvestments,", " Investments,")
    textstelle = Replace(textstelle, " lnvestments.", " Investments.")
    'Ihre
    textstelle = Replace(textstelle, " lhre ", " Ihre ")
    textstelle = Replace(textstelle, " lhre,", " Ihre,")
    textstelle = Replace(textstelle, " lhre.", " Ihre.")
    'Ihr
    textstelle = Replace(textstelle, " lhr ", " Ihr ")
    textstelle = Replace(textstelle, " lhr,", " Ihr,")
    textstelle = Replace(textstelle, " lhr.", " Ihr.")
    'Ihrem
    textstelle = Replace(textstelle, " lhrem ", " Ihrem ")
    textstelle = Replace(textstelle, " lhrem,", " Ihrem,")
    textstelle = Replace(textstelle, " lhrem.", " Ihrem.")
    'Ihres
    textstelle = Replace(textstelle, " lhres ", " Ihres ")
    textstelle = Replace(textstelle, " lhres,", " Ihres,")
    textstelle = Replace(textstelle, " lhres.", " Ihres.")
    'Anrufe
    textstelle = Replace(textstelle, " Arwfe ", " Anrufe ")
    textstelle = Replace(textstelle, " Arwfe,", " Anrufe,")
    textstelle = Replace(textstelle, " Arwfe.", " Anrufe.")
    'Inventar
    textstelle = Replace(textstelle, " lnventar ", " Inventar ")
    textstelle = Replace(textstelle, " lnventar,", " Inventar,")
    textstelle = Replace(textstelle, " lnventar.", " Inventar.")
    'In
    textstelle = Replace(textstelle, " ln ", " In ")

    
    RegelmaessigeOCRFehlerErsetzung = textstelle

End Function


Private Function PronomenErsetzungMaennlich(textstelle As String) As String

    'Drittpersonen müssen zuerst ersetzt werden, sonst wird die Ersetzung von der Erst- auf die Dritttperson erneut übersetzt
    'er
    textstelle = Replace(textstelle, " er ", " dieser ")
    textstelle = Replace(textstelle, " er, ", " dieser, ")
    textstelle = Replace(textstelle, " er. ", " dieser. ")
    textstelle = Replace(textstelle, "Er ", "Dieser ")
    'ihn
    textstelle = Replace(textstelle, " ihn ", " diesen ")
    textstelle = Replace(textstelle, " ihn, ", " diesen, ")
    textstelle = Replace(textstelle, " ihn. ", " diesen. ")
    'ihm
    textstelle = Replace(textstelle, " ihm ", " diesem ")
    textstelle = Replace(textstelle, " ihm, ", " diesem, ")
    textstelle = Replace(textstelle, " ihm. ", " diesem. ")
    'sie
    textstelle = Replace(textstelle, " sie ", " diese ")
    textstelle = Replace(textstelle, " sie, ", " diese, ")
    textstelle = Replace(textstelle, " sie. ", " diese. ")
    textstelle = Replace(textstelle, "Sie ", "Diese ")

    'Ich
    textstelle = Replace(textstelle, " ich ", " er ")
    textstelle = Replace(textstelle, " ich, ", " er, ")
    textstelle = Replace(textstelle, " ich. ", " er. ")
    textstelle = Replace(textstelle, "Ich ", "Er ")
    'lch (Ich falsch geschrieben)
    textstelle = Replace(textstelle, "lch ", "Er ")
    
    'mein
    textstelle = Replace(textstelle, " mein ", " sein ")
    textstelle = Replace(textstelle, " mein, ", " sein, ")
    textstelle = Replace(textstelle, " mein. ", " sein. ")
    textstelle = Replace(textstelle, "Mein ", "Sein ")
    'meine
    textstelle = Replace(textstelle, " meine ", " seine ")
    textstelle = Replace(textstelle, " meine, ", " seine, ")
    textstelle = Replace(textstelle, " meine. ", " seine. ")
    textstelle = Replace(textstelle, "Meine ", "Seine ")
    'meinen
    textstelle = Replace(textstelle, " meinen ", " seinen ")
    textstelle = Replace(textstelle, " meinen, ", " seinen, ")
    textstelle = Replace(textstelle, " meinen. ", " seinen. ")
    textstelle = Replace(textstelle, "Meinen ", "Seinen ")
    'meinem
    textstelle = Replace(textstelle, " meinem ", " seinem ")
    textstelle = Replace(textstelle, " meinem, ", " seinem, ")
    textstelle = Replace(textstelle, " meinem. ", " seinem. ")
    textstelle = Replace(textstelle, "Meinenm ", "Seinem ")
    'meiner
    textstelle = Replace(textstelle, " meiner ", " seiner ")
    textstelle = Replace(textstelle, " meiner, ", " seiner, ")
    textstelle = Replace(textstelle, " meiner. ", " seiner. ")
    textstelle = Replace(textstelle, "Meiner ", "Seiner ")
    'meiner
    textstelle = Replace(textstelle, " meinerseits ", " seinerseits ")
    textstelle = Replace(textstelle, " meinerseits, ", " seinerseits, ")
    textstelle = Replace(textstelle, " meinerseits. ", " seinerseits. ")
    textstelle = Replace(textstelle, "Meinerseits ", "Seinerseits ")
    'meines
    textstelle = Replace(textstelle, " meines ", " seines ")
    textstelle = Replace(textstelle, " meines, ", " seines, ")
    textstelle = Replace(textstelle, " meines. ", " seines. ")
    textstelle = Replace(textstelle, "Meines ", "Seines ")
    'mich
    textstelle = Replace(textstelle, " mich ", " ihn/sich ")
    textstelle = Replace(textstelle, " mich, ", " ihn/sich, ")
    textstelle = Replace(textstelle, " mich. ", " ihn/sich. ")
    textstelle = Replace(textstelle, "Mich ", "Ihn/Sich ")
    'mir
    textstelle = Replace(textstelle, " mir ", " ihm ")
    textstelle = Replace(textstelle, " mir, ", " ihm, ")
    textstelle = Replace(textstelle, " mir. ", " ihm. ")
    textstelle = Replace(textstelle, "Mir ", "Ihm ")
    'wir
    textstelle = Replace(textstelle, " wir ", " sie ")
    textstelle = Replace(textstelle, " wir, ", " sie, ")
    textstelle = Replace(textstelle, " wir. ", " sie. ")
    textstelle = Replace(textstelle, "Wir ", "Sie ")
    'unser
    textstelle = Replace(textstelle, " unser ", " ihr ")
    textstelle = Replace(textstelle, " unser, ", " ihr, ")
    textstelle = Replace(textstelle, " unser. ", " ihr. ")
    'unsere
    textstelle = Replace(textstelle, " unsere ", " ihre ")
    textstelle = Replace(textstelle, " unsere, ", " ihre, ")
    textstelle = Replace(textstelle, " unsere. ", " ihre. ")
    'unserem
    textstelle = Replace(textstelle, " unserem ", " ihrem ")
    textstelle = Replace(textstelle, " unserem, ", " ihrem, ")
    textstelle = Replace(textstelle, " unserem. ", " ihrem. ")
    'uns (wir haben uns verpflichtet)
    textstelle = Replace(textstelle, " uns ", " sich/ihnen ")
    textstelle = Replace(textstelle, " uns, ", " sich/ihnen, ")
    textstelle = Replace(textstelle, " uns. ", " sich/ihnen. ")
    textstelle = Replace(textstelle, "Uns ", "Sich/Ihnen ")
    
    'Das Returnstatment funktioniert inden man den Namen der Funktion mit dem Return gleichsetzt
    PronomenErsetzungMaennlich = textstelle
    
End Function

Private Function PronomenErsetzungFuerFrageMaennlich(textstelle As String) As String
' Ersetzt die förmliche Anrede "Sie" in "er" und "Ihr" in "sein"

    'Sie
    textstelle = Replace(textstelle, " Sie ", " er ")
    textstelle = Replace(textstelle, "Sie ", "Er ")
    textstelle = Replace(textstelle, " Sie, ", " er, ")
    textstelle = Replace(textstelle, " Sie. ", " er. ")
    'sie
    textstelle = Replace(textstelle, " sie ", " er ")
    textstelle = Replace(textstelle, " sie, ", " er, ")
    textstelle = Replace(textstelle, " sie. ", " er. ")
    
    'Ihr
    textstelle = Replace(textstelle, " Ihr ", " sein ")
    textstelle = Replace(textstelle, " Ihr, ", " sein, ")
    textstelle = Replace(textstelle, " Ihr. ", " sein. ")
    textstelle = Replace(textstelle, "Ihr ", "Sein ")
    'ihr
    textstelle = Replace(textstelle, " ihr ", " sein ")
    textstelle = Replace(textstelle, " ihr, ", " sein, ")
    textstelle = Replace(textstelle, " ihr. ", " sein. ")
    'Ihre
    textstelle = Replace(textstelle, " Ihre ", " seine ")
    textstelle = Replace(textstelle, " Ihre, ", " seine, ")
    textstelle = Replace(textstelle, " Ihre. ", " seine. ")
    textstelle = Replace(textstelle, "Ihre ", "Seine ")
    'Ihrer
    textstelle = Replace(textstelle, " Ihrer ", " seiner ")
    textstelle = Replace(textstelle, " Ihrer, ", " seiner, ")
    textstelle = Replace(textstelle, " Ihrre. ", " seiner. ")
    textstelle = Replace(textstelle, "Ihrer ", "Seiner ")
    'Ihrem
    textstelle = Replace(textstelle, " Ihrem ", " seinem ")
    textstelle = Replace(textstelle, " Ihrem, ", " seinem, ")
    textstelle = Replace(textstelle, " Ihrem. ", " seinem. ")
    textstelle = Replace(textstelle, "Ihrem ", "Seinem ")
    'Ihren
    textstelle = Replace(textstelle, " Ihren ", " seinen ")
    textstelle = Replace(textstelle, " Ihren, ", " seinen, ")
    textstelle = Replace(textstelle, " Ihren. ", " seinen. ")
    textstelle = Replace(textstelle, "Ihren ", "Seinen ")
    'ihren
    textstelle = Replace(textstelle, " ihren ", " ihren ")
    textstelle = Replace(textstelle, " ihren, ", " ihren, ")
    textstelle = Replace(textstelle, " ihren. ", " ihren. ")
    'Ihnen
    textstelle = Replace(textstelle, " Ihnen ", " ihm ")
    textstelle = Replace(textstelle, " Ihnen, ", " ihm, ")
    textstelle = Replace(textstelle, " Ihnen. ", " ihm. ")
    textstelle = Replace(textstelle, "Ihnen ", "Ihm ")
    'ihnen
    textstelle = Replace(textstelle, " ihnen ", " ihm ")
    textstelle = Replace(textstelle, " ihnen, ", " ihm, ")
    textstelle = Replace(textstelle, " ihnen. ", " ihm. ")
    
    'wir
    textstelle = Replace(textstelle, " wir ", " man ")
    textstelle = Replace(textstelle, " wir, ", " man, ")
    textstelle = Replace(textstelle, " wir. ", " man. ")
    textstelle = Replace(textstelle, "Wir ", "man ")
    'ich
    textstelle = Replace(textstelle, " ich ", " man ")
    textstelle = Replace(textstelle, " ich, ", " man, ")
    textstelle = Replace(textstelle, " ich. ", " man. ")
    textstelle = Replace(textstelle, "Ich ", "man ")
    
    
    'Das Returnstatment funktioniert inden man den Namen der Funktion mit dem Return gleichsetzt
    PronomenErsetzungFuerFrageMaennlich = textstelle
    
End Function

Private Function PronomenErsetzungFuerFrageWeiblich(textstelle As String) As String
' Ersetzt die förmliche Anrede "Sie" in "er" und "Ihr" in "sein"

    'Sie
    textstelle = Replace(textstelle, " Sie ", " sie ")
    textstelle = Replace(textstelle, "Sie ", "Sie ")
    textstelle = Replace(textstelle, " Sie, ", " sie, ")
    textstelle = Replace(textstelle, " Sie. ", " sie. ")
    'sie
    textstelle = Replace(textstelle, " sie ", " sie ")
    textstelle = Replace(textstelle, " sie, ", " sie, ")
    textstelle = Replace(textstelle, " sie. ", " sie. ")
    
    'Ihr
    textstelle = Replace(textstelle, " Ihr ", " ihr ")
    textstelle = Replace(textstelle, " Ihr, ", " ihr, ")
    textstelle = Replace(textstelle, " Ihr. ", " ihr. ")
    textstelle = Replace(textstelle, "Ihr ", "Ihr ")
    'Ihr
    textstelle = Replace(textstelle, " Ihre ", " ihre ")
    textstelle = Replace(textstelle, " Ihre, ", " ihre, ")
    textstelle = Replace(textstelle, " Ihre. ", " ihre. ")
    textstelle = Replace(textstelle, "Ihre ", "Ihre ")
    'Ihren
    textstelle = Replace(textstelle, " Ihrer ", " ihrer ")
    textstelle = Replace(textstelle, " Ihrer, ", " ihrer, ")
    textstelle = Replace(textstelle, " Ihrer. ", " ihrer. ")
    textstelle = Replace(textstelle, "Ihrer ", "Ihrer ")
    'Ihren
    textstelle = Replace(textstelle, " Ihren ", " ihren ")
    textstelle = Replace(textstelle, " Ihren, ", " ihren, ")
    textstelle = Replace(textstelle, " Ihren. ", " ihren. ")
    textstelle = Replace(textstelle, "Ihren ", "Ihren ")
    'Ihrem
    textstelle = Replace(textstelle, " Ihrem ", " ihrem ")
    textstelle = Replace(textstelle, " Ihrem, ", " ihrem, ")
    textstelle = Replace(textstelle, " Ihrem. ", " ihrem. ")
    textstelle = Replace(textstelle, "Ihrem ", "Ihrem ")
    'Ihnen
    textstelle = Replace(textstelle, " Ihnen ", " ihr ")
    textstelle = Replace(textstelle, " Ihnen, ", " ihr, ")
    textstelle = Replace(textstelle, " Ihnen. ", " ihr. ")
    textstelle = Replace(textstelle, "Ihnen ", "Ihr ")
    
    'wir
    textstelle = Replace(textstelle, " wir ", " man ")
    textstelle = Replace(textstelle, " wir, ", " man, ")
    textstelle = Replace(textstelle, " wir. ", " man. ")
    textstelle = Replace(textstelle, "Wir ", "man ")
    'ich
    textstelle = Replace(textstelle, " ich ", " man ")
    textstelle = Replace(textstelle, " ich, ", " man, ")
    textstelle = Replace(textstelle, " ich. ", " man. ")
    textstelle = Replace(textstelle, "Ich ", "man ")
    
    'Das Returnstatment funktioniert inden man den Namen der Funktion mit dem Return gleichsetzt
    PronomenErsetzungFuerFrageWeiblich = textstelle
    
End Function

Private Function VerbenkonvertierungMehrzahlEinzahl(textstelle As String) As String
' Wandelt die förmlichen, in Mehrzahl formulierten Verben in Einzahl-Verben um

    'hätten -> habe
    textstelle = Replace(textstelle, " hätten ", " habe ")
    textstelle = Replace(textstelle, "Hätten ", "Habe ")
    textstelle = Replace(textstelle, " hätten, ", " habe, ")
    textstelle = Replace(textstelle, " hätten. ", " habe. ")
    'möchten -> wolle
    textstelle = Replace(textstelle, " möchten ", " wolle ")
    textstelle = Replace(textstelle, "Möchten ", "Wolle ")
    textstelle = Replace(textstelle, " möchten, ", " wolle, ")
    textstelle = Replace(textstelle, " möchten. ", " wolle. ")
    
    'Das Returnstatment funktioniert inden man den Namen der Funktion mit dem Return gleichsetzt
    VerbenkonvertierungMehrzahlEinzahl = textstelle
    
End Function

Private Function PronomenErsetzungWeiblich(textstelle As String) As String
    
    'Drittpersonen müssen zuerst ersetzt werden, sonst wird die Ersetzung von der Erst- auf die Dritttperson erneut übersetzt
    'er
    textstelle = Replace(textstelle, " er ", " dieser ")
    textstelle = Replace(textstelle, " er, ", " dieser, ")
    textstelle = Replace(textstelle, " er. ", " dieser. ")
    textstelle = Replace(textstelle, "Er ", "Dieser ")
    'ihn
    textstelle = Replace(textstelle, " ihn ", " diesen ")
    textstelle = Replace(textstelle, " ihn, ", " diesen, ")
    textstelle = Replace(textstelle, " ihn. ", " diesen. ")
    'ihm
    textstelle = Replace(textstelle, " ihm ", " diesem ")
    textstelle = Replace(textstelle, " ihm, ", " diesem, ")
    textstelle = Replace(textstelle, " ihm. ", " diesem. ")
    'sie
    textstelle = Replace(textstelle, " sie ", " diese ")
    textstelle = Replace(textstelle, " sie, ", " diese, ")
    textstelle = Replace(textstelle, " sie. ", " diese. ")
    textstelle = Replace(textstelle, "Sie ", "Diese ")
    
    'Ich
    textstelle = Replace(textstelle, " ich ", " sie ")
    textstelle = Replace(textstelle, " ich, ", " sie, ")
    textstelle = Replace(textstelle, " ich. ", " sie. ")
    textstelle = Replace(textstelle, "Ich ", "Sie ")
    'lch (Ich falsch geschrieben)
    textstelle = Replace(textstelle, "lch ", "Sie ")
    
    'mein
    textstelle = Replace(textstelle, " mein ", " ihr ")
    textstelle = Replace(textstelle, " mein, ", " ihr, ")
    textstelle = Replace(textstelle, " mein. ", " ihr. ")
    textstelle = Replace(textstelle, "Mein ", "Ihr ")
    'meine
    textstelle = Replace(textstelle, " meine ", " ihre ")
    textstelle = Replace(textstelle, " meine, ", " ihre, ")
    textstelle = Replace(textstelle, " meine. ", " ihre. ")
    textstelle = Replace(textstelle, "Meine ", "Ihre ")
    'meinen
    textstelle = Replace(textstelle, " meinen ", " ihren ")
    textstelle = Replace(textstelle, " meinen, ", " ihren, ")
    textstelle = Replace(textstelle, " meinen. ", " ihren. ")
    textstelle = Replace(textstelle, "Meinen ", "Ihren ")
    'meinem
    textstelle = Replace(textstelle, " meinem ", " ihrem ")
    textstelle = Replace(textstelle, " meinem, ", " ihrem, ")
    textstelle = Replace(textstelle, " meinem. ", " ihrem. ")
    textstelle = Replace(textstelle, "Meinem ", "Ihrem ")
    'meiner
    textstelle = Replace(textstelle, " meiner ", " ihrer ")
    textstelle = Replace(textstelle, " meiner, ", " ihrer, ")
    textstelle = Replace(textstelle, " meiner. ", " ihrer. ")
    textstelle = Replace(textstelle, "Meiner ", "Ihrer ")
    'meiner
    textstelle = Replace(textstelle, " meinerseits ", " ihrerseits ")
    textstelle = Replace(textstelle, " meinerseits, ", " ihrerseits, ")
    textstelle = Replace(textstelle, " meinerseits. ", " ihrerseits. ")
    textstelle = Replace(textstelle, "Meinerseits ", "Ihrerseits ")
    'meines
    textstelle = Replace(textstelle, " meines ", " ihres ")
    textstelle = Replace(textstelle, " meines, ", " ihres, ")
    textstelle = Replace(textstelle, " meines. ", " ihres. ")
    textstelle = Replace(textstelle, "Meines ", "Ihres ")
    'mich
    textstelle = Replace(textstelle, " mich ", " sie/sich ")
    textstelle = Replace(textstelle, " mich, ", " sie/sich, ")
    textstelle = Replace(textstelle, " mich. ", " sie/sich. ")
    textstelle = Replace(textstelle, "Mich ", "Sie/Sich ")
    'mir
    textstelle = Replace(textstelle, " mir ", " ihr ")
    textstelle = Replace(textstelle, " mir, ", " ihr, ")
    textstelle = Replace(textstelle, " mir. ", " ihr. ")
    textstelle = Replace(textstelle, "Mir ", "Ihr ")
    'wir
    textstelle = Replace(textstelle, " wir ", " sie ")
    textstelle = Replace(textstelle, " wir, ", " sie, ")
    textstelle = Replace(textstelle, " wir. ", " sie. ")
    textstelle = Replace(textstelle, "Wir ", "Sie ")
    'unser
    textstelle = Replace(textstelle, " unser ", " ihr ")
    textstelle = Replace(textstelle, " unser, ", " ihr, ")
    textstelle = Replace(textstelle, " unser. ", " ihr. ")
    'unsere
    textstelle = Replace(textstelle, " unsere ", " ihre ")
    textstelle = Replace(textstelle, " unsere, ", " ihre, ")
    textstelle = Replace(textstelle, " unsere. ", " ihre. ")
    'unserem
    textstelle = Replace(textstelle, " unserem ", " ihrem ")
    textstelle = Replace(textstelle, " unserem, ", " ihrem, ")
    textstelle = Replace(textstelle, " unserem. ", " ihrem. ")
    'uns (wir haben uns verpflichtet)
    textstelle = Replace(textstelle, " uns ", " sich/ihnen ")
    textstelle = Replace(textstelle, " uns, ", " sich/ihnen, ")
    textstelle = Replace(textstelle, " uns. ", " sich/ihnen. ")
    textstelle = Replace(textstelle, "Uns ", "Sich/Ihnen ")
    
    
    
    'Das Returnstatment funktioniert inden man den Namen der Funktion mit dem Return gleichsetzt
    PronomenErsetzungWeiblich = textstelle
    
End Function


Private Function VerbenErsetzung(textstelle As String) As String
    'Er/sie hat
    textstelle = Replace(textstelle, " hat ", " habe ")
    textstelle = Replace(textstelle, " hat,", " habe,")
    textstelle = Replace(textstelle, " hat.", " habe.")
    'Er/sie ist
    textstelle = Replace(textstelle, " ist ", " sei ")
    textstelle = Replace(textstelle, " ist,", " sei,")
    textstelle = Replace(textstelle, " ist.", " sei.")
    'Er/sie soll
    textstelle = Replace(textstelle, " soll ", " solle ")
    textstelle = Replace(textstelle, " soll,", " solle,")
    textstelle = Replace(textstelle, " soll.", " solle.")
    'Er/sie kann
    textstelle = Replace(textstelle, " kann ", " könne ")
    textstelle = Replace(textstelle, " kann,", " könne,")
    textstelle = Replace(textstelle, " kann.", " könne.")
    'Er/sie hatte
    textstelle = Replace(textstelle, " hatte ", " habe ")
    textstelle = Replace(textstelle, " hatte,", " habe,")
    textstelle = Replace(textstelle, " hatte.", " habe.")
    'Er/sie weiss
    textstelle = Replace(textstelle, " weiss ", " wisse ")
    textstelle = Replace(textstelle, " weiss,", " wisse,")
    textstelle = Replace(textstelle, " weiss.", " wisse.")
    'Er/sie darf
    textstelle = Replace(textstelle, " darf ", " dürfe ")
    textstelle = Replace(textstelle, " darf,", " dürfe,")
    textstelle = Replace(textstelle, " darf.", " dürfe.")
    'Er/sie heisst
    textstelle = Replace(textstelle, " heisst ", " heisse ")
    textstelle = Replace(textstelle, " heisst,", " heisse,")
    textstelle = Replace(textstelle, " heisst.", " heisse.")
    'Er/sie trifft
    textstelle = Replace(textstelle, " trifft ", " treffe ")
    textstelle = Replace(textstelle, " trifft,", " treffe,")
    textstelle = Replace(textstelle, " trifft.", " treffe.")
    'Er/sie glaubt
    textstelle = Replace(textstelle, " glaubt ", " glaube ")
    textstelle = Replace(textstelle, " glaubt,", " glaube,")
    textstelle = Replace(textstelle, " glaubt.", " glaube.")
    'Er/sie schenkt
    textstelle = Replace(textstelle, " schenkt ", " schenke ")
    textstelle = Replace(textstelle, " schenkt,", " schenke,")
    textstelle = Replace(textstelle, " schenkt.", " schenke.")
    'Er/sie braucht
    textstelle = Replace(textstelle, " braucht ", " brauche ")
    textstelle = Replace(textstelle, " braucht,", " brauche,")
    textstelle = Replace(textstelle, " braucht.", " brauche.")
    'Er/sie kauft
    textstelle = Replace(textstelle, " kauft ", " kaufe ")
    textstelle = Replace(textstelle, " kauft,", " kaufe,")
    textstelle = Replace(textstelle, " kauft.", " kaufe.")
    'Er/sie will
    textstelle = Replace(textstelle, " will ", " wolle ")
    textstelle = Replace(textstelle, " will,", " wolle,")
    textstelle = Replace(textstelle, " will.", " wolle.")
    'Er/sie kennt
    textstelle = Replace(textstelle, " kennt ", " kenne ")
    textstelle = Replace(textstelle, " kennt,", " kenne,")
    textstelle = Replace(textstelle, " kennt.", " kenne.")
    'Er/sie lebt
    textstelle = Replace(textstelle, " lebt ", " lebe ")
    textstelle = Replace(textstelle, " lebt,", " lebe,")
    textstelle = Replace(textstelle, " lebt.", " lebe.")
    'Er/sie übergibt
    textstelle = Replace(textstelle, " übergibt ", " übergebe ")
    textstelle = Replace(textstelle, " übergibt,", " übergebe,")
    textstelle = Replace(textstelle, " übergibt.", " übergebe.")
    'Er/sie tauscht
    textstelle = Replace(textstelle, " tauscht ", " tausche ")
    textstelle = Replace(textstelle, " tauscht,", " tausche,")
    textstelle = Replace(textstelle, " tauscht.", " tausche.")
    'Er/sie spielt
    textstelle = Replace(textstelle, " spielt ", " spiele ")
    textstelle = Replace(textstelle, " spielt,", " spiele,")
    textstelle = Replace(textstelle, " spielt.", " spiele.")
    'Er/sie fühle
    textstelle = Replace(textstelle, " fühlt ", " fühle ")
    textstelle = Replace(textstelle, " fühlt,", " fühle,")
    textstelle = Replace(textstelle, " fühlt.", " fühle.")
    'Er/sie hilft
    textstelle = Replace(textstelle, " hilft ", " helfe ")
    textstelle = Replace(textstelle, " hilft,", " helfe,")
    textstelle = Replace(textstelle, " hilft.", " helfe.")
    'Er/sie schaut
    textstelle = Replace(textstelle, " schaut ", " schaue ")
    textstelle = Replace(textstelle, " schaut,", " schaue,")
    textstelle = Replace(textstelle, " schaut.", " schaue.")
    'Er/sie denkt
    textstelle = Replace(textstelle, " denkt ", " denke ")
    textstelle = Replace(textstelle, " denkt,", " denke,")
    textstelle = Replace(textstelle, " denkt.", " denke.")
    'Er/sie bringt
    textstelle = Replace(textstelle, " bringt ", " bringe ")
    textstelle = Replace(textstelle, " bringt,", " bringe,")
    textstelle = Replace(textstelle, " bringt.", " bringe.")
    'Er/sie bemerkt
    textstelle = Replace(textstelle, " bemerkt ", " bemerke ")
    textstelle = Replace(textstelle, " bemerkt,", " bemerke,")
    textstelle = Replace(textstelle, " bemerkt.", " bemerke.")
    'Er/sie benötigt
    textstelle = Replace(textstelle, " benötigt ", " benötige ")
    textstelle = Replace(textstelle, " benötigt,", " benötige,")
    textstelle = Replace(textstelle, " benötigt.", " benötige.")
    'Er/sie verfügt
    textstelle = Replace(textstelle, " verfügt ", " verfüge ")
    textstelle = Replace(textstelle, " verfügt,", " verfüge,")
    textstelle = Replace(textstelle, " verfügt.", " verfüge.")
    'Er/sie verdient
    textstelle = Replace(textstelle, " verdient ", " verdiene ")
    textstelle = Replace(textstelle, " verdient,", " verdiene,")
    textstelle = Replace(textstelle, " verdient.", " verdiene.")
    'Er/sie möchte
    textstelle = Replace(textstelle, " möchte ", " wolle ")
    textstelle = Replace(textstelle, " möchte,", " wolle,")
    textstelle = Replace(textstelle, " möchte.", " wolle.")
    'Sie/er sagt
    textstelle = Replace(textstelle, " sagt ", " sage ")
    textstelle = Replace(textstelle, " sagt,", " sage,")
    textstelle = Replace(textstelle, " sagt.", " sage.")
    'Sie/er wohnt
    textstelle = Replace(textstelle, " wohnt ", " wohne ")
    textstelle = Replace(textstelle, " wohnt,", " wohne,")
    textstelle = Replace(textstelle, " wohnt.", " wohne.")
    'Sie/er besitzt
    textstelle = Replace(textstelle, " besitzt ", " besitze ")
    textstelle = Replace(textstelle, " besitzt,", " besitze,")
    textstelle = Replace(textstelle, " besitzt.", " besitze.")
    'Sie/er fällt
    textstelle = Replace(textstelle, " fällt ", " falle ")
    textstelle = Replace(textstelle, " fällt,", " falle,")
    textstelle = Replace(textstelle, " fällt.", " falle.")
    'Sie/er verlange
    textstelle = Replace(textstelle, " verlange ", " verlangte ")
    textstelle = Replace(textstelle, " verlange,", " verlangte,")
    textstelle = Replace(textstelle, " verlange.", " verlangte.")
    'Sie/er lauft
    textstelle = Replace(textstelle, " lauft ", " laufe ")
    textstelle = Replace(textstelle, " lauft,", " laufe,")
    textstelle = Replace(textstelle, " lauft.", " laufe.")
    'Sie/er durchsucht
    textstelle = Replace(textstelle, " durchsucht ", " durchsuche ")
    textstelle = Replace(textstelle, " durchsucht,", " durchsuche,")
    textstelle = Replace(textstelle, " durchsucht.", " durchsuche.")
    'Sie/er arbeitet
    textstelle = Replace(textstelle, " arbeitet ", " arbeite ")
    textstelle = Replace(textstelle, " arbeitet,", " arbeite,")
    textstelle = Replace(textstelle, " arbeitet.", " arbeite.")
    'Sie/er nimmt
    textstelle = Replace(textstelle, " nimmt ", " nehme ")
    textstelle = Replace(textstelle, " nimmt,", " nehme,")
    textstelle = Replace(textstelle, " nimmt.", " nehme.")
    'Sie/er vermutet
    textstelle = Replace(textstelle, " vermutet ", " vermute ")
    textstelle = Replace(textstelle, " vermutet,", " vermute,")
    textstelle = Replace(textstelle, " vermutet.", " vermute.")
    'Sie/er stamme
    textstelle = Replace(textstelle, " stamme ", " stammte ")
    textstelle = Replace(textstelle, " stamme,", " stammte,")
    textstelle = Replace(textstelle, " stamme.", " stammte.")
    'Sie/er belastet
    textstelle = Replace(textstelle, " belastet ", " belaste ")
    textstelle = Replace(textstelle, " belastet,", " belaste,")
    textstelle = Replace(textstelle, " belastet.", " belaste.")
    'Sie/er holt
    textstelle = Replace(textstelle, " holt ", " hole ")
    textstelle = Replace(textstelle, " holt,", " hole,")
    textstelle = Replace(textstelle, " holt.", " hole.")
    'Sie/er täuscht
    textstelle = Replace(textstelle, " täuscht ", " täusche ")
    textstelle = Replace(textstelle, " täuscht,", " täusche,")
    textstelle = Replace(textstelle, " täuscht.", " täusche.")
    'Sie/er verliert
    textstelle = Replace(textstelle, " verliert ", " verliere ")
    textstelle = Replace(textstelle, " verliert,", " verliere,")
    textstelle = Replace(textstelle, " verliert.", " verliere.")
    'Sie/er zielt
    textstelle = Replace(textstelle, " zielt ", " ziele ")
    textstelle = Replace(textstelle, " zielt,", " ziele,")
    textstelle = Replace(textstelle, " zielt.", " ziele.")
    'Sie/er erhält
    textstelle = Replace(textstelle, " erhält ", " erhalte ")
    textstelle = Replace(textstelle, " erhält,", " erhalte,")
    textstelle = Replace(textstelle, " erhält.", " erhalte.")
    'Sie/er erhält
    textstelle = Replace(textstelle, " interessiert ", " interessiere ")
    textstelle = Replace(textstelle, " interessiert,", " interessiere,")
    textstelle = Replace(textstelle, " interessiert.", " interessiere.")
    'Sie/er steigt
    textstelle = Replace(textstelle, " steigt ", " steige ")
    textstelle = Replace(textstelle, " steigt,", " steige,")
    textstelle = Replace(textstelle, " steigt.", " steige.")
    'Sie/er schaut
    textstelle = Replace(textstelle, " schaut ", " schaue ")
    textstelle = Replace(textstelle, " schaut,", " schaue,")
    textstelle = Replace(textstelle, " schaut.", " schaue.")
    'Sie/er übernimmt
    textstelle = Replace(textstelle, " übernimmt ", " übernehme ")
    textstelle = Replace(textstelle, " übernimmt,", " übernehme,")
    textstelle = Replace(textstelle, " übernimmt.", " übernehme.")
    'Sie/er bewertet
    textstelle = Replace(textstelle, " bewertet ", " bewerte ")
    textstelle = Replace(textstelle, " bewertet,", " bewerte,")
    textstelle = Replace(textstelle, " bewertet.", " bewerte.")
    'Sie/er betrachtet
    textstelle = Replace(textstelle, " betrachtet ", " betrachte ")
    textstelle = Replace(textstelle, " betrachtet,", " betrachte,")
    textstelle = Replace(textstelle, " betrachtet.", " betrachte.")
    'Sie/er tätigt
    textstelle = Replace(textstelle, " tätigt ", " tätige ")
    textstelle = Replace(textstelle, " tätigt,", " tätige,")
    textstelle = Replace(textstelle, " tätigt.", " tätige.")
    'Sie/er wirft
    textstelle = Replace(textstelle, " wirft ", " werfe ")
    textstelle = Replace(textstelle, " wirft,", " werfe,")
    textstelle = Replace(textstelle, " wirft.", " werfe.")
    'Sie/er reagiert
    textstelle = Replace(textstelle, " reagiert ", " reagiere ")
    textstelle = Replace(textstelle, " reagiert,", " reagiere,")
    textstelle = Replace(textstelle, " reagiert.", " reagiere.")
    'Sie/er erzielt
    textstelle = Replace(textstelle, " erzielt ", " erziele ")
    textstelle = Replace(textstelle, " erzielt,", " erziele,")
    textstelle = Replace(textstelle, " erzielt.", " erziele.")
    'Sie/er zahlt
    textstelle = Replace(textstelle, " zahlt ", " zahle ")
    textstelle = Replace(textstelle, " zahlt,", " zahle,")
    textstelle = Replace(textstelle, " zahlt.", " zahle.")
    'Sie/er generiert
    textstelle = Replace(textstelle, " generiert ", " generiere ")
    textstelle = Replace(textstelle, " generiert,", " generiere,")
    textstelle = Replace(textstelle, " generiert.", " generiere.")
    'Sie/er öffnet
    textstelle = Replace(textstelle, " öffnet ", " öffne ")
    textstelle = Replace(textstelle, " öffnet,", " öffne,")
    textstelle = Replace(textstelle, " öffnet.", " öffne.")
    'Sie/er sucht
    textstelle = Replace(textstelle, " sucht ", " suche ")
    textstelle = Replace(textstelle, " sucht,", " suche,")
    textstelle = Replace(textstelle, " sucht.", " suche.")
    'Sie/er trägt
    textstelle = Replace(textstelle, " trägt ", " trage ")
    textstelle = Replace(textstelle, " trägt,", " trage,")
    textstelle = Replace(textstelle, " trägt.", " trage.")
    'Sie/er lenkte
    textstelle = Replace(textstelle, " lenkt ", " lenke ")
    textstelle = Replace(textstelle, " lenkt,", " lenke,")
    textstelle = Replace(textstelle, " lenkt.", " lenke.")
    'Sie/er führt
    textstelle = Replace(textstelle, " führt ", " führe ")
    textstelle = Replace(textstelle, " führt,", " führe,")
    textstelle = Replace(textstelle, " führt.", " führe.")
    'Sie/er erbringt
    textstelle = Replace(textstelle, " erbringt ", " erbringe ")
    textstelle = Replace(textstelle, " erbringt,", " erbringe,")
    textstelle = Replace(textstelle, " erbringt.", " erbringe.")
    'Sie/er hält
    textstelle = Replace(textstelle, " hält ", " halte ")
    textstelle = Replace(textstelle, " hält,", " halte,")
    textstelle = Replace(textstelle, " hält.", " halte.")
    'Sie/er vertreibt
    textstelle = Replace(textstelle, " vertreibt ", " vertreibe ")
    textstelle = Replace(textstelle, " vertreibt,", " vertreibe,")
    textstelle = Replace(textstelle, " vertreibt.", " vertreibe.")
    'Sie/er vermag
    textstelle = Replace(textstelle, " vermag ", " vermöge ")
    textstelle = Replace(textstelle, " vermag,", " vermöge,")
    textstelle = Replace(textstelle, " vermag.", " vermöge.")
    'Sie/er übt
    textstelle = Replace(textstelle, " übt ", " übe ")
    textstelle = Replace(textstelle, " übt,", " übe,")
    textstelle = Replace(textstelle, " übt.", " übe.")
    'Sie/er entwickelt
    textstelle = Replace(textstelle, " entwickelt ", " entwickle ")
    textstelle = Replace(textstelle, " entwickelt,", " entwickle,")
    textstelle = Replace(textstelle, " entwickelt.", " entwickle.")
    'Sie/er sitzt
    textstelle = Replace(textstelle, " sitzt ", " sitze ")
    textstelle = Replace(textstelle, " sitzt,", " sitze,")
    textstelle = Replace(textstelle, " sitzt.", " sitze.")
    'Sie/er berichtet
    textstelle = Replace(textstelle, " berichtet ", " berichte ")
    textstelle = Replace(textstelle, " berichtet,", " berichte,")
    textstelle = Replace(textstelle, " berichtet.", " berichte.")
    'Sie/er versteht
    textstelle = Replace(textstelle, " versteht ", " verstehe ")
    textstelle = Replace(textstelle, " versteht,", " verstehe,")
    textstelle = Replace(textstelle, " versteht.", " verstehe.")
    'Sie/er beauftragt
    textstelle = Replace(textstelle, " beauftragt ", " beauftrage ")
    textstelle = Replace(textstelle, " beauftragt,", " beauftrage,")
    textstelle = Replace(textstelle, " beauftragt.", " beauftrage.")
    'Sie/er verfügt
    textstelle = Replace(textstelle, " verfügt ", " verfüge ")
    textstelle = Replace(textstelle, " verfüge,", " verfüge,")
    textstelle = Replace(textstelle, " verfüge.", " verfüge.")
    'Sie/er geniesst
    textstelle = Replace(textstelle, " geniesst ", " geniesse ")
    textstelle = Replace(textstelle, " geniesst,", " geniesse,")
    textstelle = Replace(textstelle, " geniesst.", " geniesse.")
    'Sie/er bekommt
    textstelle = Replace(textstelle, " bekommt ", " bekomme ")
    textstelle = Replace(textstelle, " bekommt,", " bekomme,")
    textstelle = Replace(textstelle, " bekommt.", " bekomme.")
    
    '(Ich) bin
    textstelle = Replace(textstelle, " bin ", " sei ")
    textstelle = Replace(textstelle, " bin,", " sei,")
    textstelle = Replace(textstelle, " bin.", " sei.")
    'sie haben
    textstelle = Replace(textstelle, " haben ", " hätten ")
    textstelle = Replace(textstelle, " haben,", " hätten,")
    textstelle = Replace(textstelle, " haben.", " hätten.")
    'sie sind
    textstelle = Replace(textstelle, " sind ", " seien ")
    textstelle = Replace(textstelle, " sind,", " seien,")
    textstelle = Replace(textstelle, " sind.", " seien.")
    'sie benötigen
    textstelle = Replace(textstelle, " benötigen ", " benötigten ")
    textstelle = Replace(textstelle, " benötigen,", " benötigten,")
    textstelle = Replace(textstelle, " benötigen.", " benötigten.")
    'sie hatten
    textstelle = Replace(textstelle, " hatten ", " hätten ")
    textstelle = Replace(textstelle, " hatten,", " hätten,")
    textstelle = Replace(textstelle, " hatten.", " hätten.")
    'sie stammen
    textstelle = Replace(textstelle, " stammen ", " stammten ")
    textstelle = Replace(textstelle, " stammen,", " stammten,")
    textstelle = Replace(textstelle, " stammen.", " stammten.")
    'sie vertreiben
    textstelle = Replace(textstelle, " vertreiben ", " vertrieben ")
    textstelle = Replace(textstelle, " vertreiben,", " vertrieben,")
    textstelle = Replace(textstelle, " vertreiben.", " vertrieben.")

    'man muss
    textstelle = Replace(textstelle, " muss ", " müsse ")
    textstelle = Replace(textstelle, " muss,", " müsse,")
    textstelle = Replace(textstelle, " muss.", " müsse.")
    'es wird
    textstelle = Replace(textstelle, " wird ", " werde ")
    textstelle = Replace(textstelle, " wird,", " werde,")
    textstelle = Replace(textstelle, " wird.", " werde.")
    'es gilt
    textstelle = Replace(textstelle, " gilt ", " gelte ")
    textstelle = Replace(textstelle, " gilt,", " gelte,")
    textstelle = Replace(textstelle, " gilt.", " gelte.")
    'es geht
    textstelle = Replace(textstelle, " geht ", " gehe ")
    textstelle = Replace(textstelle, " geht,", " gehe,")
    textstelle = Replace(textstelle, " geht.", " gehe.")
    'es gibt
    textstelle = Replace(textstelle, " gibt ", " gebe ")
    textstelle = Replace(textstelle, " gibt,", " gebe,")
    textstelle = Replace(textstelle, " gibt.", " gebe.")
    'Es steht
    textstelle = Replace(textstelle, " steht ", " stehe ")
    textstelle = Replace(textstelle, " steht,", " stehe,")
    textstelle = Replace(textstelle, " steht.", " stehe.")
    'Es befindet
    textstelle = Replace(textstelle, " befindet ", " befinde ")
    textstelle = Replace(textstelle, " befindet,", " befinde,")
    textstelle = Replace(textstelle, " befindet.", " befinde.")
    'Es kommt
    textstelle = Replace(textstelle, " kommt ", " komme ")
    textstelle = Replace(textstelle, " kommt,", " komme,")
    textstelle = Replace(textstelle, " kommt.", " komme.")
    'Es stellt
    textstelle = Replace(textstelle, " stellt ", " stelle ")
    textstelle = Replace(textstelle, " stellt,", " stelle,")
    textstelle = Replace(textstelle, " stellt.", " stelle.")
    'Es zeigt
    textstelle = Replace(textstelle, " zeigt ", " zeige ")
    textstelle = Replace(textstelle, " zeigt,", " zeige,")
    textstelle = Replace(textstelle, " zeigt.", " zeige.")
    'Es erstreckt
    textstelle = Replace(textstelle, " erstreckt ", " erstrecke ")
    textstelle = Replace(textstelle, " erstreckt,", " erstrecke,")
    textstelle = Replace(textstelle, " erstreckt.", " erstrecke.")
    'Wie es aussieht
    textstelle = Replace(textstelle, " aussieht ", " aussehe ")
    textstelle = Replace(textstelle, " aussieht,", " aussehe,")
    textstelle = Replace(textstelle, " aussieht.", " aussehe.")
    'Es ergibt
    textstelle = Replace(textstelle, " ergibt ", " ergebe ")
    textstelle = Replace(textstelle, " ergibt,", " ergebe,")
    textstelle = Replace(textstelle, " ergibt.", " ergebe.")
    'Es macht
    textstelle = Replace(textstelle, " macht ", " mache ")
    textstelle = Replace(textstelle, " macht,", " mache,")
    textstelle = Replace(textstelle, " macht.", " mache.")
    'Es liegt
    textstelle = Replace(textstelle, " liegt ", " liege ")
    textstelle = Replace(textstelle, " liegt,", " liege,")
    textstelle = Replace(textstelle, " liegt.", " liege.")
    'Es hängt
    textstelle = Replace(textstelle, " hängt ", " hänge ")
    textstelle = Replace(textstelle, " hängt,", " hänge,")
    textstelle = Replace(textstelle, " hängt.", " hänge.")
    'Es bleibt
    textstelle = Replace(textstelle, " bleibt ", " bleibe ")
    textstelle = Replace(textstelle, " bleibt,", " bleibe,")
    textstelle = Replace(textstelle, " bleibt.", " bleibe.")
    'Es stimmt
    textstelle = Replace(textstelle, " stimmt ", " stimme ")
    textstelle = Replace(textstelle, " stimmt,", " stimme,")
    textstelle = Replace(textstelle, " stimmt.", " stimme.")
    'Es lautet
    textstelle = Replace(textstelle, " lautet ", " laute ")
    textstelle = Replace(textstelle, " lautet,", " laute,")
    textstelle = Replace(textstelle, " lautet.", " laute.")
    'Es bezieht
    textstelle = Replace(textstelle, " bezieht ", " beziehe ")
    textstelle = Replace(textstelle, " bezieht,", " beziehe,")
    textstelle = Replace(textstelle, " bezieht.", " beziehe.")
    'Es findet statt (stattfindet)
    textstelle = Replace(textstelle, " stattfindet ", " stattfinde ")
    textstelle = Replace(textstelle, " stattfindet,", " stattfinde,")
    textstelle = Replace(textstelle, " stattfindet.", " stattfinde.")
    'Es findet
    textstelle = Replace(textstelle, " findet ", " finde ")
    textstelle = Replace(textstelle, " findet,", " finde,")
    textstelle = Replace(textstelle, " findet.", " finde.")
    'Es entspricht
    textstelle = Replace(textstelle, " entspricht ", " entspreche ")
    textstelle = Replace(textstelle, " entspricht,", " entspreche,")
    textstelle = Replace(textstelle, " entspricht.", " entspreche.")
    'Sie entsprechen
    textstelle = Replace(textstelle, " entsprechen ", " entsprächen ")
    textstelle = Replace(textstelle, " entsprechen,", " entsprächen,")
    textstelle = Replace(textstelle, " entsprechen.", " entsprächen.")
    'Es handelt
    textstelle = Replace(textstelle, " handelt ", " handle ")
    textstelle = Replace(textstelle, " handelt,", " handle,")
    textstelle = Replace(textstelle, " handelt.", " handle.")
    'Es fehlt
    textstelle = Replace(textstelle, " fehlt ", " fehle ")
    textstelle = Replace(textstelle, " fehlt,", " fehle,")
    textstelle = Replace(textstelle, " fehlt.", " fehle.")
    'Es fehlen
    textstelle = Replace(textstelle, " fehlen ", " fehlten ")
    textstelle = Replace(textstelle, " fehlen,", " fehlten,")
    textstelle = Replace(textstelle, " fehlen.", " fehlten.")
    'Es tut
    textstelle = Replace(textstelle, " tut ", " tue ")
    textstelle = Replace(textstelle, " tut,", " tue,")
    textstelle = Replace(textstelle, " tut.", " tue.")
    'Es besteht
    textstelle = Replace(textstelle, " besteht ", " bestehe ")
    textstelle = Replace(textstelle, " besteht,", " bestehe,")
    textstelle = Replace(textstelle, " besteht.", " bestehe.")
    'Sie gehören
    textstelle = Replace(textstelle, " gehören ", " gehörten ")
    textstelle = Replace(textstelle, " gehören,", " gehörten,")
    textstelle = Replace(textstelle, " gehören.", " gehörten.")
    'Es setzt
    textstelle = Replace(textstelle, " setzt ", " setze ")
    textstelle = Replace(textstelle, " setzt,", " setze,")
    textstelle = Replace(textstelle, " setzt.", " setze.")
    'Es angeht
    textstelle = Replace(textstelle, " angeht ", " angehe ")
    textstelle = Replace(textstelle, " angeht,", " angehe,")
    textstelle = Replace(textstelle, " angeht.", " angehe.")
    'Es sieht
    textstelle = Replace(textstelle, " sieht ", " sehe ")
    textstelle = Replace(textstelle, " sieht,", " sehe,")
    textstelle = Replace(textstelle, " sieht.", " sehe.")
    'Es funktioniert
    textstelle = Replace(textstelle, " funktioniert ", " funktioniere ")
    textstelle = Replace(textstelle, " funktioniert,", " funktioniere,")
    textstelle = Replace(textstelle, " funktioniert.", " funktioniere.")
    'Es anbelangt
    textstelle = Replace(textstelle, " anbelangt ", " anbelange ")
    textstelle = Replace(textstelle, " anbelangt,", " anbelange,")
    textstelle = Replace(textstelle, " anbelangt.", " anbelange.")
    'Es dient
    textstelle = Replace(textstelle, " dient ", " diene ")
    textstelle = Replace(textstelle, " dient,", " diene,")
    textstelle = Replace(textstelle, " dient.", " diene.")
    'Es erwartet
    textstelle = Replace(textstelle, " erwartet ", " erwarte ")
    textstelle = Replace(textstelle, " erwartet,", " erwarte,")
    textstelle = Replace(textstelle, " erwartet.", " erwarte.")
    'Es enthält
    textstelle = Replace(textstelle, " enthält ", " enthalte ")
    textstelle = Replace(textstelle, " enthält,", " enthalte,")
    textstelle = Replace(textstelle, " enthält.", " enthalte.")
    'Es betrifft
    textstelle = Replace(textstelle, " betrifft ", " betreffe ")
    textstelle = Replace(textstelle, " betrifft,", " betreffe,")
    textstelle = Replace(textstelle, " betrifft.", " betreffe.")
    'Es stimmt (nicht)
    textstelle = Replace(textstelle, " stimmt ", " stimme ")
    textstelle = Replace(textstelle, " stimmt,", " stimme,")
    textstelle = Replace(textstelle, " stimmt.", " stimme.")
    'Sachen stimmen (nicht)
    textstelle = Replace(textstelle, " stimmen ", " stimmten ")
    textstelle = Replace(textstelle, " stimmen,", " stimmten,")
    textstelle = Replace(textstelle, " stimmen.", " stimmten.")
    'Es läuft
    textstelle = Replace(textstelle, " läuft ", " laufe ")
    textstelle = Replace(textstelle, " läuft,", " laufe,")
    textstelle = Replace(textstelle, " läuft.", " laufe.")
    'Es stammt
    textstelle = Replace(textstelle, " stammt ", " stamme ")
    textstelle = Replace(textstelle, " stammt,", " stamme,")
    textstelle = Replace(textstelle, " stammt.", " stamme.")
    'Es kostet
    textstelle = Replace(textstelle, " kostet ", " koste ")
    textstelle = Replace(textstelle, " kostet,", " koste,")
    textstelle = Replace(textstelle, " kostet.", " koste.")
    'Es passt
    textstelle = Replace(textstelle, " passt ", " passe ")
    textstelle = Replace(textstelle, " passt,", " passe,")
    textstelle = Replace(textstelle, " passt.", " passe.")
    'Es entsteht
    textstelle = Replace(textstelle, " entsteht ", " entstehe ")
    textstelle = Replace(textstelle, " entsteht,", " entstehe,")
    textstelle = Replace(textstelle, " entsteht.", " entstehe.")
    'Es könnte (sein)
    textstelle = Replace(textstelle, " könnte ", " könne ")
    textstelle = Replace(textstelle, " könnte,", " könne,")
    textstelle = Replace(textstelle, " könnte.", " könne.")
    'Es folgt
    textstelle = Replace(textstelle, " folgt ", " folge ")
    textstelle = Replace(textstelle, " folgt,", " folge,")
    textstelle = Replace(textstelle, " folgt.", " folge.")
    'Es datiert
    textstelle = Replace(textstelle, " datiert ", " datiere ")
    textstelle = Replace(textstelle, " datiert,", " datiere,")
    textstelle = Replace(textstelle, " datiert.", " datiere.")
    'Es gelingt
    textstelle = Replace(textstelle, " gelingt ", " gelinge ")
    textstelle = Replace(textstelle, " gelingt,", " gelinge,")
    textstelle = Replace(textstelle, " gelingt.", " gelinge.")
    'Es gelingt
    textstelle = Replace(textstelle, " vorsieht ", " vorsehe ")
    textstelle = Replace(textstelle, " vorsieht,", " vorsehe,")
    textstelle = Replace(textstelle, " vorsieht.", " vorsehe.")
    'Man spricht
    textstelle = Replace(textstelle, " spricht ", " spreche ")
    textstelle = Replace(textstelle, " spricht,", " spreche,")
    textstelle = Replace(textstelle, " spricht.", " spreche.")
    'Man beträgt
    textstelle = Replace(textstelle, " beträgt ", " betrage ")
    textstelle = Replace(textstelle, " beträgt,", " betrage,")
    textstelle = Replace(textstelle, " beträgt.", " betrage.")
    'Es geschieht
    textstelle = Replace(textstelle, " geschieht ", " geschehe ")
    textstelle = Replace(textstelle, " geschieht,", " geschehe,")
    textstelle = Replace(textstelle, " geschieht.", " geschehe.")
    'Es fängt
    textstelle = Replace(textstelle, " fängt ", " fange ")
    textstelle = Replace(textstelle, " fängt,", " fange,")
    textstelle = Replace(textstelle, " fängt.", " fange.")
    'Es umfasst
    textstelle = Replace(textstelle, " umfasst ", " umfasse ")
    textstelle = Replace(textstelle, " umfasst,", " umfasse,")
    textstelle = Replace(textstelle, " umfasst.", " umfasse.")
    'Es beläuft
    textstelle = Replace(textstelle, " beläuft ", " belaufe ")
    textstelle = Replace(textstelle, " beläuft,", " belaufe,")
    textstelle = Replace(textstelle, " beläuft.", " belaufe.")
    'es fliesst
    textstelle = Replace(textstelle, " fliesst ", " fliesse ")
    textstelle = Replace(textstelle, " fliesst,", " fliesse,")
    textstelle = Replace(textstelle, " fliesst.", " fliesse.")
    'es dauert
    textstelle = Replace(textstelle, " dauert ", " dauere ")
    textstelle = Replace(textstelle, " dauert,", " dauere,")
    textstelle = Replace(textstelle, " dauert.", " dauere.")
    'man fragt (sich)
    textstelle = Replace(textstelle, " fragt ", " frage ")
    textstelle = Replace(textstelle, " fragt,", " frage,")
    textstelle = Replace(textstelle, " fragt.", " frage.")
    'es scheint
    textstelle = Replace(textstelle, " scheint ", " scheine ")
    textstelle = Replace(textstelle, " scheint,", " scheine,")
    textstelle = Replace(textstelle, " scheint.", " scheine.")
    'es nützt
    textstelle = Replace(textstelle, " nützt ", " nütze ")
    textstelle = Replace(textstelle, " nützt,", " nütze,")
    textstelle = Replace(textstelle, " nützt.", " nütze.")
    'es überwiegt
    textstelle = Replace(textstelle, " überwiegt ", " überwiege ")
    textstelle = Replace(textstelle, " überwiegt,", " überwiege,")
    textstelle = Replace(textstelle, " überwiegt.", " überwiege.")
    
    
    
    'Wörter direkt an einem Satzzeichen, werden von ersetzeVergangenheitsform nicht erfasst.
    'Zudem braucht es dort die umgekehrte Reihenfolge
    'Es war (es sei gewesen)
    textstelle = Replace(textstelle, " war,", " gewesen sei,")
    textstelle = Replace(textstelle, " war.", " gewesen sei.")
    'Sie waren (sie seien gewesen)
    textstelle = Replace(textstelle, " waren,", " gewesen seien,")
    textstelle = Replace(textstelle, " waren.", " gewesen seien.")
    'Es kam (es sei gekommen)
    textstelle = Replace(textstelle, " kam,", " gekommen sei,")
    textstelle = Replace(textstelle, " kam.", " gekommen sei.")
    'Sie kamen (sie seien gekommen)
    textstelle = Replace(textstelle, " kamen,", " gekommen seien,")
    textstelle = Replace(textstelle, " kamen.", " gekommen seien.")
    'Es blieb (es sei geblieben)
    textstelle = Replace(textstelle, " blieb,", " geblieben sei,")
    textstelle = Replace(textstelle, " blieb.", " geblieben sei.")
    'Sie blieben (sie seien geblieben)
    textstelle = Replace(textstelle, " blieben,", " geblieben seien,")
    textstelle = Replace(textstelle, " blieben.", " geblieben seien.")
    'es gab (es habe gegeben)
    textstelle = Replace(textstelle, " gab,", " gegeben habe,")
    textstelle = Replace(textstelle, " gab.", " gegeben habe.")
    'er ging (er sei gegangen)
    textstelle = Replace(textstelle, " ging,", " gegangen sei,")
    textstelle = Replace(textstelle, " ging.", " gegangen sei.")
    'es wurde (er sei geworden)
    textstelle = Replace(textstelle, " wurde,", " worden sei,")
    textstelle = Replace(textstelle, " wurde.", " worden sei.")
    'es befand (es habe befunden)
    textstelle = Replace(textstelle, " befand,", "  befunden habe,")
    textstelle = Replace(textstelle, " befand.", " befunden habe.")
    'er machte (er habe gemacht)
    textstelle = Replace(textstelle, " machte,", " gemacht habe,")
    textstelle = Replace(textstelle, " machte.", " gemacht habe.")
    'er wusste (er habe gewusst) - die kommaendung wird testmässig umgestellt: er wusste, -> er habe gewusst,
    textstelle = Replace(textstelle, " wusste,", " habe gewusst,")
    textstelle = Replace(textstelle, " wusste.", " gewusst habe.")
    'er sagte (er habe gesagt) - die kommaendung wird testmässig umgestellt: er sagte, -> er habe gesagt,
    textstelle = Replace(textstelle, " sagte,", " habe gesagt,")
    textstelle = Replace(textstelle, " sagte.", " gesagt habe.")
    'sie sagten (sie hätten gesagt)
    textstelle = Replace(textstelle, " sagten,", " gesagt hätten,")
    textstelle = Replace(textstelle, " sagten.", " gesagt hätten.")
    'er brauchte (er habe gebraucht)
    textstelle = Replace(textstelle, " brauchte,", " gebraucht habe,")
    textstelle = Replace(textstelle, " brauchte.", " gebraucht habe.")
    'sie brauchten (sie hätten gebraucht)
    textstelle = Replace(textstelle, " brauchten,", " gebraucht hätten,")
    textstelle = Replace(textstelle, " brauchten.", " gebraucht hätten.")
    'er hielt (er habe gehalten)
    textstelle = Replace(textstelle, " hielt,", " gehalten habe,")
    textstelle = Replace(textstelle, " hielt.", " gehalten haben.")
    'sie hielten (sie hätten gehalten)
    textstelle = Replace(textstelle, " hielten,", " gehalten hätten,")
    textstelle = Replace(textstelle, " hielten.", " gehalten hätten.")
    'er wollte (er habe gewollt)
    textstelle = Replace(textstelle, " wollte,", " habe gewollt,")
    textstelle = Replace(textstelle, " wollte.", " habe gewollt.")
    'sie wollten (sie hätten gewollt)
    textstelle = Replace(textstelle, " wollten,", " hätten gewollt,")
    textstelle = Replace(textstelle, " wollten.", " hätten gewollt.")
    'sie dachten (sie hätten gedacht)
    textstelle = Replace(textstelle, " dachten,", " hätten gedacht,")
    textstelle = Replace(textstelle, " dachten.", " hätten gedacht.")
    'es lautete (es habe gelautet)
    textstelle = Replace(textstelle, " lautete,", " habe gelautet,")
    textstelle = Replace(textstelle, " lauteten.", " habe gelautet.")
    'es stand (es habe gestanden)
    textstelle = Replace(textstelle, " stand,", " gestanden habe,")
    textstelle = Replace(textstelle, " standen.", " gestanden hätten.")
    'es erklärt (es habe erklärt)
    textstelle = Replace(textstelle, " erklärt,", " habe erklärt,")
    textstelle = Replace(textstelle, " erklärt.", " habe erklärt.")
    'er meinte (es habe gemeint)
    textstelle = Replace(textstelle, " meinte,", " habe gemeint,")
    textstelle = Replace(textstelle, " meinte.", " habe gemeint.")
    'er meinte (es habe gemeint)
    textstelle = Replace(textstelle, " erklärte,", " habe erklärt,")
    textstelle = Replace(textstelle, " erklärte.", " habe erklärt.")
    
    'Das Returnstatment funktioniert in VBA inden man den Namen der Funktion mit dem Return gleichsetzt
    VerbenErsetzung = textstelle
    
End Function


Private Function VergangenheitsVerbenErsetzung(text As String)

    'Ich war müde. -> Er sei müde gewesen.
    text = ersetzeVergangenheitsform(text, " war ", " sei ", "gewesen")
    'Wir waren müde. -> Sie seien müde gewesen.
    text = ersetzeVergangenheitsform(text, " waren ", " seien ", "gewesen")
    'Ich hatte Mühe. -> Er habe Mühe gehabt.
    text = ersetzeVergangenheitsform(text, " hatte ", " habe ", "gehabt")
    'Wir hatten Mühe. -> Sie hätten Mühe gehabt.
    text = ersetzeVergangenheitsform(text, " hatten ", " hätten ", "gehabt")
    'Ich musste gehen. -> Er  habe gehen müssen.
    text = ersetzeVergangenheitsform(text, " musste ", " habe ", "müssen")
    'Wir mussten gehen. -> Sie hätten gehen müssen.
    text = ersetzeVergangenheitsform(text, " mussten ", " hätten ", "müssen")
    'Ich fuhr heim. -> Sie sei heim gefahren.
    text = ersetzeVergangenheitsform(text, " fuhr ", " sei ", "gefahren")
    'Ich trug einen Helm. -> Sie habe einen Helm getragen.
    text = ersetzeVergangenheitsform(text, " trug ", " habe ", "getragen")
    'Wir trugen einen Helm. -> Sie hätten einen Helm getragen.
    text = ersetzeVergangenheitsform(text, " trugen ", " hätten ", "getragen")
    'Ich befand mich dort. -> Er habe sich dort befunden.
    text = ersetzeVergangenheitsform(text, " befand ", " habe ", "befunden")
    'Wir befanden uns dort. -> Sie hätten sich dort befunden.
    text = ersetzeVergangenheitsform(text, " befanden ", " hätten ", "befunden")
    'Ich lief nach Hause. -> Sie sei nach Hause gelaufen.
    text = ersetzeVergangenheitsform(text, " lief ", " sei ", "gelaufen")
    'Wir liefen nach Hause. -> Sie seien nach Hause gelaufen.
    text = ersetzeVergangenheitsform(text, " liefen ", " seien ", "gelaufen")
    'Ich fragte ihn. -> Er habe ihn gefragt.
    text = ersetzeVergangenheitsform(text, " fragte ", " habe ", "gefragt")
    'Wir fragten nach. -> Sie hätten nach gefragt.
    text = ersetzeVergangenheitsform(text, " fragten ", " hätten ", "gefragt")
    'Ich stellte Fragen. -> Sie habe Fragen gestellt.
    text = ersetzeVergangenheitsform(text, " stellte ", " habe ", "gestellt")
    'Wir stellten Fragen. -> Sei hätten Fragen gestellt.
    text = ersetzeVergangenheitsform(text, " stellten ", " hätten ", "gestellt")
    'Ich ging nach Hause. -> Er sei nach Hause gegangen.
    text = ersetzeVergangenheitsform(text, " ging ", " sei ", "gegangen")
    'Wir gingen nach Hause. -> Sie seien nach Hause gegangen.
    text = ersetzeVergangenheitsform(text, " gingen ", " seien ", "gegangen")
    'Ich blieb zuhause. -> Er sei zuhause geblieben.
    text = ersetzeVergangenheitsform(text, " blieb ", " sei ", "geblieben")
    'Wir blieben zuhause. -> Sie seien zuhause geblieben.
    text = ersetzeVergangenheitsform(text, " blieben ", " seien ", "geblieben")
    'Ich kannte ihn. -> Er habe ihn gekannt.
    text = ersetzeVergangenheitsform(text, " kannte ", " habe ", "gekannt")
    'Wir kannten uns. -> Sie hätten sich gekannt.
    text = ersetzeVergangenheitsform(text, " kannten ", " hätten ", "gekannt")
    'Ich wusste es. -> Er habe es gewusst.
    text = ersetzeVergangenheitsform(text, " wusste ", " habe ", "gewusst")
    'Wir wussten es. -> Sie hätten es gewusst.
    text = ersetzeVergangenheitsform(text, " wussten ", " hätten ", "gewusst")
    'Ich stand dort. -> Er habe dort gestanden.
    text = ersetzeVergangenheitsform(text, " stand ", " habe ", "gestanden")
    'Wir standen dort. -> Sie hätten dort gestanden.
    text = ersetzeVergangenheitsform(text, " standen ", " hätten ", "gestanden")
    'Ich dachte es. -> Er habe es gedacht.
    text = ersetzeVergangenheitsform(text, " dachte ", " habe ", "gedacht")
    'Wir dachten es. -> Sie hätten es gedacht.
    text = ersetzeVergangenheitsform(text, " dachten ", " hätten ", "gedacht")
    'Ich nahm Drogen. -> Er habe Drogen genommen.
    text = ersetzeVergangenheitsform(text, " nahm ", " habe ", "genommen")
    'Wir nahmen Drogen. -> Sie hätten Drogen genommen.
    text = ersetzeVergangenheitsform(text, " nahmen ", " hätten ", "genommen")
    'Ich sah rosa Elefanten. -> Er habe rosa Elefanten gesehen.
    text = ersetzeVergangenheitsform(text, " sah ", " habe ", "gesehen")
    'Wir sahen blaue Beeren. -> Sie hätten blaue Beeren gesehen.
    text = ersetzeVergangenheitsform(text, " sahen ", " hätten ", "gesehen")
    'Ich kam herunter. -> Er sei herunter gekommen.
    text = ersetzeVergangenheitsform(text, " kam ", " sei ", "gekommen")
    'Wir kamen herunter. -> Sie seien herunter gekommen.
    text = ersetzeVergangenheitsform(text, " kamen ", " seien ", "gekommen")
    'Ich sagte nichts. -> Er habe nichts gesagt.
    text = ersetzeVergangenheitsform(text, " sagte ", " habe ", "gesagt")
    'Wir sagten nichts. -> Sie hätten nichts gesagt.
    text = ersetzeVergangenheitsform(text, " sagten ", " hätten ", "gesagt")
    'Ich wurde wütend. -> Sie sei wütend worden.
    text = ersetzeVergangenheitsform(text, " wurde ", " sei ", "worden")
    'Wir wurden wütend. -> Sie seien wütend worden.
    text = ersetzeVergangenheitsform(text, " wurden ", " seien ", "worden")
    'Ich brauchte Hilfe. -> Sei habe Hilfe gebraucht.
    text = ersetzeVergangenheitsform(text, " brauchte ", " habe ", "gebraucht")
    'Wir brauchten Hilfe -> Sie hätten Hilfe gebraucht.
    text = ersetzeVergangenheitsform(text, " brauchten ", " hätten ", "gebraucht")
    'Ich benötigte Hilfe. -> Sie habe Hilfe benötigt.
    text = ersetzeVergangenheitsform(text, " benötigte ", " habe ", "benötigt")
    'Wir benötigten Hilfe -> Sie hätten Hilfe benötigt.
    text = ersetzeVergangenheitsform(text, " benötigten ", " hätten ", "benötigt")
    'Ich hatte einen Heidenspass. -> Er habe einen Heidenspass gehabt.
    text = ersetzeVergangenheitsform(text, " hatte ", " habe ", "gehabt")
    'Wir hatten Hunger -> Sie hätten Hunger gehabt.
    text = ersetzeVergangenheitsform(text, " hatten ", " hätten ", "gehabt")
    'Ich konnte es nicht. -> Er habe es nicht gekonnt.
    text = ersetzeVergangenheitsform(text, " konnte ", " habe ", "gekonnt")
    'Wir konnten es nicht -> Sie hätten es nicht gekonnt.
    text = ersetzeVergangenheitsform(text, " konnten ", " hätten ", "gekonnt")
    'Es gab Probleme. -> Es habe Probleme gegeben.
    text = ersetzeVergangenheitsform(text, " gab ", " habe ", "gegeben")
    'Ich durfte es nicht. -> Er habe es nicht gedurft.
    text = ersetzeVergangenheitsform(text, " durfte ", " habe ", "gedurft")
    'Wir durften es nicht -> Sie hätten es nicht dürfen.
    text = ersetzeVergangenheitsform(text, " durften ", " hätten ", "dürfen")
    'Ich machte nie Probleme. -> Sie habe nie Probleme gemacht.
    text = ersetzeVergangenheitsform(text, " machte ", " habe ", "gemacht")
    'Wir machten Konfetti -> Sie hätten Konfetti gemacht.
    text = ersetzeVergangenheitsform(text, " machten ", " hätten ", "gemacht")
    'Ich spielte gut. -> Er habe gut gespielt.
    text = ersetzeVergangenheitsform(text, " spielte ", " habe ", "gespielt")
    'Wir spielten Fussball -> Sie hätten Fussball gespielt.
    text = ersetzeVergangenheitsform(text, " spielten ", " hätten ", "gespielt")
    'Ich hielt an. -> Er habe an gehalten.
    text = ersetzeVergangenheitsform(text, " hielt ", " habe ", "gehalten")
    'Wir hielten Aktien -> Sie hätten Aktien gehalten.
    text = ersetzeVergangenheitsform(text, " hielten ", " hätten ", "gehalten")
    'Ich wollte gehen. -> Er habe gehen wollen.
    text = ersetzeVergangenheitsform(text, " wollte ", " habe ", "wollen")
    'Wir wollten gehen -> Sie hätten gehen wollen.
    text = ersetzeVergangenheitsform(text, " wollten ", " hätten ", "wollen")
    'Ich diente ihr. -> Er habe ihr gedient.
    text = ersetzeVergangenheitsform(text, " diente ", " habe ", "gedient")
    'Wir dienten als Munitionsfutter -> Sie hätten als Munitionsfutter gedient.
    text = ersetzeVergangenheitsform(text, " dienten ", " hätten ", "gedient")
    'Ich versuchte es. -> Er habe es versucht.
    text = ersetzeVergangenheitsform(text, " versuchte ", " habe ", "versucht")
    'Wir versuchten es -> Sie hätten es versucht.
    text = ersetzeVergangenheitsform(text, " versuchten ", " hätten ", "versucht")
    'Ich brachte Sachen. -> Er habe Sachen gebracht.
    text = ersetzeVergangenheitsform(text, " brachte ", " habe ", "gebracht")
    'Wir brachten Kuchen. -> Sie hätten Kuchen gebracht.
    text = ersetzeVergangenheitsform(text, " brachten ", " hätten ", "gebracht")
    'Ich fand es. -> Er habe es gefunden.
    text = ersetzeVergangenheitsform(text, " fand ", " habe ", "gefunden")
    'Wir fanden es. -> Sie hätten es gefunden.
    text = ersetzeVergangenheitsform(text, " fanden ", " hätten ", "gefunden")
    'Ich geriet in Panik. -> Er sei in Panik geraten.
    text = ersetzeVergangenheitsform(text, " geriet ", " sei ", "geraten")
    'Wir gerieten in Übermut. -> Sie seien in Übermut geraten.
    text = ersetzeVergangenheitsform(text, " gerieten ", " seien ", "geraten")
    'Ich fuhr los. -> Er sei losgefahren.
    text = ersetzeVergangenheitsform(text, " fuhr ", " sei ", "gefahren")
    'Wir fuhren Auto. -> Sie seien Auto gefahren.
    text = ersetzeVergangenheitsform(text, " fuhren ", " seien ", "gefahren")
    'Ich verbrachte Zeit. -> Er habe Zeit verbracht
    text = ersetzeVergangenheitsform(text, " verbrachte ", " habe ", "verbracht")
    'Wir verbrachten Zeit. -> Sie hätten Zeit verbracht.
    text = ersetzeVergangenheitsform(text, " verbrachten ", " hätten ", "verbracht")
    'Ich trank Bier. -> Er habe Bier getrunken
    text = ersetzeVergangenheitsform(text, " trank ", " habe ", "getrunken")
    'Wir tranken viel. -> Sie hätten viel getrunken.
    text = ersetzeVergangenheitsform(text, " tranken ", " hätten ", "getrunken")
    'Ich unterhielt mich. -> Er habe sich unterhalten
    text = ersetzeVergangenheitsform(text, " unterhielt ", " habe ", "unterhalten")
    'Wir unterhielten uns. -> Sie hätten sich unterhalten.
    text = ersetzeVergangenheitsform(text, " unterhielten ", " hätten ", "unterhalten")
    'Ich besass nichts. -> Er habe nichts besessen
    text = ersetzeVergangenheitsform(text, " besass ", " habe ", "besessen")
    'Wir besassen nichts. -> Sie hätten nichts besessen.
    text = ersetzeVergangenheitsform(text, " besassen ", " hätten ", "besessen")
    'Ich fiel nicht. -> Er sei nicht gefallen
    text = ersetzeVergangenheitsform(text, " fiel ", " sei ", "gefallen")
    'Wir fielen um. -> Sie seien um gefallen.
    text = ersetzeVergangenheitsform(text, " fielen ", " seien ", "gefallen")
    'Ich verlangte es. -> Er habe es verlangt.
    text = ersetzeVergangenheitsform(text, " verlangte ", " habe ", "verlangt")
    'Wir verlangten es. -> Sie hätten es verlangt.
    text = ersetzeVergangenheitsform(text, " verlangten ", " hätten ", "verlangt")
    'Es passierte gestern. -> Es sei gestern passiert.
    text = ersetzeVergangenheitsform(text, " passierte ", " sei ", "passiert")
    'Ich erklärte es -> Er habe es erklärt.
    text = ersetzeVergangenheitsform(text, " erklärte ", " habe ", "erklärt")
    'Sie erklärten es -> Sie hätten es erklärt.
    text = ersetzeVergangenheitsform(text, " erklärten ", " hätten ", "erklärt")
    'Ich traf ins Schwarze. -> Er habe ins Schwarze getroffen.
    text = ersetzeVergangenheitsform(text, " traf ", " habe ", "getroffen")
    'Wir trafen uns. -> Sie hätten sich getroffen.
    text = ersetzeVergangenheitsform(text, " trafen ", " hätten ", "getroffen")
    'Ich bekam Hunger. -> Er habe Hunger bekommen.
    text = ersetzeVergangenheitsform(text, " bekam ", " habe ", "bekommen")
    'Wir bekamen Hunger.  -> Sie hätten Hunger bekommen.
    text = ersetzeVergangenheitsform(text, " bekamen ", " hätten ", "bekommen")
    'Ich löschte alles. -> Er habe alles gelöscht.
    text = ersetzeVergangenheitsform(text, " löschte ", " habe ", "gelöscht")
    'Wir löschten es.  -> Sie hätten es gelöscht.
    text = ersetzeVergangenheitsform(text, " löschten ", " hätten ", "gelöscht")
    'Es kostete nicht viel. -> Es habe nicht viel gekostet.
    text = ersetzeVergangenheitsform(text, " kostete ", " habe ", "gekostet")
    'Ich vermutete es.  -> Er habe es vermutet.
    text = ersetzeVergangenheitsform(text, " vermutete ", " habe ", "vermutet")
    'Wir vermuteten es. -> Sie hätten es vermutet.
    text = ersetzeVergangenheitsform(text, " vermuteten ", " hätten ", "vermutet")
    'Ich passte nicht.  -> Er nicht nicht gepasst.
    text = ersetzeVergangenheitsform(text, " passte ", " habe ", "gepasst")
    'Wir passten nicht. -> Sie hätten nicht gepasst.
    text = ersetzeVergangenheitsform(text, " passten ", " hätten ", "gepasst")
    'Ich holte es.  -> Er habe es geholt.
    text = ersetzeVergangenheitsform(text, " holte ", " habe ", "geholt")
    'Wir holten es. -> Sie hätten es geholt.
    text = ersetzeVergangenheitsform(text, " holten ", " hätten ", "geholt")
    'Ich zeigte es.  -> Er habe es gezeigt.
    text = ersetzeVergangenheitsform(text, " zeigte ", " habe ", "gezeigt")
    'Wir zeigten es. -> Sie hätten es gezeigt.
    text = ersetzeVergangenheitsform(text, " zeigten ", " hätten ", "gezeigt")
    'Ich telefonierte ihm.  -> Er habe diesem telefoniert.
    text = ersetzeVergangenheitsform(text, " telefonierte ", " habe ", "telefoniert")
    'Wir telefonierten miteinander. -> Sie hätten miteinander telefoniert.
    text = ersetzeVergangenheitsform(text, " telefonierten ", " hätten ", "telefoniert")
    'Ich bat ihn darum.  -> Er habe diesen darum gegebeten.
    text = ersetzeVergangenheitsform(text, " bat ", " habe ", "gebeten")
    'Wir baten diese darum. -> Sie hätten diese darum gebeten.
    text = ersetzeVergangenheitsform(text, " baten ", " hätten ", "gebeten")
    'Ich hörte es.  -> Er habe es gehört.
    text = ersetzeVergangenheitsform(text, " hörte ", " habe ", "gehört")
    'Wir hörten es. -> Sie hätten es gehört.
    text = ersetzeVergangenheitsform(text, " hörten ", " hätten ", "gehört")
    'Ich sass unten.  -> Er habe unten gesessen.
    text = ersetzeVergangenheitsform(text, " sass ", " habe ", "gesessen")
    'Wir sassen im Foyer. -> Sie seien im Foyer gesessen.
    text = ersetzeVergangenheitsform(text, " sassen ", " hätten ", "gesessen")
    'Ich schilderte es.  -> Er habe es geschildert.
    text = ersetzeVergangenheitsform(text, " schilderte ", " habe ", "geschildert")
    'Wir schilderten es. -> Sie hätten es geschildert.
    text = ersetzeVergangenheitsform(text, " schilderten ", " hätten ", "geschildert")
    'Ich schrieb diesem.  -> Er habe diesem geschrieben.
    text = ersetzeVergangenheitsform(text, " schrieb ", " habe ", "geschrieben")
    'Wir schrieben uns. -> Sie hätten sich geschrieben.
    text = ersetzeVergangenheitsform(text, " schrieben ", " hätten ", "geschrieben")
    'Ich logierte dort.  -> Er habe dort logiert.
    text = ersetzeVergangenheitsform(text, " logierte ", " habe ", "logiert")
    'Wir logierten dort. -> Sie hätten dort logiert.
    text = ersetzeVergangenheitsform(text, " logierten ", " hätten ", "logiert")
    'Ich funktionierte einfach.  -> Er habe einfach funktioniert.
    text = ersetzeVergangenheitsform(text, " funktionierte ", " habe ", "funktioniert")
    'Wir funktionierten nicht. -> Sie hätten nicht funktioniert.
    text = ersetzeVergangenheitsform(text, " funktionierten ", " hätten ", "funktioniert")
    'Ich lag gut.  -> Er sei gut gelegen.
    text = ersetzeVergangenheitsform(text, " lag ", " sei ", "gelegen")
    'Wir lagen drunter. -> Sie seien drunter gelegen.
    text = ersetzeVergangenheitsform(text, " lagen ", " seien ", "gelegen")
    'Ich täuschte mich.  -> Er habe sich getäuscht.
    text = ersetzeVergangenheitsform(text, " täuschte ", " habe ", "getäuscht")
    'Wir täuschten uns. -> Sie hätten sich getäuscht.
    text = ersetzeVergangenheitsform(text, " täuschten ", " hätten ", "getäuscht")
    'Ich zielte nicht.  -> Er habe nicht gezielt.
    text = ersetzeVergangenheitsform(text, " zielte ", " habe ", "gezielt")
    'Wir zielten nicht. -> Sie hätten nicht gezielt.
    text = ersetzeVergangenheitsform(text, " zielten ", " hätten ", "gezielt")
    'Ich antwortete nicht.  -> Er habe nicht geantwortet.
    text = ersetzeVergangenheitsform(text, " antwortete ", " habe ", "geantwortet")
    'Wir antworteten nicht. -> Sie hätten nicht geantwortet.
    text = ersetzeVergangenheitsform(text, " antworteten ", " hätten ", "geantwortet")
    'Ich rief ihm.  -> Er habe diesem gerufen.
    text = ersetzeVergangenheitsform(text, " rief ", " habe ", "gerufen")
    'Wir riefen diesen. -> Sie hätten diesen gerufen.
    text = ersetzeVergangenheitsform(text, " riefen ", " hätten ", "gerufen")
    'Ich stieg runter.  -> Er sei runter gestiegen.
    text = ersetzeVergangenheitsform(text, " stieg ", " sei ", "gestiegen")
    'Wir stiegen runter. -> Sie seien runter gestiegen.
    text = ersetzeVergangenheitsform(text, " stiegen ", " seien ", "gestiegen")
    'Ich schaute runter.  -> Er habe runter geschaut.
    text = ersetzeVergangenheitsform(text, " schaute ", " habe ", "geschaut")
    'Wir schauten runter. -> Sie hätten runter geschaut.
    text = ersetzeVergangenheitsform(text, " schauten ", " hätten ", "geschaut")
    'Ich übernahme es.  -> Er habe es übernommen.
    text = ersetzeVergangenheitsform(text, " übernahm ", " habe ", "übernommen")
    'Wir übernahmen es. -> Sie hätten es übernommen.
    text = ersetzeVergangenheitsform(text, " übernahmen ", " hätten ", "übernommen")
    'Ich öffnete es.  -> Er habe es geöffnet.
    text = ersetzeVergangenheitsform(text, " öffnete ", " habe ", "geöffnet")
    'Wir öffneten es. -> Sie hätten es geöffnet.
    text = ersetzeVergangenheitsform(text, " öffneten ", " hätten ", "geöffnet")
    'Ich reagierte nicht.  -> Er habe nicht reagiert.
    text = ersetzeVergangenheitsform(text, " reagierte ", " habe ", "reagiert")
    'Wir reagierten nicht. -> Sie hätten nicht reagiert.
    text = ersetzeVergangenheitsform(text, " reagierten ", " hätten ", "reagiert")
    'Ich begab mich.  -> Er habe sich begeben.
    text = ersetzeVergangenheitsform(text, " begab ", " habe ", "begeben")
    'Wir begaben uns. -> Sie hätten sich begeben.
    text = ersetzeVergangenheitsform(text, " begaben ", " hätten ", "begeben")
    'Ich führte ihn.  -> Er habe diesen geführt.
    text = ersetzeVergangenheitsform(text, " führte ", " habe ", "geführt")
    'Wir führten diese. -> Sie hätten diese geführt.
    text = ersetzeVergangenheitsform(text, " führten ", " hätten ", "geführt")
    'Ich sprach laut.  -> Er habe laut gesprochen.
    text = ersetzeVergangenheitsform(text, " sprach ", " habe ", "gesprochen")
    'Wir sprachen darüber. -> Sie hätten darüber gesprochen.
    text = ersetzeVergangenheitsform(text, " sprachen ", " hätten ", "gesprochen")
    'Ich stiess ihn.  -> Er habe diesen gestossen.
    text = ersetzeVergangenheitsform(text, " stiess ", " habe ", "gestossen")
    'Wir stiessen uns. -> Sie hätten sich gestossen.
    text = ersetzeVergangenheitsform(text, " stiessen ", " hätten ", "gestossen")
    'Ich gelangte hinein.  -> Er sei hinein gelangt.
    text = ersetzeVergangenheitsform(text, " gelangte ", " sei ", "gelangt")
    'Wir gelangten hinein. -> Sie seien hinein gelangt.
    text = ersetzeVergangenheitsform(text, " gelangten ", " seien ", "gelangt")
    'Ich schloss ab.  -> Er habe ab geschlossen.
    text = ersetzeVergangenheitsform(text, " schloss ", " habe ", "geschlossen")
    'Wir schlossen ab. -> Sie hätten ab geschlossen.
    text = ersetzeVergangenheitsform(text, " schlossen ", " hätten ", "geschlossen")
    'Ich folgte ihr.  -> Er sei ihr gefolgt.
    text = ersetzeVergangenheitsform(text, " folgte ", " sei ", "gefolgt")
    'Wir folgten ihr. -> Sie seien ihr gefolgt.
    text = ersetzeVergangenheitsform(text, " folgten ", " seien ", "gefolgt")
    'Ich meinte es.  -> Er habe es gemeint.
    text = ersetzeVergangenheitsform(text, " meinte ", " habe ", "gemeint")
    'Wir meinten es. -> Sie hätten es gemeint.
    text = ersetzeVergangenheitsform(text, " meinten ", " hätten ", "gemeint")
    'Ich zahlte es.  -> Er habe es gezahlt.
    text = ersetzeVergangenheitsform(text, " zahlte ", " habe ", "gezahlt")
    'Wir zahlten es. -> Sie hätten es gezahlt.
    text = ersetzeVergangenheitsform(text, " zahlten ", " hätten ", "gezahlt")
    'Es erfolge.  -> Es sei erfolgt.
    text = ersetzeVergangenheitsform(text, " erfolgte ", " sei ", "erfolgt")
    'Es erfolgten Schicksalsschläge.  -> Es seien Schicksalsschläge erfolgt.
    text = ersetzeVergangenheitsform(text, " erfolgten ", " seien ", "erfolgt")
    'Es lautete.  -> Es habe gelautet.
    text = ersetzeVergangenheitsform(text, " lautete ", " habe ", "gelautet")
    'Sie lauteten.  -> Sie hätten  gelautet.
    text = ersetzeVergangenheitsform(text, " lauteten ", " hätten ", "gelautet")
    'Ich beantragte es.  -> Er habe es beantragt.
    text = ersetzeVergangenheitsform(text, " beantragte ", " habe ", "beantragt")
    'Wir beantragten es. -> Sie hätten es beantragt.
    text = ersetzeVergangenheitsform(text, " beantagten ", " hätten ", "beantragt")
    'Ich suchte ihn.  -> Er habe diesen gesucht.
    text = ersetzeVergangenheitsform(text, " suchte ", " habe ", "gesucht")
    'Wir suchten es. -> Sie hätten es gesucht.
    text = ersetzeVergangenheitsform(text, " suchten ", " hätten ", "gesucht")
    'Ich warf es.  -> Er habe es geworfen.
    text = ersetzeVergangenheitsform(text, " warf ", " habe ", "geworfen")
    'Wir warfen es. -> Sie hätten es geworfen.
    text = ersetzeVergangenheitsform(text, " warfen ", " hätten ", "geworfen")
    'Ich schuldete es.  -> Er habe es geschuldet.
    text = ersetzeVergangenheitsform(text, " schuldete ", " habe ", "geschuldet")
    'Wir schuldeten es. -> Sie hätten es geschuldet.
    text = ersetzeVergangenheitsform(text, " schuldeten ", " hätten ", "geschuldet")
    'Ich erhielt es.  -> Er habe es erhalten.
    text = ersetzeVergangenheitsform(text, " erhielt ", " habe ", "erhalten")
    'Wir erhielten es. -> Sie hätten es erhalten.
    text = ersetzeVergangenheitsform(text, " erhielten ", " hätten ", "erhalten")
    'Ich liess es.  -> Er habe es gelassen.
    text = ersetzeVergangenheitsform(text, " liess ", " habe ", "gelassen")
    'Wir liessen es. -> Sie hätten es gelassen.
    text = ersetzeVergangenheitsform(text, " liessen ", " hätten ", "gelassen")
    'Ich hiess es gut.  -> Er habe es gut geheissen.
    text = ersetzeVergangenheitsform(text, " hiess ", " habe ", "geheissen")
    'Wir hiessen es gut. -> Sie hätten es gut geheissen.
    text = ersetzeVergangenheitsform(text, " hiessen ", " hätten ", "geheissen")
    'Ich tat es.  -> Er habe es getan.
    text = ersetzeVergangenheitsform(text, " tat ", " habe ", "getan")
    'Wir taten es . -> Sie hätten es getan.
    text = ersetzeVergangenheitsform(text, " taten ", " hätten ", "getan")
    'Ich glaubte es.  -> Er habe es geglaubt.
    text = ersetzeVergangenheitsform(text, " glaubte ", " habe ", "geglaubt")
    'Wir glaubten es. -> Sie hätten es geglaubt.
    text = ersetzeVergangenheitsform(text, " glaubten ", " hätten ", "geglaubt")
    'Ich half ihm.  -> Er habe diesem geholfen.
    text = ersetzeVergangenheitsform(text, " half ", " habe ", "geholfen")
    'Wir halfen aus. -> Sie hätten aus geholfen.
    text = ersetzeVergangenheitsform(text, " halfen ", " hätten ", "geholfen")
    'Ich ass viel.  -> Er habe viel gegessen.
    text = ersetzeVergangenheitsform(text, " ass ", " habe ", "gegessen")
    'Wir assen viel. -> Sie hätten viel gegessen.
    text = ersetzeVergangenheitsform(text, " assen ", " hätten ", "gegessen")
    'Ich las viel.  -> Er habe viel gelesen.
    text = ersetzeVergangenheitsform(text, " las ", " habe ", "gelesen")
    'Wir lasen viel. -> Sie hätten viel geleseen.
    text = ersetzeVergangenheitsform(text, " lasen ", " hätten ", "gelesen")
    'Ich zog daran.  -> Er habe daran gezogen.
    text = ersetzeVergangenheitsform(text, " zog ", " habe ", "gezogen")
    'Wir zogen daran. -> Sie hätten daran gezogen.
    text = ersetzeVergangenheitsform(text, " zogen ", " hätten ", "gezogen")
    'Ich schlief noch.  -> Er habe noch geschlafen.
    text = ersetzeVergangenheitsform(text, " schlief ", " habe ", "geschlafen")
    'Wir schliefen noch. -> Sie hätten noch geschlafen.
    text = ersetzeVergangenheitsform(text, " schliefen ", " hätten ", "geschlafen")
    'Ich begann damit.  -> Er habe damit begonnen.
    text = ersetzeVergangenheitsform(text, " begann ", " habe ", "begonnen")
    'Wir begannen damit. -> Sie hätten damit begonnen.
    text = ersetzeVergangenheitsform(text, " begannen ", " hätten ", "begonnen")
    'Ich legte es.  -> Er habe es gelegt.
    text = ersetzeVergangenheitsform(text, " legte ", " habe ", "gelegt")
    'Wir legten es. -> Sie hätten es gelegt.
    text = ersetzeVergangenheitsform(text, " legten ", " hätten ", "gelegt")
    'Ich wehrte mich.  -> Er habe sich gewehrt.
    text = ersetzeVergangenheitsform(text, " wehrte ", " habe ", "gewehrt")
    'Wir wehrten uns. -> Sie hätten sich gewehrt.
    text = ersetzeVergangenheitsform(text, " wehrten ", " hätten ", "gewehrt")
    'Ich spuckte es.  -> Er habe es gespuckt.
    text = ersetzeVergangenheitsform(text, " spuckte ", " habe ", "gespuckt")
    'Wir spuckten aus. -> Sie hätten aus gespuckt.
    text = ersetzeVergangenheitsform(text, " spuckten ", " hätten ", "gespuckt")
    'Ich explodierte.  -> Er sei explodiert.
    text = ersetzeVergangenheitsform(text, " explodierte ", " sei ", "explodiert")
    'Wir explodierten. -> Sie seien explodiert.
    text = ersetzeVergangenheitsform(text, " explodierten ", " seien ", "explodiert")
    'Ich schleuderte es.  -> Er habe es geschleudert.
    text = ersetzeVergangenheitsform(text, " schleuderte ", " habe ", "geschleudert")
    'Wir schleuderten es. -> Sie hätten es geschleudert.
    text = ersetzeVergangenheitsform(text, " schleuderten ", " hätten ", "geschleudert")
    'Ich schubste ihn.  -> Er habe diesen geschubst.
    text = ersetzeVergangenheitsform(text, " schubste ", " habe ", "geschubst")
    'Wir schubsten sie. -> Sie hätten diese geschubst.
    text = ersetzeVergangenheitsform(text, " schubsten ", " hätten ", "geschubst")
    'Ich drückte es.  -> Er habe es gedrückt.
    text = ersetzeVergangenheitsform(text, " drückte ", " habe ", "gedrückt")
    'Wir drückten es. -> Sie hätten es gedrückt.
    text = ersetzeVergangenheitsform(text, " drückten ", " hätten ", "gedrückt")
    'Ich beobachtete es.  -> Er habe es beobachtet.
    text = ersetzeVergangenheitsform(text, " beobachtete ", " habe ", "beobachtet")
    'Wir beobachteten es. -> Sie hätten es beobachtet.
    text = ersetzeVergangenheitsform(text, " beobachteten ", " hätten ", "beobachtet")
    'Ich winselte laut.  -> Er habe laut gewinselt.
    text = ersetzeVergangenheitsform(text, " winselte ", " habe ", "gewinselt")
    'Wir winselten laut. -> Sie hätten laut gewinselt.
    text = ersetzeVergangenheitsform(text, " winselte ", " hätten ", "gewinselt")
    'Ich bellte laut.  -> Er habe laut gebellt.
    text = ersetzeVergangenheitsform(text, " bellte ", " habe ", "gebellt")
    'Wir bellten laut. -> Sie hätten laut gebellt.
    text = ersetzeVergangenheitsform(text, " bellten ", " hätten ", "gebellt")
    'Ich stöhnt laut.  -> Er habe laut gestöhnt.
    text = ersetzeVergangenheitsform(text, " stöhnte ", " habe ", "gestöhnt")
    'Wir stöhnten laut. -> Sie hätten laut gestöhnt.
    text = ersetzeVergangenheitsform(text, " stöhnten ", " hätten ", "gestöhnt")
    'Ich leckte es.  -> Er habe es geleckt.
    text = ersetzeVergangenheitsform(text, " leckte ", " habe ", "geleckt")
    'Wir leckten es. -> Sie hätten es geleckt.
    text = ersetzeVergangenheitsform(text, " leckten ", " hätten ", "geleckt")
    'Ich bewegte es.  -> Er habe es bewegt.
    text = ersetzeVergangenheitsform(text, " bewegte ", " habe ", "bewegt")
    'Wir bewegten es. -> Sie hätten es bewegt.
    text = ersetzeVergangenheitsform(text, " bewegten ", " hätten ", "bewegt")
    'Ich näherte mich. -> Er habe sich genähert.
    text = ersetzeVergangenheitsform(text, " näherte ", " habe ", "genähert")
    'Wir näherten uns. -> Sie hätten sich genähert.
    text = ersetzeVergangenheitsform(text, " näherten ", " hätten ", "genähert")
    'Ich verhielt mich gut. -> Er habe sich gut verhalten.
    text = ersetzeVergangenheitsform(text, " verhielt ", " habe ", "verhalten")
    'Wir verhielten uns. -> Sie hätten sich verhalten.
    text = ersetzeVergangenheitsform(text, " verhielten ", " hätten ", "verhalten")
    'Ich behandelte es. -> Er habe es behandelt.
    text = ersetzeVergangenheitsform(text, " behandelte ", " habe ", "behandelt")
    'Wir behandelten es. -> Sie hätten es behandelt.
    text = ersetzeVergangenheitsform(text, " behandelten ", " hätten ", "behandelt")
    'Ich hob es. -> Er habe es gehoben.
    text = ersetzeVergangenheitsform(text, " hob ", " habe ", "gehoben")
    'Wir hoben es. -> Sie hätten es gehoben.
    text = ersetzeVergangenheitsform(text, " hoben ", " hätten ", "gehoben")
    'Ich flog. -> Er sei geflogen.
    text = ersetzeVergangenheitsform(text, " flog ", " sei ", "geflogen")
    'Wir flogen. -> Sie seien geflogen.
    text = ersetzeVergangenheitsform(text, " flogen ", " seien ", "geflogen")
    'Ich landete. -> Er sei gelandet.
    text = ersetzeVergangenheitsform(text, " landete ", " sei ", "gelandet")
    'Wir landeten. -> Sie seien gelandet.
    text = ersetzeVergangenheitsform(text, " landeten ", " seien ", "gelandet")
    'Ich wickelte. -> Er habe gewickelt.
    text = ersetzeVergangenheitsform(text, " wickelte ", " habe ", "gewickelt")
    'Wir wickelten. -> Sie hätten gewickelt.
    text = ersetzeVergangenheitsform(text, " wickelten ", " hätten ", "gewickelt")
    'Ich vernahm. -> Er habe vernommen.
    text = ersetzeVergangenheitsform(text, " vernahm ", " habe ", "vernommen")
    'Wir vernahmen. -> Sie hätten vernommen.
    text = ersetzeVergangenheitsform(text, " vernahmen ", " hätten ", "vernommen")
    'Ich entschied es. -> Er habe es entschieden.
    text = ersetzeVergangenheitsform(text, " entschied ", " habe ", "entschieden")
    'Wir entschieden uns. -> Sie hätten sich entschieden.
    text = ersetzeVergangenheitsform(text, " entschieden ", " hätten ", "entschieden")
    'Ich weigerte mich. -> Er habe sich geweigert.
    text = ersetzeVergangenheitsform(text, " weigerte ", " habe ", "geweigert")
    'Wir weigerten uns. -> Sie hätten sich geweigert.
    text = ersetzeVergangenheitsform(text, " weigerten ", " hätten ", "geweigert")
    'Ich insistierte darum. -> Er habe darum insisitiert.
    text = ersetzeVergangenheitsform(text, " insistierte ", " habe ", "insistiert")
    'Wir insistierten dort. -> Sie hätten dort insistiert.
    text = ersetzeVergangenheitsform(text, " insistierten ", " hätten ", "insistiert")
    'Ich kaufte es. -> Er habe es gekauft.
    text = ersetzeVergangenheitsform(text, " kaufte ", " habe ", "gekauft")
    'Wir kauften es. -> Sie hätten es gekauft.
    text = ersetzeVergangenheitsform(text, " kauften ", " hätten ", "gekauft")
    'Ich arbeitete lange. -> Er habe lange gearbeitet.
    text = ersetzeVergangenheitsform(text, " arbeitete ", " habe ", "gearbeitet")
    'Wir arbeiteten lange. -> Sie hätten lange gearbeitet.
    text = ersetzeVergangenheitsform(text, " arbeiteten ", " hätten ", "gearbeitet")
    'Ich fühlte es. -> Er habe es gefühlt.
    text = ersetzeVergangenheitsform(text, " fühlte ", " habe ", "gefühlt")
    'Wir fühlten es. -> Sie hätten es gefühlt.
    text = ersetzeVergangenheitsform(text, " fühlten ", " hätten ", "gefühlt")
    'Ich lebte alleine. -> Er habe alleine gelebt.
    text = ersetzeVergangenheitsform(text, " lebte ", " habe ", "gelebt")
    'Wir lebten alleine. -> Sie hätten alleine gelebt.
    text = ersetzeVergangenheitsform(text, " lebten ", " hätten ", "gelebt")
    'Ich starb. -> Er sei gestorben.
    text = ersetzeVergangenheitsform(text, " starb ", " sei ", "gestorben")
    'Wir starben alleine. -> Sie seien alleine gestorben.
    text = ersetzeVergangenheitsform(text, " starben ", " seien ", "gestorben")
    'Ich studierte es. -> Er habe es studiert.
    text = ersetzeVergangenheitsform(text, " studierte ", " habe ", "studiert")
    'Wir studierten es. -> Sie hätten es studiert.
    text = ersetzeVergangenheitsform(text, " studierten ", " hätten ", "studiert")
    'Ich reiste alleine. -> Er sei alleine gereist.
    text = ersetzeVergangenheitsform(text, " reiste ", " sei ", "gereist")
    'Wir reisten alleine. -> Sie seien alleine gereist.
    text = ersetzeVergangenheitsform(text, " reisten ", " seien ", "gereist")
    'Ich träumte es. -> Er habe es geträumt.
    text = ersetzeVergangenheitsform(text, " träumte ", " habe ", "geträumt")
    'Wir träumten es. -> Sie hätten es geträumt.
    text = ersetzeVergangenheitsform(text, " träumten ", " hätten ", "geträumt")
    'Ich verkaufte es. -> Er habe es verkauft.
    text = ersetzeVergangenheitsform(text, " verkaufte ", " habe ", "verkauft")
    'Wir verkauften es. -> Sie hätten es verkauft.
    text = ersetzeVergangenheitsform(text, " verkauften ", " hätten ", "verkauft")
    'Ich lernte es. -> Er habe es gelernt.
    text = ersetzeVergangenheitsform(text, " lernte ", " habe ", "gelernt")
    'Wir lernten es. -> Sie hätten es gelernt.
    text = ersetzeVergangenheitsform(text, " lernten ", " hätten ", "gelernt")
    'Ich weinte lange. -> Er habe lange geweint.
    text = ersetzeVergangenheitsform(text, " weinte ", " habe ", "geweint")
    'Wir weinten lange. -> Sie hätten lange geweint.
    text = ersetzeVergangenheitsform(text, " weinten ", " hätten ", "geweint")
    'Ich sang lange. -> Er habe lange gesungen.
    text = ersetzeVergangenheitsform(text, " sang ", " habe ", "gesungen")
    'Wir sangen lange. -> Sie hätten lange gesungen.
    text = ersetzeVergangenheitsform(text, " sangen ", " hätten ", "gesungen")
    'Ich tanzte lange. -> Er habe lange getanzt.
    text = ersetzeVergangenheitsform(text, " tanzte ", " habe ", "getanzt")
    'Wir tanzten lange. -> Sie hätten lange getanzt.
    text = ersetzeVergangenheitsform(text, " tanzten ", " hätten ", "getanzt")
    'Ich malte lange. -> Er habe lange gemalt.
    text = ersetzeVergangenheitsform(text, " malte ", " habe ", "gemalt")
    'Wir tanzten lange. -> Sie hätten lange getanzt.
    text = ersetzeVergangenheitsform(text, " malten ", " hätten ", "gemalt")
    'Ich setzte viel Wert darauf. -> Er viel Wert darauf gesetzt.
    text = ersetzeVergangenheitsform(text, " setzte ", " habe ", "gesetzt")
    'Wir setzten uns. -> Sie hätten sich gesetzt.
    text = ersetzeVergangenheitsform(text, " setzten ", " hätten ", "gesetzt")
    'Ich schaffte es nicht. -> Er habe es nicht geschafft.
    text = ersetzeVergangenheitsform(text, " schaffte ", " habe ", "geschafft")
    'Wir schafften es. -> Sie hätten es geschafft.
    text = ersetzeVergangenheitsform(text, " schafften ", " hätten ", "geschafft")
    'Ich bezahlte es. -> Er habe es bezahlt.
    text = ersetzeVergangenheitsform(text, " bezahlte ", " habe ", "bezahlt")
    'Wir bezahlten es. -> Sie hätten es bezahlt.
    text = ersetzeVergangenheitsform(text, " bezahlten ", " hätten ", "bezahlt")
    'Ich meldete es. -> Er habe es gemeldet.
    text = ersetzeVergangenheitsform(text, " meldete ", " habe ", "gemeldet")
    'Wir meldeten es. -> Sie hätten es gemeldet.
    text = ersetzeVergangenheitsform(text, " meldeten ", " hätten ", "gemeldet")
    'Es geschah nichts. -> Es sei nichts geschehen.
    text = ersetzeVergangenheitsform(text, " geschah ", " sei ", "geschehen")
    'Ich kontaktierte ihn. -> Er habe ihn kontaktiert.
    text = ersetzeVergangenheitsform(text, " kontaktierte ", " habe ", "kontaktiert")
    'Wir kontaktierten diese. -> Sie hätten diese kontaktiert.
    text = ersetzeVergangenheitsform(text, " kontaktierten ", " hätten ", "kontaktiert")
    'Ich kontrollierte ihn. -> Er habe ihn kontrolliert.
    text = ersetzeVergangenheitsform(text, " kontrollierte ", " habe ", "kontrolliert")
    'Wir kontrollierten diese. -> Sie hätten diese kontrolliert.
    text = ersetzeVergangenheitsform(text, " kontrollierten ", " hätten ", "kontrolliert")
    'Ich schenkte es. -> Er habe es geschenkt.
    text = ersetzeVergangenheitsform(text, " schenkte ", " habe ", "geschenkt")
    'Wir schenkten es. -> Sie hätten es geschenkt.
    text = ersetzeVergangenheitsform(text, " schenkten ", " hätten ", "geschenkt")
    'Ich leistete viel. -> Er habe viel geleistet.
    text = ersetzeVergangenheitsform(text, " leistete ", " habe ", "geleistet")
    'Wir leisteten es. -> Sie hätten es geleistet.
    text = ersetzeVergangenheitsform(text, " leisteten ", " hätten ", "geleistet")
    'Ich beorderte diesen. -> Er habe diesen beordert.
    text = ersetzeVergangenheitsform(text, " beorderte ", " habe ", "beordert")
    'Wir beorderten diese. -> Sie hätten diese beordert.
    text = ersetzeVergangenheitsform(text, " beorderten ", " hätten ", "beordert")
    'Ich erzählte es. -> Er habe es erzählt.
    text = ersetzeVergangenheitsform(text, " erzählte ", " habe ", "erzählt")
    'Wir erzählten es. -> Sie hätten es erzählt.
    text = ersetzeVergangenheitsform(text, " erzählten ", " hätten ", "erzählt")
    'Ich organisierte es. -> Er habe es organisiert.
    text = ersetzeVergangenheitsform(text, " organisierte ", " habe ", "organisiert")
    'Wir organisierten es. -> Sie hätten es organisiert.
    text = ersetzeVergangenheitsform(text, " organisierten ", " hätten ", "organisiert")
    'Ich präsentierte es. -> Er habe es präsentiert.
    text = ersetzeVergangenheitsform(text, " präsentierte ", " habe ", "präsentiert")
    'Wir präsentierten es. -> Sie hätten es präsentiert.
    text = ersetzeVergangenheitsform(text, " präsentierten ", " hätten ", "präsentiert")
    'Ich suchte es. -> Er habe es gesucht.
    text = ersetzeVergangenheitsform(text, " suchte ", " habe ", "gesucht")
    'Wir suchten es. -> Sie hätten es gesucht.
    text = ersetzeVergangenheitsform(text, " suchten ", " hätten ", "gesucht")
    'Ich produzierte es. -> Er habe es produziert.
    text = ersetzeVergangenheitsform(text, " produzierte ", " habe ", "produziert")
    'Wir produzierten es. -> Sie hätten es produzisert.
    text = ersetzeVergangenheitsform(text, " produzierten ", " hätten ", "produziert")
    'Ich fehlte dort. -> Er habe dort gefehlt.
    text = ersetzeVergangenheitsform(text, " fehlte ", " habe ", "gefehlt")
    'Wir fehlten dort. -> Sie hätten dort gefehlt.
    text = ersetzeVergangenheitsform(text, " fehlten ", " hätten ", "gefehlt")
    'Ich teilte mit. -> Er habe mit geteilt.
    text = ersetzeVergangenheitsform(text, " teilte ", " habe ", "geteilt")
    'Wir teilten es. -> Sie hätten es geteilt.
    text = ersetzeVergangenheitsform(text, " teilten ", " hätten ", "geteilt")
    'Ich betreute es. -> Er habe es betreut.
    text = ersetzeVergangenheitsform(text, " betreute ", " habe ", "betreut")
    'Wir betreuten es. -> Sie hätten es betreut.
    text = ersetzeVergangenheitsform(text, " betreuten ", " hätten ", "betreut")
    'Ich strich es. -> Er habe es gestrichen.
    text = ersetzeVergangenheitsform(text, " strich ", " habe ", "gestrichen")
    'Wir strichen es. -> Sie hätten es gestrichen.
    text = ersetzeVergangenheitsform(text, " strichen ", " hätten ", "gestrichen")
    'Ich verlegte es. -> Er habe es verlegt.
    text = ersetzeVergangenheitsform(text, " verlegte ", " habe ", "verlegt")
    'Wir verlegten es. -> Sie hätten es verlegt.
    text = ersetzeVergangenheitsform(text, " verlegten ", " hätten ", "verlegt")
    'Ich bestand darauf. -> Er habe darauf bestanden.
    text = ersetzeVergangenheitsform(text, " bestand ", " habe ", "bestanden")
    'Wir bestanden darauf. -> Sie hätten darauf bestanden.
    text = ersetzeVergangenheitsform(text, " bestanden ", " hätten ", "bestanden")
    'Ich eröffnete es. -> Er habe es eröffnet.
    text = ersetzeVergangenheitsform(text, " eröffnete ", " habe ", "eröffnet")
    'Wir eröffneten es. -> Sie hätten es eröffnet.
    text = ersetzeVergangenheitsform(text, " eröffneten ", " hätten ", "eröffnet")
    'Ich sendete es. -> Er habe es gesendet.
    text = ersetzeVergangenheitsform(text, " sendete ", " habe ", "gesendet")
    'Wir sendeten es. -> Sie hätten es gesendet.
    text = ersetzeVergangenheitsform(text, " sendeten ", " hätten ", "gesendet")
    'Ich rechnete es. -> Er habe es gerechnet.
    text = ersetzeVergangenheitsform(text, " rechnete ", " habe ", "gerechnet")
    'Wir rechneten es. -> Sie hätten es gerechnet.
    text = ersetzeVergangenheitsform(text, " rechneten ", " hätten ", "gerechnet")
    'Ich stützte es. -> Er habe es gestützt.
    text = ersetzeVergangenheitsform(text, " stützte ", " habe ", "gestützt")
    'Wir stützten es. -> Sie hätten es gestützt.
    text = ersetzeVergangenheitsform(text, " stützten ", " hätten ", "gestützt")
    'Ich generierte es. -> Er habe es generiert.
    text = ersetzeVergangenheitsform(text, " generierte ", " habe ", "generiert")
    'Wir generierten es. -> Sie hätten es generiert.
    text = ersetzeVergangenheitsform(text, " generierten ", " hätten ", "generiert")
    'Ich handelte es. -> Er habe es gehandelt.
    text = ersetzeVergangenheitsform(text, " handelte ", " habe ", "gehandelt")
    'Wir handelten es. -> Sie hätten es gehandelt.
    text = ersetzeVergangenheitsform(text, " handelten ", " hätten ", "gehandelt")
    'Ich schaltete es. -> Er habe es geschaltet.
    text = ersetzeVergangenheitsform(text, " schaltete ", " habe ", "geschaltet")
    'Wir schalteten es. -> Sie hätten es geschaltet.
    text = ersetzeVergangenheitsform(text, " schalteten ", " hätten ", "geschaltet")
    'Ich fügte mich. -> Er habe sich gefügt.
    text = ersetzeVergangenheitsform(text, " fügte ", " habe ", "gefügt")
    'Wir fügten uns. -> Sie hätten sich gefügt.
    text = ersetzeVergangenheitsform(text, " fügten ", " hätten ", "gefügt")
    'Ich profitierte davon. -> Er habe davon profitiert.
    text = ersetzeVergangenheitsform(text, " profitierte ", " habe ", "profitiert")
    'Wir profitierten davon. -> Sie hätten davon profitiert.
    text = ersetzeVergangenheitsform(text, " profitierten ", " hätten ", "profitiert")
    'Ich sicherte es. -> Er habe es gesichert.
    text = ersetzeVergangenheitsform(text, " sicherte ", " habe ", "gesichert")
    'Wir sicherten es. -> Sie hätten es gesichert.
    text = ersetzeVergangenheitsform(text, " sicherten ", " hätten ", "gesichert")
    'Ich verliess es. -> Er habe es verlassen.
    text = ersetzeVergangenheitsform(text, " verliess ", " habe ", "verlassen")
    'Wir verliessen es. -> Sie hätten es verlassen.
    text = ersetzeVergangenheitsform(text, " verliessen ", " hätten ", "verlassen")
    'Ich fing es. -> Er habe es gefangen.
    text = ersetzeVergangenheitsform(text, " fing ", " habe ", "gefangen")
    'Wir fingen es. -> Sie hätten es gefangen.
    text = ersetzeVergangenheitsform(text, " fingen ", " hätten ", "gefangen")
    'Es entstand früh. -> Es sei früh entstanden.
    text = ersetzeVergangenheitsform(text, " entstand ", " sei ", "entstanden")
    'Sie entstanden früh. -> Sie seien früh entstanden.
    text = ersetzeVergangenheitsform(text, " entstanden ", " seien ", "entstanden")
    'Ich unterschrieb es. -> Er habe es unterschrieben.
    text = ersetzeVergangenheitsform(text, " unterschrieb ", " habe ", "unterschrieben")
    'Wir unterschrieben es. -> Sie hätten es unterschrieben.
    text = ersetzeVergangenheitsform(text, " unterschrieben ", " hätten ", "unterschrieben")
    'Es belief sich. -> Es habe sich belaufen.
    text = ersetzeVergangenheitsform(text, " belief ", " habe ", "belaufen")
    'Sie beliefen sich. -> Sie hätten sich belaufen.
    text = ersetzeVergangenheitsform(text, " beliefen ", " hätten ", "belaufen")
    'Ich verfügte darüber -> Er habe darüber verfügt.
    text = ersetzeVergangenheitsform(text, " verfügte ", " habe ", "verfügt")
    'Wir verfügten darüber. -> Sie hätten darüber verfügt.
    text = ersetzeVergangenheitsform(text, " verfügten ", " hätten ", "verfügt")
    'Ich erwähnte es -> Er habe es erwähnt.
    text = ersetzeVergangenheitsform(text, " erwähnte ", " habe ", "erwähnt")
    'Wir erwähnten es. -> Sie hätten es erwähnt.
    text = ersetzeVergangenheitsform(text, " erwähnten ", " hätten ", "erwähnt")
    'Ich finanzierte es -> Er habe es finanziert.
    text = ersetzeVergangenheitsform(text, " finanzierte ", " habe ", "finanziert")
    'Wir finanzierten es. -> Sie hätten es finanziert.
    text = ersetzeVergangenheitsform(text, " finanzierten ", " hätten ", "finanziert")
    'Ich herrschte darüber -> Er habe darüber geherrscht.
    text = ersetzeVergangenheitsform(text, " herrschte ", " habe ", "geherrscht")
    'Wir herschten darüber. -> Sie hätten darüber geherrscht.
    text = ersetzeVergangenheitsform(text, " herschten ", " hätten ", "geherrscht")
    'Ich tätigte es -> Er habe es getätigt.
    text = ersetzeVergangenheitsform(text, " tätigte ", " habe ", "getätigt")
    'Wir tätigten es. -> Sie hätten es getätigt.
    text = ersetzeVergangenheitsform(text, " tätigten ", " hätten ", "getätigt")
    'Es gehörte mir -> Er habe ihm gehört.
    text = ersetzeVergangenheitsform(text, " gehörte ", " habe ", "gehört")
    'Diese gehörten diesen. -> Diese hätten diesen gehört.
    text = ersetzeVergangenheitsform(text, " gehörten ", " hätten ", "gehört")
    'Ich wohnte dort -> Er habe dort gewohnt.
    text = ersetzeVergangenheitsform(text, " wohnte ", " habe ", "gewohnt")
    'Wir wohnten dort. -> Sie hätten dort gewohnt.
    text = ersetzeVergangenheitsform(text, " wohnten ", " hätten ", "gewohnt")
    'Ich wuchs -> Er sei gewachsen.
    text = ersetzeVergangenheitsform(text, " wuchs ", " sei ", "gewachsen")
    'Wir wuchsen. -> Sie seien gewachsen.
    text = ersetzeVergangenheitsform(text, " wuchsen ", " seien ", "gewachsen")
    'Ich kündigte es. -> Er habe es gekündigt.
    text = ersetzeVergangenheitsform(text, " kündigte ", " habe ", "gekündigt")
    'Wir kündigten es. -> Sie hätten es gekündigt.
    text = ersetzeVergangenheitsform(text, " kündigten ", " hätten ", "gekündigt")
    'Ich absolvierte es. -> Er habe es absolviert.
    text = ersetzeVergangenheitsform(text, " absolvierte ", " habe ", "absolviert")
    'Wir absolvierten es. -> Sie hätten es absolviert.
    text = ersetzeVergangenheitsform(text, " absolvierten ", " hätten ", "absolviert")
    'Ich klingelte dort. -> Er habe dort geklingelt.
    text = ersetzeVergangenheitsform(text, " klingelte ", " habe ", "geklingelt")
    'Wir klingelten dort. -> Sie hätten dort geklingelt.
    text = ersetzeVergangenheitsform(text, " klingelten ", " hätten ", "geklingelt")
    'Ich schickte es. -> Er habe es geschickt.
    text = ersetzeVergangenheitsform(text, " schickte ", " habe ", "geschickt")
    'Wir schickten es. -> Sie hätten es geschickt.
    text = ersetzeVergangenheitsform(text, " schickten ", " hätten ", "geschickt")
    'Ich riet davon ab. -> Er habe davon ab geraten.
    text = ersetzeVergangenheitsform(text, " riet ", " habe ", "geraten")
    'Wir rieten davon ab. -> Sie hätten davon ab geraten.
    text = ersetzeVergangenheitsform(text, " rieten ", " hätten ", "geraten")
    'Ich verstand es. -> Er habe es verstanden.
    text = ersetzeVergangenheitsform(text, " verstand ", " habe ", "verstanden")
    'Ich gewährte es. -> Er habe es gewährt.
    text = ersetzeVergangenheitsform(text, " gewährte ", " habe ", "gewährt")
    'Wir gewährten es. -> Sie hätten es gewahrt.
    text = ersetzeVergangenheitsform(text, " gewährten ", " hätten ", "gewährt")
    'Ich realisierte es. -> Er habe es realisiert.
    text = ersetzeVergangenheitsform(text, " realisierte ", " habe ", "realisiert")
    'Wir realisierten es. -> Sie hätten es realisiert.
    text = ersetzeVergangenheitsform(text, " realisierten ", " hätten ", "realisiert")
    'Ich veranstaltete es. -> Er habe es veranstaltet.
    text = ersetzeVergangenheitsform(text, " veranstaltete ", " habe ", "veranstaltet")
    'Wir veranstalteten es. -> Sie hätten es veranstaltet.
    text = ersetzeVergangenheitsform(text, " veranstalteten ", " hätten ", "veranstaltet")
    'Ich wählte es. -> Er habe es gewählt.
    text = ersetzeVergangenheitsform(text, " wählte ", " habe ", "gewählt")
    'Wir wählten es. -> Sie hätten es gewählt.
    text = ersetzeVergangenheitsform(text, " wählten ", " hätten ", "gewählt")
    'Ich löste es. -> Er habe es gelöst.
    text = ersetzeVergangenheitsform(text, " löste ", " habe ", "gelöst")
    'Wir lösten es. -> Sie hätten es gelöst.
    text = ersetzeVergangenheitsform(text, " lösten ", " hätten ", "gelöst")
    'Ich trat es. -> Er habe es getreten.
    text = ersetzeVergangenheitsform(text, " trat ", " habe ", "getreten")
    'Wir traten es. -> Sie hätten es getreten.
    text = ersetzeVergangenheitsform(text, " traten ", " hätten ", "getreten")
    'Ich monierte es. -> Er habe es moniert.
    text = ersetzeVergangenheitsform(text, " monierte ", " habe ", "moniert")
    'Wir monierten es. -> Sie hätten es moniert.
    text = ersetzeVergangenheitsform(text, " monierten ", " hätten ", "moniert")
    'Ich merkte es. -> Er habe es gemerkt.
    text = ersetzeVergangenheitsform(text, " merkte ", " habe ", "gemerkt")
    'Wir merkten es. -> Sie hätten es gemerkt.
    text = ersetzeVergangenheitsform(text, " merkten ", " hätten ", "gemerkt")
    'Es fruchtete nicht. -> Es habe nicht gefruchtet.
    text = ersetzeVergangenheitsform(text, " fruchtete ", " habe ", "gefruchtet")
    'Sie fruchteten nicht. -> Diese hätten nicht gefruchtet.
    text = ersetzeVergangenheitsform(text, " fruchteten ", " hätten ", "gefruchtet")
    'Ich verniedlichte es. -> Er habe es verniedlicht.
    text = ersetzeVergangenheitsform(text, " verniedlichte ", " habe ", "verniedlicht")
    'Wir verniedlichten es. -> Sie hätten es verniedlicht.
    text = ersetzeVergangenheitsform(text, " verniedlichten ", " hätten ", "verniedlicht")
    'Ich beschönigte es. -> Er habe es beschönigt.
    text = ersetzeVergangenheitsform(text, " beschönigte ", " habe ", "beschönigt")
    'Wir beschönigten es. -> Sie hätten es beschönigt.
    text = ersetzeVergangenheitsform(text, " beschönigten ", " hätten ", "beschönigt")
    'Ich rastete dort. -> Er habe dort gerastet.
    text = ersetzeVergangenheitsform(text, " rastete ", " habe ", "gerastet")
    'Wir rasteten dort. -> Sie hätten dort gerastet.
    text = ersetzeVergangenheitsform(text, " rasteten ", " hätten ", "gerastet")
    'Ich befürchtete es. -> Er habe es befürchtet.
    text = ersetzeVergangenheitsform(text, " befürchtete ", " habe ", "befürchtet")
    'Wir befürchteten es. -> Sie hätten es befürchtet.
    text = ersetzeVergangenheitsform(text, " befürchteten ", " hätten ", "befürchtet")
    'Ich wünschte es. -> Er habe es gewünscht.
    text = ersetzeVergangenheitsform(text, " wünschte ", " habe ", "gewünscht")
    'Wir wünschten es. -> Sie hätten es gewünscht.
    text = ersetzeVergangenheitsform(text, " wünschten ", " hätten ", "gewünscht")
    'Ich betrieb es. -> Er habe es betrieben.
    text = ersetzeVergangenheitsform(text, " betrieb ", " habe ", "betrieben")
    'Wir betrieben es. -> Sie hätten es betrieben.
    text = ersetzeVergangenheitsform(text, " betrieben ", " hätten ", "betrieben")
    'Ich vereinbarte es. -> Er habe es vereinbart.
    text = ersetzeVergangenheitsform(text, " vereinbarte ", " habe ", "vereinbart")
    'Wir vereinbarten es. -> Sie hätten es vereinbart.
    text = ersetzeVergangenheitsform(text, " vereinbarten ", " hätten ", "vereinbart")
    'Wir gingen dorthin. -> Sie seien dorthin gegangen.
    text = ersetzeVergangenheitsform(text, " gingen ", " seien ", "gegangen")
    'Ich unterzeichnete es. -> Er habe es unterzeichnet.
    text = ersetzeVergangenheitsform(text, " unterzeichnete ", " habe ", "unterzeichnet")
    'Ich informierte darüber. -> Er habe darüber informiert.
    text = ersetzeVergangenheitsform(text, " informierte ", " habe ", "informiert")
    'Wir informierten darüber. -> Sie hätten darüber informiert.
    text = ersetzeVergangenheitsform(text, " informierten ", " hätten ", "informiert")
    'Ich erfuhr es. -> Er habe es erfahren.
    text = ersetzeVergangenheitsform(text, " erfuhr ", " habe ", "erfahren")
    'Wir erfuhren es. -> Sie hätten es erfahren.
    text = ersetzeVergangenheitsform(text, " erfuhren ", " hätten ", "erfahren")
    'Ich streckte es. -> Er habe es gestreckt.
    text = ersetzeVergangenheitsform(text, " streckte ", " habe ", "gestreckt")
    'Wir streckten es. -> Sie hätten es gestreckt.
    text = ersetzeVergangenheitsform(text, " streckten ", " hätten ", "gestreckt")
    'Ich druckte es. -> Er habe es gedruckt.
    text = ersetzeVergangenheitsform(text, " druckte ", " habe ", "gedruckt")
    'Wir druckten es. -> Sie hätten es gedruckt.
    text = ersetzeVergangenheitsform(text, " druckten ", " hätten ", "gedruckt")
    'Ich bejahte es. -> Er habe es bejaht.
    text = ersetzeVergangenheitsform(text, " bejahte ", " habe ", "bejaht")
    'Wir bejahten es. -> Sie hätten es bejaht.
    text = ersetzeVergangenheitsform(text, " bejahten ", " hätten ", "bejaht")
    'Ich verneinte es. -> Er habe es verneint.
    text = ersetzeVergangenheitsform(text, " verneinte ", " habe ", "verneint")
    'Wir verneinten es. -> Sie hätten es verneint.
    text = ersetzeVergangenheitsform(text, " verneinten ", " hätten ", "verneint")
    'Ich leitete es. -> Er habe es geleitet.
    text = ersetzeVergangenheitsform(text, " leitete ", " habe ", "geleitet")
    'Wir leiteten es. -> Sie hätten es geleitet.
    text = ersetzeVergangenheitsform(text, " leiteten ", " hätten ", "geleitet")
    'Ich beauftragte es. -> Er habe es beauftragt.
    text = ersetzeVergangenheitsform(text, " beauftragte ", " habe ", "beauftragt")
    'Wir beauftragten es. -> Sie hätten es beauftragt.
    text = ersetzeVergangenheitsform(text, " beauftragten ", " hätten ", "beauftragt")
    'Ich speicherte es. -> Er habe es gespeichert.
    text = ersetzeVergangenheitsform(text, " speicherte ", " habe ", "gespeichert")
    'Wir speicherten es. -> Sie hätten es gespeichert.
    text = ersetzeVergangenheitsform(text, " speicherten ", " hätten ", "gespeichert")
    'Ich überliess es. -> Er habe es überlassen.
    text = ersetzeVergangenheitsform(text, " überliess ", " habe ", "überlassen")
    'Wir überliessen es. -> Sie hätten es überlassen.
    text = ersetzeVergangenheitsform(text, " überliessen ", " hätten ", "überlassen")
    'Ich kehrte zurück. -> Er sei zurück gekehrt.
    text = ersetzeVergangenheitsform(text, " kehrte ", " sei ", "gekehrt")
    'Wir kehrten zurück. -> Sie seien zurück gekehrt.
    text = ersetzeVergangenheitsform(text, " kehrten ", " seien ", "gekehrt")
    'Ich beruhigte mich. -> Er habe sich beruhigt.
    text = ersetzeVergangenheitsform(text, " beruhigte ", " habe ", "beruhigt")
    'Wir beruhigten es. -> Sie hätten sich beruhigt.
    text = ersetzeVergangenheitsform(text, " beruhigten ", " hätten ", "beruhigt")
    'Ich erwartete es. -> Er habe es erwartet.
    text = ersetzeVergangenheitsform(text, " erwartete ", " habe ", "erwartet")
    'Wir erwarteten es. -> Sie hätten es erwartet.
    text = ersetzeVergangenheitsform(text, " erwarteten ", " hätten ", "erwartet")
    'Ich kümmerte mich. -> Er habe sich gekümmert.
    text = ersetzeVergangenheitsform(text, " kümmerte ", " habe ", "gekümmert")
    'Wir kümmerten uns. -> Sie hätten sich gekümmert.
    text = ersetzeVergangenheitsform(text, " kümmerten ", " hätten ", "gekümmert")
    'Ich drohte ihm. -> Er habe ihm gedroht.
    text = ersetzeVergangenheitsform(text, " drohte ", " habe ", "gedroht")
    'Wir drohten diesen. -> Sie hätten diesen gedroht.
    text = ersetzeVergangenheitsform(text, " drohten ", " hätten ", "gedroht")
    'Ich bezog es. -> Er habe es bezogen.
    text = ersetzeVergangenheitsform(text, " bezog ", " habe ", "bezogen")
    'Wir bezogen es. -> Sie hätten es bezogen.
    text = ersetzeVergangenheitsform(text, " bezogen ", " hätten ", "bezogen")
    'Ich erachtete es. -> Er habe es erachtet.
    text = ersetzeVergangenheitsform(text, " erachtete ", " habe ", "erachtet")
    'Wir erachteten es. -> Sie hätten es erachtet.
    text = ersetzeVergangenheitsform(text, " erachteten ", " hätten ", "erachtet")
    'Ich unterschrieb es. -> Er habe es unterschrieben.
    text = ersetzeVergangenheitsform(text, " unterschrieb ", " habe ", "unterschrieben")
    'Ich berichtete es. -> Er habe es berichtet.
    text = ersetzeVergangenheitsform(text, " berichtete ", " habe ", "berichtet")
    'Wir berichteten es. -> Sie hätten es berichtet.
    text = ersetzeVergangenheitsform(text, " berichteten ", " hätten ", "berichtet")
    'Ich nannte es. -> Er habe es genannt.
    text = ersetzeVergangenheitsform(text, " nannte ", " habe ", "genannt")
    'Wir nannten es. -> Sie hätten es genannt.
    text = ersetzeVergangenheitsform(text, " nannten ", " hätten ", "genannt")
    'Ich beschloss es. -> Er habe es beschlossen.
    text = ersetzeVergangenheitsform(text, " beschloss ", " habe ", "beschlossen")
    'Wir beschlossen es. -> Sie hätten es beschlossen.
    text = ersetzeVergangenheitsform(text, " beschlossen ", " hätten ", "beschlossen")
    'Ich besprach es. -> Er habe es besprochen.
    text = ersetzeVergangenheitsform(text, " besprach ", " habe ", "besprochen")
    'Wir besprachen es. -> Sie hätten es besprochen.
    text = ersetzeVergangenheitsform(text, " besprachen ", " hätten ", "besprochen")
    'Es dauerte. -> Es habe gedauert.
    text = ersetzeVergangenheitsform(text, " dauerte ", " habe ", "gedauert")
    'Sie dauerten -> Sie hätten gedauert.
    text = ersetzeVergangenheitsform(text, " dauerten ", " hätten ", "gedauert")
    'Ich richtete es ein. -> Er habe es ein gerichtet.
    text = ersetzeVergangenheitsform(text, " richtete ", " habe ", "gerichtet")
    'Wir richteten es aus. -> Sie hätten es aus gerichtet.
    text = ersetzeVergangenheitsform(text, " richteten ", " hätten ", "gerichtet")
    'Ich erstellte es. -> Er habe es erstellt.
    text = ersetzeVergangenheitsform(text, " erstellte ", " habe ", "erstellt")
    'Wir erstellten es. -> Sie hätten es erstellt.
    text = ersetzeVergangenheitsform(text, " erstellten ", " hätten ", "erstellt")
    'Ich entnahm es. -> Er habe es entnommen.
    text = ersetzeVergangenheitsform(text, " entnahm ", " habe ", "entnommen")
    'Wir entnahmen es. -> Sie hätten es entnommen.
    text = ersetzeVergangenheitsform(text, " entnahmen ", " hätten ", "entnommen")
    'Ich entschloss es. -> Er habe es entschlossen.
    text = ersetzeVergangenheitsform(text, " entschloss ", " habe ", "entschlossen")
    'Wir entschlossen es. -> Sie hätten es entschlossen.
    text = ersetzeVergangenheitsform(text, " entschlossen ", " hätten ", "entschlossen")
    'Ich schwärmte davon. -> Er habe davon geschwärmt.
    text = ersetzeVergangenheitsform(text, " schwärmte ", " habe ", "geschwärmt")
    'Wir schwärmten davon. -> Sie hätten davon geschwärmt.
    text = ersetzeVergangenheitsform(text, " schwärmten ", " hätten ", "geschwärmt")
    'Ich beteiligte mich. -> Er habe sich beteiligt.
    text = ersetzeVergangenheitsform(text, " beteiligte ", " habe ", "beteiligt")
    'Ich wies ihn an. -> Er habe diesen an gewiesen.
    text = ersetzeVergangenheitsform(text, " wies ", " habe ", "gewiesen")
    'Wir wiesen ihn an. -> Sie hätten diesen an gewiesen.
    text = ersetzeVergangenheitsform(text, " wiesen ", " hätten ", "gewiesen")
    'Ich forderte es. -> Er habe es gefordert.
    text = ersetzeVergangenheitsform(text, " forderte ", " habe ", "gefordert")
    'Wir forderten es. -> Sie hätten es gefordert.
    text = ersetzeVergangenheitsform(text, " forderten ", " hätten ", "gefordert")
    'Ich sandte es. -> Er habe es gesendet.
    text = ersetzeVergangenheitsform(text, " sandte ", " habe ", "gesendet")
    'Wir sandten es. -> Sie hätten es gesendet.
    text = ersetzeVergangenheitsform(text, " sandten ", " hätten ", "gesendet")
    'Ich hoffte es. -> Er habe es gehofft.
    text = ersetzeVergangenheitsform(text, " hoffte ", " habe ", "gehofft")
    'Wir hofften es. -> Sie hätten es gehofft.
    text = ersetzeVergangenheitsform(text, " hofften ", " hätten ", "gehofft")
    'Ich forschte darüber. -> Er habe darüber geforscht.
    text = ersetzeVergangenheitsform(text, " forschte ", " habe ", "geforscht")
    'Wir forschten darüber. -> Sie hätten darüber geforscht.
    text = ersetzeVergangenheitsform(text, " forschten ", " hätten ", "geforscht")
    'Ich investierte es. -> Er habe es investiert.
    text = ersetzeVergangenheitsform(text, " investierte ", " habe ", "investiert")
    'Wir investierten es. -> Sie hätten es investiert.
    text = ersetzeVergangenheitsform(text, " investierten ", " hätten ", "investiert")
    'Ich entsprach den Erwartungen. -> Er habe den Erwartungen entsprochen.
    text = ersetzeVergangenheitsform(text, " entsprach ", " habe ", "entsprochen")
    'Wir entsprachen dem Anliegen. -> Sie hätten dem Anliegen entsprochen.
    text = ersetzeVergangenheitsform(text, " entsprachen ", " hätten ", "entsprochen")
    'Ich versicherte es. -> Er habe es versichert.
    text = ersetzeVergangenheitsform(text, " versicherte ", " habe ", "versichert")
    'Wir versicherten es. -> Sie hätten es versichert.
    text = ersetzeVergangenheitsform(text, " versicherten ", " hätten ", "versichert")
    'Ich entwickelte es. -> Er habe es entwickelt.
    text = ersetzeVergangenheitsform(text, " entwickelte ", " habe ", "entwickelte")
    'Ich vermarktete es. -> Er habe es vermarktet.
    text = ersetzeVergangenheitsform(text, " vermarktet ", " habe ", "vermarktet")
    'Wir vermarkteten es. -> Sie hätten es vermarktet.
    text = ersetzeVergangenheitsform(text, " vermarkteten ", " hätten ", "vermarktet")
    'Ich leaste es. -> Er habe es geleast.
    text = ersetzeVergangenheitsform(text, " leaste ", " habe ", "geleast")
    'Wir leasten es. -> Sie hätten es geleast.
    text = ersetzeVergangenheitsform(text, " leasten ", " hätten ", "geleast")
    'Ich begründete es. -> Er habe es begründet.
    text = ersetzeVergangenheitsform(text, " begründete ", " habe ", "begründet")
    'Ich existierte nicht. -> Er habe nicht existiert.
    text = ersetzeVergangenheitsform(text, " existierte ", " habe ", "existiert")
    'Wir existierten nicht. -> Sie hätten nicht existiert.
    text = ersetzeVergangenheitsform(text, " existierten ", " hätten ", "existiert")
    'Ich veröffentlichte es. -> Er habe es veröffentlicht.
    text = ersetzeVergangenheitsform(text, " veröffentlichte ", " habe ", "veröffentlicht")
    'Ich überwies es. -> Er habe es überwiesen.
    text = ersetzeVergangenheitsform(text, " überwies ", " habe ", "überwiesen")
    'Wir überwiesen es. -> Sie hätten es überwiesen.
    text = ersetzeVergangenheitsform(text, " überwiesen ", " hätten ", "überwiesen")
    'Ich entgegnete es. -> Er habe es entgegnet.
    text = ersetzeVergangenheitsform(text, " entgegnete ", " habe ", "entgegnet")
    'Wir entgegneten es. -> Sie hätten es entgegnet.
    text = ersetzeVergangenheitsform(text, " entgegneten ", " hätten ", "entgegnet")
    'Es floss den Bach runter. -> Es sei den Bach runter geflossen.
    text = ersetzeVergangenheitsform(text, " floss ", " sei ", "geflossen")
    'Wir flossen den Bach runter. -> Sie seien den Bach runter geflossen.
    text = ersetzeVergangenheitsform(text, " flossen ", " seien ", "geflossen")
    'Ich besuchte es. -> Er habe es besucht.
    text = ersetzeVergangenheitsform(text, " besuchte ", " habe ", "besucht")
    'Ich stoppte es. -> Er habe es gestoppt.
    text = ersetzeVergangenheitsform(text, " stoppte ", " habe ", "gestoppt")
    'Wir stoppten es. -> Sie hätten es gestoppt.
    text = ersetzeVergangenheitsform(text, " stoppten ", " hätten ", "gestoppt")
    'Ich kritisierte es. -> Er habe es kritisiert.
    text = ersetzeVergangenheitsform(text, " kritisierte ", " habe ", "kritisiert")
    'Wir kritisierten es. -> Sie hätten es kritisiert.
    text = ersetzeVergangenheitsform(text, " kritisierten ", " hätten ", "kritisiert")
    'Ich empfand es. -> Er habe es empfunden.
    text = ersetzeVergangenheitsform(text, " empfand ", " habe ", "empfunden")
    'Wir empfanden es. -> Sie hätten es empfunden.
    text = ersetzeVergangenheitsform(text, " empfanden ", " hätten ", "empfunden")
    'Ich sollte es. -> Er habe es sollen.
    text = ersetzeVergangenheitsform(text, " sollte ", " habe ", "sollen")
    'Wir sollten es. -> Sie hätten es sollen.
    text = ersetzeVergangenheitsform(text, " sollten ", " hätten ", "sollen")
    'Ich erbrachte es. -> Er habe es erbracht.
    text = ersetzeVergangenheitsform(text, " erbrachte ", " habe ", "erbracht")
    'Wir erbrachten es. -> Sie hätten es erbracht.
    text = ersetzeVergangenheitsform(text, " erbrachten ", " hätten ", "erbracht")
    'Ich kommunizierte es. -> Er habe es kommuniziert.
    text = ersetzeVergangenheitsform(text, " kommunizierte ", " habe ", "kommuniziert")
    'Ich einigte mich. -> Er habe sich geeinigt.
    text = ersetzeVergangenheitsform(text, " einigte ", " habe ", "geeinigt")
    'Wir einigten uns. -> Sie hätten sich geeinigt.
    text = ersetzeVergangenheitsform(text, " einigten ", " hätten ", "geeinigt")
    'Ich gewann es. -> Er habe es gewonnen.
    text = ersetzeVergangenheitsform(text, " gewann ", " habe ", "gewonnen")
    'Wir gewannen es. -> Sie hätten es gewonnen.
    text = ersetzeVergangenheitsform(text, " gewannen ", " hätten ", "gewonnen")
    'Ich verlor es. -> Er habe es verloren.
    text = ersetzeVergangenheitsform(text, " verlor ", " habe ", "verloren")
    'Es oblag diesem. -> Es sei diesem obliegen.
    text = ersetzeVergangenheitsform(text, " oblag ", " sei ", "obliegen")
    'Sie oblagen uns. -> Sie seien ihnen obliegen.
    text = ersetzeVergangenheitsform(text, " oblagen ", " seien ", "obliegen")
    'Ich brach ein. -> Er sei ein gebrochen.
    text = ersetzeVergangenheitsform(text, " brach ", " sei ", "gebrochen")
    'Wir brachen ein. -> Sie seien ein gebrochen.
    text = ersetzeVergangenheitsform(text, " brachen ", " seien ", "gebrochen")
    'Ich wechselte es. -> Er habe es gewechselt.
    text = ersetzeVergangenheitsform(text, " wechselte ", " habe ", "gewechselt")
    'Wir wechselten es. -> Sie hätten es gewechselt.
    text = ersetzeVergangenheitsform(text, " wechselten ", " hätten ", "gewechselt")
    'Ich gab es heraus -> er habe es herausgegeben
    text = ersetzeVergangenheitsform(text, " gab ", " habe ", "gegeben")
    'Wir gaben es heraus. -> Sie hätten es heraus gegeben.
    text = ersetzeVergangenheitsform(text, " gaben ", " hätten ", "gegeben")
    'Ich schädigte es -> er habe es geschädigt.
    text = ersetzeVergangenheitsform(text, " schädigte ", " habe ", "geschädigt")
    'Wir schädigten es . -> Sie hätten es geschädigt.
    text = ersetzeVergangenheitsform(text, " schädigten ", " hätten ", "geschädigt")
    'Ich füllte es -> er habe es gefüllt.
    text = ersetzeVergangenheitsform(text, " füllte ", " habe ", "gefüllt")
    'Wir füllten es . -> Sie hätten es gefüllt.
    text = ersetzeVergangenheitsform(text, " füllten ", " hätten ", "gefüllt")
    'Ich zeichnete es -> er habe es gezeichnet.
    text = ersetzeVergangenheitsform(text, " zeichnete ", " habe ", "gezeichnet")
    'Wir zeichneten es . -> Sie hätten es gezeichnet.
    text = ersetzeVergangenheitsform(text, " zeichneten ", " hätten ", "gezeichnet")
    'Es lautete auf -> Es habe auf gelautet.
    text = ersetzeVergangenheitsform(text, " lautete ", " habe ", "gelautet")
    'Sie lauteten auf -> Sie hätten auf gelautet.
    text = ersetzeVergangenheitsform(text, " lauteten ", " hätten ", "gelautet")


    VergangenheitsVerbenErsetzung = text

End Function

Function VerbenZusammenfuegung(ByVal textstelle As String, verbenpaar As String, zusammenfuegung As String) As String
'
'fügt zusammengehörende Verbenbruchteile wie z.B. "zusammen gefügt" zusammen
'
'

Dim RegexObject As Object
Set RegexObject = CreateObject("VBScript.RegExp")
RegexObject.Global = True 'Nach mehreren Vorkommen suchen
RegexObject.Pattern = verbenpaar
VerbenZusammenfuegung = RegexObject.Replace(textstelle, zusammenfuegung)

End Function

Function VerbenZusammenfuegen(text As String)
    
    text = VerbenZusammenfuegung(text, "zurück gehalten", "zurückgehalten")
    text = VerbenZusammenfuegung(text, "an gerufen", "angerufen")
    text = VerbenZusammenfuegung(text, "ab geraten", "abgeraten")
    text = VerbenZusammenfuegung(text, "zu gemacht", "zugemacht")
    text = VerbenZusammenfuegung(text, "vor gesehen", "vorgesehen")
    text = VerbenZusammenfuegung(text, "an gefragt", "angefragt")
    text = VerbenZusammenfuegung(text, "ab gestützt", "abgestützt")
    text = VerbenZusammenfuegung(text, "heraus gekommen", "herausgekommen")
    text = VerbenZusammenfuegung(text, "aus gewählt", "ausgewählt")
    text = VerbenZusammenfuegung(text, "heraus gerückt", "herausgerückt")
    text = VerbenZusammenfuegung(text, "rein komme", "reinkomme")
    text = VerbenZusammenfuegung(text, "aus gegangen", "ausgegangen")
    text = VerbenZusammenfuegung(text, "entgegen genommen", "entgegengenommen")
    text = VerbenZusammenfuegung(text, "heraus gestellt", "herausgestellt")
    text = VerbenZusammenfuegung(text, "aus gelöst", "ausgelöst")
    text = VerbenZusammenfuegung(text, "ab getreten", "abgetreten")
    text = VerbenZusammenfuegung(text, "aus gesehen", "ausgesehen")
    text = VerbenZusammenfuegung(text, "vor gestellt", "vorgestellt")
    text = VerbenZusammenfuegung(text, "zu gegangen", "zugegangen")
    text = VerbenZusammenfuegung(text, "statt gefunden", "stattgefunden")
    text = VerbenZusammenfuegung(text, "aus gerastet", "ausgerastet")
    text = VerbenZusammenfuegung(text, "ein gegangen", "eingegangen")
    text = VerbenZusammenfuegung(text, "kennen gelernt", "kennengelernt")
    text = VerbenZusammenfuegung(text, "weiter gefahren", "weitergefahren")
    text = VerbenZusammenfuegung(text, "an gefragt", "angefragt")
    text = VerbenZusammenfuegung(text, "an gefallen", "angefallen")
    text = VerbenZusammenfuegung(text, "zu gestellt", "zugestellt")
    text = VerbenZusammenfuegung(text, "weg gegangen", "weggegangen")
    text = VerbenZusammenfuegung(text, "hin gestreckt", "hingestreckt")
    text = VerbenZusammenfuegung(text, "aus gedruckt", "ausgedruckt")
    text = VerbenZusammenfuegung(text, "hin gehalten", "hingehalten")
    text = VerbenZusammenfuegung(text, "nach geführt", "nachgeführt")
    text = VerbenZusammenfuegung(text, "ab gespeichert", "abgespeichert")
    text = VerbenZusammenfuegung(text, "aus geführt", "ausgeführt")
    text = VerbenZusammenfuegung(text, "auf genommen", "aufgenommen")
    text = VerbenZusammenfuegung(text, "zurück gekehrt", "zurückgekehrt")
    text = VerbenZusammenfuegung(text, "mit bekommen", "mitbekommen")
    text = VerbenZusammenfuegung(text, "hervor gekommen", "hervorgekommen")
    text = VerbenZusammenfuegung(text, "herüber gekommen", "herübergekommen")
    text = VerbenZusammenfuegung(text, "weg gekommen", "weggekommen")
    text = VerbenZusammenfuegung(text, "runter gekommen", "runtergekommen")
    text = VerbenZusammenfuegung(text, "rauf gekommen", "raufgekommen")
    text = VerbenZusammenfuegung(text, "rauf gegangen", "raufgegangen")
    text = VerbenZusammenfuegung(text, "runter gegangen", "runtergegangen")
    text = VerbenZusammenfuegung(text, "heim gegangen", "heimgegangen")
    text = VerbenZusammenfuegung(text, "heim gekommen", "heimgekommen")
    text = VerbenZusammenfuegung(text, "vor gekommen", "vorgekommen")
    text = VerbenZusammenfuegung(text, "hervor gegangen", "hervorgegangen")
    text = VerbenZusammenfuegung(text, "nach gefragt", "nachgefragt")
    text = VerbenZusammenfuegung(text, "zurück gekommen", "zurückgekommen")
    text = VerbenZusammenfuegung(text, "hin gekommen", "hingekommen")
    text = VerbenZusammenfuegung(text, "kennen zu lernen", "kennenzulernen")
    text = VerbenZusammenfuegung(text, "mit geteilt", "mitgeteilt")
    text = VerbenZusammenfuegung(text, "los gegangen", "losgegangen")
    text = VerbenZusammenfuegung(text, "an geschaut", "angeschaut")
    text = VerbenZusammenfuegung(text, "ein gerichtet", "eingerichtet")
    text = VerbenZusammenfuegung(text, "aus gerichtet", "ausgerichtet")
    text = VerbenZusammenfuegung(text, "vor gelegen", "vorgelegen")
    text = VerbenZusammenfuegung(text, "ab gelaufen", "abgelaufen")
    text = VerbenZusammenfuegung(text, "durch geführt", "durchgeführt")
    text = VerbenZusammenfuegung(text, "fest gestellt", "festgestellt")
    text = VerbenZusammenfuegung(text, "an gekündigt", "angekündigt")
    text = VerbenZusammenfuegung(text, "an gewiesen", "angewiesen")
    text = VerbenZusammenfuegung(text, "hin gewiesen", "hingewiesen")
    text = VerbenZusammenfuegung(text, "an gemeldet", "angemeldet")
    text = VerbenZusammenfuegung(text, "auf gefordert", "aufgefordert")
    text = VerbenZusammenfuegung(text, "an gefordert", "angefordert")
    text = VerbenZusammenfuegung(text, "ab gesagt", "abgesagt")
    text = VerbenZusammenfuegung(text, "zu gesagt", "zugesagt")
    text = VerbenZusammenfuegung(text, "ein bezahlt", "einbezahlt")
    text = VerbenZusammenfuegung(text, "nach gedacht", "nachgedacht")
    text = VerbenZusammenfuegung(text, "ein gestiegen", "eingestiegen")
    text = VerbenZusammenfuegung(text, "ab gehoben", "abgehoben")
    text = VerbenZusammenfuegung(text, "aus gesagt", "ausgesagt")
    text = VerbenZusammenfuegung(text, "teil genommen", "teilgenommen")
    text = VerbenZusammenfuegung(text, "klar gemacht", "klargemacht")
    text = VerbenZusammenfuegung(text, "fest gehalten", "festgehalten")
    text = VerbenZusammenfuegung(text, "auf gehalten", "aufgehalten")
    text = VerbenZusammenfuegung(text, "durch gehalten", "durchgehalten")
    text = VerbenZusammenfuegung(text, "durch gegeben", "durchgegeben")
    text = VerbenZusammenfuegung(text, "hinzu gekommen", "hinzugekommen")
    text = VerbenZusammenfuegung(text, "ein gebrochen", "eingebrochen")
    text = VerbenZusammenfuegung(text, "heraus gegeben", "herausgegeben")
    text = VerbenZusammenfuegung(text, "rein gesehen", "reingesehen")
    text = VerbenZusammenfuegung(text, "vorbei gekommen", "vorbeigekommen")
    text = VerbenZusammenfuegung(text, "ein gestanden", "eingestanden")
    text = VerbenZusammenfuegung(text, "vor gelegt", "vorgelegt")
    text = VerbenZusammenfuegung(text, "weiter geleitet", "weitergeleitet")
    text = VerbenZusammenfuegung(text, "aus gefüllt", "ausgefüllt")
    text = VerbenZusammenfuegung(text, "vorbei gebracht", "vorbeigebracht")

    VerbenZusammenfuegen = text

End Function

Function BelegstelleHinzufuegen(ByVal textstelle As String) As String
'
'Fügt vor dem letzten Punkt zwei Klammern () ein.
'
'

'Durch die folgende Initialisierung (2 Zeilen) des regexObject bedarf es keiner Einbindung durch Extras -> Verweise -> Microsoft VBScript Regular Expressions 5.5 mehr
Dim RegexObject As Object
Dim BelegstellenVerweis As String
Set RegexObject = CreateObject("VBScript.RegExp")
RegexObject.Global = False 'nicht nach mehreren Vorkommen suchen
RegexObject.MultiLine = False 'nicht das Ende jeder Zeile anschauen
RegexObject.Pattern = "\.\W*$" 'Entspricht dem letzten Punkt und einem oder mehreren Leerzeichen oder Umschlagzeichen am ende
BelegstellenVerweis = "Ziff."
BelegstelleHinzufuegen = RegexObject.Replace(textstelle, " (" + BelegstellenVerweis + Chr(160) + "). ")

End Function

Function DoppelpunktHinzufuegen(ByVal textstelle As String) As String
'
'Fügt vor dem letzten Punkt zwei Klammern () ein.
'
'

'Durch die folgende Initialisierung (2 Zeilen) des regexObject bedarf es keiner Einbindung durch Extras -> Verweise -> Microsoft VBScript Regular Expressions 5.5 mehr
Dim RegexObject As Object
Set RegexObject = CreateObject("VBScript.RegExp")
RegexObject.Global = False 'nicht nach mehreren Vorkommen suchen
RegexObject.MultiLine = False 'nicht das Ende jeder Zeile anschauen
RegexObject.Pattern = "[\?\.\W]*$" 'erfasst entweder ein Fragezeichen (?), einen Punkt (.) oder ein nicht alphanumerisches Zeichen (\W). Das *-Quantifier bedeutet, dass dieses Muster null oder mehrmals vorkommen kann.
DoppelpunktHinzufuegen = RegexObject.Replace(textstelle, ": ")

End Function


Function MoveCursorBackThreeSteps() 'Diese Funktion hat chatgpt am 22.03.2023 erstellt
' This program moves the cursor three steps back in Word
' Declare a variable to store the current selection
Dim sel As Selection
' Set the variable to the current selection
Set sel = Application.Selection
' Check if the selection is not empty
If sel.Type <> wdSelectionIP Then
    ' Collapse the selection to its start point
    sel.Collapse Direction:=wdCollapseStart
End If
' Move the cursor three characters to the left
sel.MoveLeft Unit:=wdCharacter, Count:=3
End Function

Sub AussageMannEinfuegen()
'
'Nimmt Text aus der Zwischenablage und führt damit die ZeilenumbruchEntfernen, die PronomenErsetzungMaennlich und die VerbenErsetzung Funktion durch und gibt den Text wieder aus
'
'
    Dim sel_text As String
    sel_text = ClipBoard_GetData()
    sel_text = FunctionZeilenumbruecheEntfernen(sel_text)
    sel_text = EntferneWorttrennungenImText(sel_text)
    sel_text = SpezifischeFormatierungen(sel_text)
    sel_text = RegelmaessigeOCRFehlerErsetzung(sel_text)
    sel_text = PronomenErsetzungMaennlich(sel_text)
    sel_text = VergangenheitsVerbenErsetzung(sel_text)
    sel_text = VerbenErsetzung(sel_text)
    sel_text = VerbenZusammenfuegen(sel_text)
    sel_text = BelegstelleHinzufuegen(sel_text)
    Selection.TypeText text:=sel_text
    Call MoveCursorBackThreeSteps
    
End Sub


Sub AussageFrauEinfuegen()
'
'Nimmt den Text aus der Zwischenablage und führt damit die ZeilenumbruchEntfernen, die PronomenErsetzungWeiblich und die VerbenErsetzung Funktion durch und gibt den Text wieder aus
'
'
    Dim sel_text As String
    sel_text = ClipBoard_GetData()
    sel_text = FunctionZeilenumbruecheEntfernen(sel_text)
    sel_text = EntferneWorttrennungenImText(sel_text)
    sel_text = SpezifischeFormatierungen(sel_text)
    sel_text = RegelmaessigeOCRFehlerErsetzung(sel_text)
    sel_text = PronomenErsetzungWeiblich(sel_text)
    sel_text = VergangenheitsVerbenErsetzung(sel_text)
    sel_text = VerbenErsetzung(sel_text)
    sel_text = VerbenZusammenfuegen(sel_text)
    sel_text = BelegstelleHinzufuegen(sel_text)
    Selection.TypeText text:=sel_text
    Call MoveCursorBackThreeSteps
    
End Sub


Sub PDFTextEinfuegen()
'
'Führt mit dem Text aus der Zwischanablage lediglich Zeilenumbrueche etc. aus
'
'
    Dim sel_text As String
    sel_text = ClipBoard_GetData()
    sel_text = FunctionZeilenumbruecheEntfernen(sel_text)
    sel_text = EntferneWorttrennungenImText(sel_text)
    sel_text = SpezifischeFormatierungen(sel_text)
    sel_text = RegelmaessigeOCRFehlerErsetzung(sel_text)
    Selection.TypeText text:=sel_text
    
End Sub

Sub FrageAnMannEinfuegen()
'
'Nimmt den Text aus der Zwischenablage und führt damit die ZeilenumbruchEntfernen, die PronomenErsetzungWeiblich und die VerbenErsetzung Funktion durch und gibt den Text wieder aus
'
'
    Dim sel_text As String

    sel_text = ClipBoard_GetData()
    sel_text = FunctionZeilenumbruecheEntfernen(sel_text)
    sel_text = EntferneWorttrennungenImText(sel_text)
    sel_text = SpezifischeFormatierungen(sel_text)
    sel_text = RegelmaessigeOCRFehlerErsetzung(sel_text)
    sel_text = PronomenErsetzungFuerFrageMaennlich(sel_text)
    sel_text = VergangenheitsVerbenErsetzung(sel_text)
    sel_text = VerbenErsetzung(sel_text)
    sel_text = VerbenZusammenfuegen(sel_text)
    sel_text = VerbenkonvertierungMehrzahlEinzahl(sel_text)
    sel_text = DoppelpunktHinzufuegen(sel_text)
    ' Auf Kursivschrift umstellen
    Selection.Font.Italic = True
    Selection.TypeText text:=sel_text
    ' Kursivschrift deaktivieren
    Selection.Font.Italic = False
    Call ZeichenHinterCursorAufNormalschriftStellen
    
End Sub

Sub FrageAnFrauEinfuegen()
'
'Nimmt den Text aus der Zwischenablage und führt damit die ZeilenumbruchEntfernen, die PronomenErsetzungWeiblich und die VerbenErsetzung Funktion durch und gibt den Text wieder aus
'
'
    Dim sel_text As String
    sel_text = ClipBoard_GetData()
    sel_text = FunctionZeilenumbruecheEntfernen(sel_text)
    sel_text = EntferneWorttrennungenImText(sel_text)
    sel_text = SpezifischeFormatierungen(sel_text)
    sel_text = RegelmaessigeOCRFehlerErsetzung(sel_text)
    sel_text = PronomenErsetzungFuerFrageWeiblich(sel_text)
    sel_text = VergangenheitsVerbenErsetzung(sel_text)
    sel_text = VerbenErsetzung(sel_text)
    sel_text = VerbenZusammenfuegen(sel_text)
    sel_text = VerbenkonvertierungMehrzahlEinzahl(sel_text)
    sel_text = DoppelpunktHinzufuegen(sel_text)
    ' Auf Kursivschrift umstellen
    Selection.Font.Italic = True
    Selection.TypeText text:=sel_text
    ' Kursivschrift deaktivieren
    Selection.Font.Italic = False
    Call ZeichenHinterCursorAufNormalschriftStellen
    
End Sub

Function ZeichenHinterCursorAufNormalschriftStellen()
    Dim sel_text As String
    Dim cursorPosition As Long
    Dim doc As Document
    
    ' Referenz zum aktiven Dokument
    Set doc = ActiveDocument
    
    ' Cursorposition speichern
    cursorPosition = Selection.Range.Start
    
    ' Text vor dem Cursor (ein Zeichen) extrahieren
    sel_text = Mid(doc.Range(cursorPosition - 1, cursorPosition), 1, 1)
    
    ' Zeichen auf Normalschrift umstellen
    With doc.Range(Start:=cursorPosition - 1, End:=cursorPosition).Font
        .Italic = False
        ' Füge hier weitere gewünschte Formatierungsoptionen hinzu
    End With
    
    ' Cursor an die ursprüngliche Position zurücksetzen
    Selection.SetRange cursorPosition, cursorPosition
    
End Function

Sub BGerAufruf()
    Dim selectedText As String
    Dim EdgePath As String

    selectedText = Selection.text ' Get the selected text
    EdgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" ' Set the path to Edge browser
    
    selectedText = Replace(selectedText, Chr(160), " ") ' allfällige geschützte Leerschläge (Chr(160)) mit normal Leerschlägen (" ") ersetzen
    
    'allfällige leerzeichen durch bindestriche ersetzen
    If InStr(selectedText, " ") > 0 Then ' Check if there are spaces in the string
        selectedText = Replace(selectedText, " ", "-") ' Replace spaces with hyphens
    End If
    
    
    If selectedText <> "" Then ' Check if something is selected
        Shell EdgePath & " " & "https://www.bger.li/" & selectedText ' Open the selected text as a URL in Edge browser
    Else
        MsgBox "Please select some text" ' Display message box if nothing is selected
    End If

End Sub


Sub GesetzAufruf()
    Dim mark_text As String
    Dim liste() As String
    Dim gesetz As String
    Dim artikel_nr As String
    
    mark_text = Selection.text
    mark_text = Replace(mark_text, Chr(160), " ") ' allfällige geschützte Leerschläge (Chr(160)) mit normal Leerschlägen (" ") ersetzen
    liste = Split(mark_text)
    gesetz = liste(UBound(liste)) 'letze erscheinung in dieser Split Liste nehmen
    artikel_nr = ExtractWordAfterArt(mark_text)

    
    EdgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" ' Set the path to Edge browser

    If mark_text <> "" Then ' Check if something is selected
        Shell EdgePath & " " & "https://www.fedlex.admin.ch/de/search?collection=classified_compilation&classifiedBy=" & gesetz & "&article=" & artikel_nr ' Open the selected text as a URL in Edge browser
    Else
        MsgBox "Bitte einen Gesetzesartikel markieren" ' Display message box if nothing is selected
    End If
        
End Sub

Private Function ExtractWordAfterArt(MyString As String)
    
    Dim MyArray() As String
    Dim result As String

    MyArray = Split(MyString, "Art.") ' Split the string into an array by "Art."

    If UBound(MyArray) > 0 Then ' Check if there is at least one occurrence of "Art."
        result = Trim(MyArray(1)) ' Get the substring after the first occurrence of "Art." and remove leading and trailing spaces
        result = Split(result)(0) ' Get the first word of the substring by splitting it by spaces and taking the first element
    Else
        MsgBox "Gesetzesartikel mit Abkürzung Art. markieren" ' Display message box if there is no occurrence of Art. in the string
    End If

    ExtractWordAfterArt = result
End Function

