; StartAll.ahk
; 一键启动所有 AHK 脚本
; AHK v2

#Requires AutoHotkey v2.0
#SingleInstance Force

; 获取脚本目录
scriptDir := A_ScriptDir

; 要启动的脚本列表
scripts := [
    "ClipboardImagePaste.ahk",
    "Home_MediaControl.ahk",
    "translator.ahk"
]

; 启动所有脚本
for script in scripts {
    scriptPath := scriptDir "\" script
    if FileExist(scriptPath) {
        Run(scriptPath)
    }
}

; 启动完成后退出自身
ExitApp()
