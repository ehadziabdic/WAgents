' Hermes Agent Gateway - Messaging Platform Integration
Option Explicit
Dim fso, sh, target
target = "C:\Users\eminha\AppData\Local\hermes\profiles\wagent\gateway-service\Hermes_Gateway_wagent.vbs"
Set fso = CreateObject("Scripting.FileSystemObject")
If Not fso.FileExists(target) Then WScript.Quit 0
Set sh = CreateObject("WScript.Shell")
sh.Run "wscript.exe C:\Users\eminha\AppData\Local\hermes\profiles\wagent\gateway-service\Hermes_Gateway_wagent.vbs", 0, False
