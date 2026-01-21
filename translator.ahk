; ================================================
; 翻译工具 AutoHotkey v2 入口脚本 (Windows)
; 快捷键: Ctrl + Shift + T
; ================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; Python 翻译脚本所在目录（与 AHK 脚本同目录）
global TranslatorDir := A_ScriptDir

; 托盘菜单
A_TrayMenu.Delete()
A_TrayMenu.Add("翻译工具", (*) => "")
A_TrayMenu.Disable("翻译工具")
A_TrayMenu.Add()
A_TrayMenu.Add("退出", (*) => ExitApp())

TrayTip("翻译工具", "已启动", 1)

; 自启动
shortcutPath := A_Startup "\translator.lnk"
if !FileExist(shortcutPath) {
    try FileCreateShortcut(A_ScriptFullPath, shortcutPath, A_ScriptDir)
}

; Ctrl + Shift + T: 翻译选中文本为英文
^+t::
{
    ; 复制选中的文本
    Send "^c"
    Sleep 100  ; 等待复制完成

    ; 调用 Python 脚本翻译
    try {
        Run('cmd /c "cd /d "' TranslatorDir '" && python translator.py --silent"', , "Hide")
    }

    ; 等待翻译完成（DeepL API 响应时间）
    Sleep 1500

    ; 粘贴翻译结果
    Send "^v"
}

; Ctrl + Alt + Shift + T: 翻译选中文本为中文
^!+t::
{
    Send "^c"
    Sleep 100

    ; 调用 Python 脚本翻译为中文
    try {
        Run('cmd /c "cd /d "' TranslatorDir '" && python translator.py --zh --silent"', , "Hide")
    }

    Sleep 1500

    Send "^v"
}

; Ctrl + Shift + Y: 仅翻译（不粘贴，结果在剪贴板）
^+y::
{
    Send "^c"
    Sleep 100

    try {
        Run('cmd /c "cd /d "' TranslatorDir '" && python translator.py"', , "Hide")
    }
}
