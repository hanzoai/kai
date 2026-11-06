' Kai.vbs - one decision through Windows Script Host.
Option Explicit

Const DefaultBaseUrl = "https://api.hanzo.ai"

Dim shell, processEnv, apiKey, model, baseUrl, payload, http, status, responseText
Dim choiceRe, matches, choice, legal

Set shell = CreateObject("WScript.Shell")
Set processEnv = shell.Environment("PROCESS")

apiKey = Trim(processEnv("HANZO_API_KEY"))
model = Trim(processEnv("KAI_MODEL"))
If apiKey = "" Then
    WScript.Echo "HANZO_API_KEY is required"
    WScript.Quit 1
End If
If model = "" Then model = "kai"
If baseUrl = "" Then baseUrl = DefaultBaseUrl
Do While Right(baseUrl, 1) = "/"
    baseUrl = Left(baseUrl, Len(baseUrl) - 1)
Loop

payload = "{""model"":" & JsonString(model) & _
    ",""state"":{""game"":""tic-tac-toe"",""board"":[["""","""",""""],["""","""",""""],["""","""","""]],""player"":""X""}" & _
    ",""questions"":{""move"":{""type"":""choice"",""instructions"":""Choose the strongest legal next move."",""criteria"":{""r1c1"":""top-left"",""r1c2"":""top-center"",""r1c3"":""top-right"",""r2c1"":""middle-left"",""r2c2"":""center"",""r2c3"":""middle-right"",""r3c1"":""bottom-left"",""r3c2"":""bottom-center"",""r3c3"":""bottom-right""}}}}"

Set http = CreateObject("MSXML2.ServerXMLHTTP.6.0")
http.Open "POST", baseUrl & "/v1/decisions", False
http.setRequestHeader "Content-Type", "application/json"
http.setRequestHeader "Authorization", "Bearer " & apiKey
http.setTimeouts 5000, 5000, 10000, 30000
http.Send payload

status = http.Status
responseText = http.ResponseText
WScript.Echo "status: " & status
WScript.Echo responseText

If status <> 200 Then WScript.Quit 1

Set choiceRe = New RegExp
choiceRe.Pattern = """choice""\s*:\s*""([^""]*)"""
choiceRe.IgnoreCase = True
Set matches = choiceRe.Execute(responseText)
If matches.Count = 0 Then
    WScript.Echo "No choice in Kai's response"
    WScript.Quit 1
End If

choice = matches(0).SubMatches(0)
legal = False
Select Case choice
    Case "r1c1", "r1c2", "r1c3", "r2c1", "r2c2", "r2c3", "r3c1", "r3c2", "r3c3"
        legal = True
End Select
If Not legal Then
    WScript.Echo "Kai returned an illegal move: " & choice
    WScript.Quit 1
End If
WScript.Echo "move: " & choice

Function JsonString(value)
    Dim result
    result = Replace(value, "\", "\\")
    result = Replace(result, """", "\""")
    result = Replace(result, vbCrLf, "\n")
    result = Replace(result, vbCr, "\n")
    result = Replace(result, vbLf, "\n")
    result = Replace(result, vbTab, "\t")
    JsonString = """" & result & """"
End Function
