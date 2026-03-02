; StartAll.ahk
; 自动启动目录下所有 AHK 脚本
; AHK v2

#Requires AutoHotkey v2.0
#SingleInstance Force

; 获取脚本目录
scriptDir := A_ScriptDir

; 扫描并启动目录下所有 .ahk 脚本（排除自身）
Loop Files scriptDir "\*.ahk" {
    if (A_LoopFileName != "StartAll.ahk") {
        Run(A_LoopFileFullPath)
    }
}

; 自启动：将自身添加到启动目录
shortcutPath := A_Startup "\StartAll.lnk"
if !FileExist(shortcutPath) {
    try FileCreateShortcut(A_ScriptFullPath, shortcutPath, A_ScriptDir)
}

; 启动完成后退出自身
ExitApp()
