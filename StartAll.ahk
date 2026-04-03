; StartAll.ahk
; 开机启动入口：启动统一热键脚本和后台媒体监听服务
; AHK v2

#Requires AutoHotkey v2.0
#SingleInstance Force

; 获取脚本目录
scriptDir := A_ScriptDir

; ===== 启动 TCP 媒体监听服务 =====
Run(A_ScriptDir "\.venv\Scripts\pythonw.exe " A_ScriptDir "\media_listener.py --tcp", , "Hide")

; ===== 统一启动主脚本（单托盘图标） =====
Run(scriptDir "\UnifiedHotkeys.ahk")

; 自启动：将自身添加到启动目录
shortcutPath := A_Startup "\StartAll.lnk"
if !FileExist(shortcutPath) {
    try FileCreateShortcut(A_ScriptFullPath, shortcutPath, A_ScriptDir)
}

; 启动完成后退出自身
ExitApp()
