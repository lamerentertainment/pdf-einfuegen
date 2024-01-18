Sub GPTFrau()

zwischenablage = Modul1.ClipBoard_GetData()
text = Modul1.FunctionZeilenumbruecheEntfernen(zwischenablage)
text = Modul1.SpezifischeFormatierungen(zwischenablage)
text = AskChatGPT("Du bist eine professionelle Textkonvertierungsmaschine. Du machst nichts anderes als eingespiesene Texte in indirekte Rede sowie in dritte Person umformatieren. Auch die Verben in Vergangenheitsform konvertierst Du in indirekte Rede (Der Text wurde von einer Frau gesprochen. Ein Beispiel: 'Ich fand dies komisch' sollte in 'Sie habe dies komisch gefunden' konvertiert werden): " + text)
text = Modul1.BelegstelleHinzufuegen(text)
Selection.TypeText text:=text
Call Modul1.MoveCursorBackThreeSteps

End Sub

Sub GPTMann()

zwischenablage = Modul1.ClipBoard_GetData()
text = Modul1.FunctionZeilenumbruecheEntfernen(zwischenablage)
text = Modul1.SpezifischeFormatierungen(zwischenablage)
text = AskChatGPT("Du bist eine professionelle Textkonvertierungsmaschine. Du machst nichts anderes als eingespiesene Texte in indirekte Rede sowie in dritte Person umformatieren. Auch die Verben in Vergangenheitsform konvertierst Du in indirekte Rede (Der Text wurde von einem Mann gesprochen. Ein Beispiel: 'Ich fand dies komisch' sollte in 'Er habe dies komisch gefunden' konvertiert werden): " + text)
text = Modul1.BelegstelleHinzufuegen(text)
Selection.TypeText text:=text
Call Modul1.MoveCursorBackThreeSteps

End Sub

Function AskChatGPT(userMessage As String) As String
    Dim response As String
    Dim URL As String
    Dim apiKey As String
    Dim modelName As String
    
    apiKey = "env('OPENAI-API-KEY')"
    modelName = "gpt-3.5-turbo"
    userMessage = userMessage
    URL = "https://api.openai.com/v1/chat/completions"
    
    Set request = CreateObject("MSXML2.XMLHTTP")
    
    request.Open "POST", URL, False
    request.setRequestHeader "Content-Type", "application/json"
    request.setRequestHeader "Authorization", "Bearer " & apiKey
    
    Dim data As String
    data = "{""model"": """ & modelName & """, ""messages"": [{""role"": ""user"", ""content"": """ & userMessage & """}]}"

    request.send (data)
    
    json_response = request.responseText
    
    'Extracting the content from the response
    response = ExtractContent(json_response)
    
    Selection.TypeText response
    AskChatGPT = response
End Function

Function ExtractContent(ByVal json As String) As String
    Dim regex As Object
    Set regex = CreateObject("VBScript.RegExp")
    regex.Pattern = """content"":\s*""(.+?)"""
    Dim matches As Object
    Set matches = regex.Execute(json)
    If matches.Count > 0 Then
        ExtractContent = matches(0).SubMatches(0)
    End If
End Function


Function CreateJSON(ByVal textstelle As String, geschlecht As String) As String
    Dim json As String
    textstelle = textstelle
    
    ' Create the JSON string
    json = "{""text"": """ & textstelle & """, ""geschlecht"": """ & geschlecht & """}"
    
    CreateJSON = json
End Function

Function SendPOSTRequest(ByVal textstelle As String, geschlecht As String) As String
    Dim objHTTP As Object
    Dim URL As String
    Dim Payload As String
    textstelle = textstelle
    
    ' Set the URL for the POST request
    URL = "https://einfuegen.ch/api/v1/transform_text"
    
    ' Set the payload for the POST request
    Payload = CreateJSON(textstelle, geschlecht)
    
    ' Create an HTTP object
    Set objHTTP = CreateObject("WinHttp.WinHttpRequest.5.1")
    
    ' Send the POST request
    objHTTP.Open "POST", URL, False
    objHTTP.setRequestHeader "Content-Type", "application/json"
    objHTTP.send Payload
    
    ' Print the response from the server
    Debug.Print objHTTP.responseText
    
    SendPOSTRequest = objHTTP.responseText
    
    ' Release the HTTP object
    Set objHTTP = Nothing
    
    
End Function


Function ExtrahiereTextAusJSON(ByVal json As String) As String
    Dim regex As Object
    Dim matches As Object
    
    Set regex = CreateObject("VBScript.RegExp")
    regex.Pattern = """transformed_text""\s*:\s*""([^""]+)"""
    regex.Global = False
    
    Set matches = regex.Execute(json)
    
    If matches.Count > 0 Then
        ExtrahiereTextAusJSON = matches(0).SubMatches(0)
    End If
End Function

Function Umlautkorrektur(ByVal text As String) As String
    
    ' Escape-Sequenzen in Unicode-Zeichen umwandeln
    text = Replace(text, "\u00e4", "ä")
    text = Replace(text, "\u00f6", "ö")
    text = Replace(text, "\u00fc", "ü")
    text = Replace(text, "\u00c4", "Ä")
    text = Replace(text, "\u00d6", "Ö")
    text = Replace(text, "\u00dc", "Ü")
    text = Replace(text, "\u00df", "ß")
    
    Umlautkorrektur = text
    
End Function

Function APIAbfrage(ByVal geschlecht As String)

    zwischenablage = Modul1.ClipBoard_GetData()
    zwischenablage = Modul1.FunctionZeilenumbruecheEntfernen(zwischenablage)
    zwischenablage = Modul1.SpezifischeFormatierungen(zwischenablage)
    json_response = SendPOSTRequest(zwischenablage, geschlecht)
    transformierter_text = ExtrahiereTextAusJSON(json_response)
    transformierter_text = Modul1.BelegstelleHinzufuegen(transformierter_text)
    transformierter_text = Umlautkorrektur(transformierter_text)
    Selection.TypeText text:=transformierter_text
    Call Modul1.MoveCursorBackThreeSteps

End Function


Sub APIAussageMann()

Call APIAbfrage("m")

End Sub

Sub APIAussageFrau()

Call APIAbfrage("w")

End Sub


