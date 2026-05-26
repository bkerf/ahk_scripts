#NoEnv
#SingleInstance Force
#Persistent
SetWorkingDir %A_ScriptDir%
SendMode Input
SetTitleMatchMode, 2

; Shift + Win + C
#+c::
Run, % "powershell -NoProfile -ExecutionPolicy Bypass -File \"" . A_ScriptDir . "\clear-claude-login.ps1\" -CloseBrowsers -VerboseOutput", , Hide
return
