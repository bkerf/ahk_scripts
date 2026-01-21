; ================================================
; 禁用 F1 帮助键
; 防止误按 F1 弹出 Windows 帮助
; ================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; 托盘菜单
A_TrayMenu.Delete()
A_TrayMenu.Add("禁用 F1", (*) => "")
A_TrayMenu.Disable("禁用 F1")
A_TrayMenu.Add()
A_TrayMenu.Add("退出", (*) => ExitApp())

TrayTip("禁用 F1", "已启动，F1 键已被拦截", 1)

; 自启动
shortcutPath := A_Startup "\disable_f1.lnk"
if !FileExist(shortcutPath) {
    try FileCreateShortcut(A_ScriptFullPath, shortcutPath, A_ScriptDir)
}

; 禁用 F1 键（拦截但不执行任何操作）
F1::return
