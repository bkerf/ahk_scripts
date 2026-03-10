; ============================================================
; VoiceMediaControl.ahk
; ============================================================
; Description: Win+H 先暂停媒体播放，再启动系统语音输入
;
; Usage:
;   - Win+H: 暂停媒体 → 启动语音输入
;
; 原因: 系统 Win+H 语音输入不会自动暂停媒体，
;       导致语音识别被背景音干扰
; ============================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; ===== Tray Menu =====
A_TrayMenu.Delete()
A_TrayMenu.Add("Voice Media Control", (*) => "")
A_TrayMenu.Disable("Voice Media Control")
A_TrayMenu.Add()
A_TrayMenu.Add("退出", (*) => ExitApp())

TrayTip("Voice Media Control", "Win+H = 暂停媒体 + 语音输入", 1)

; ===== Win+H Hotkey =====
; $ 前缀：使用键盘钩子，防止 Send("#h") 递归触发
$#h:: {
    ; APPCOMMAND_MEDIA_PAUSE = 47（仅暂停，不会切换播放）
    ; 如果媒体已暂停或未播放，此命令无效果
    PostMessage(0x0319, 0, 47 << 16,, "ahk_class Shell_TrayWnd")
    Sleep(200)
    ; 触发系统原生 Win+H 语音输入
    Send("#h")
}
