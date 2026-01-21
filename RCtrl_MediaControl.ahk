; RCtrl_MediaControl.ahk
; 右 Ctrl 键增强：按住暂停媒体，释放恢复播放，同时保留原有 Ctrl 功能
; AHK v2

#Requires AutoHotkey v2.0
#SingleInstance Force

; ===== 托盘菜单 =====
A_TrayMenu.Delete()
A_TrayMenu.Add("RCtrl 媒体控制", (*) => "")
A_TrayMenu.Disable("RCtrl 媒体控制")
A_TrayMenu.Add()
A_TrayMenu.Add("暂停脚本", TrayPauseScript)
A_TrayMenu.Add("移除开机启动", TrayRemoveAutoStart)
A_TrayMenu.Add()
A_TrayMenu.Add("退出", (*) => ExitApp())

TrayPauseScript(*) {
    Suspend(-1)
    if A_IsSuspended
        A_TrayMenu.Check("暂停脚本")
    else
        A_TrayMenu.Uncheck("暂停脚本")
}

TrayRemoveAutoStart(*) {
    shortcutPath := A_Startup "\RCtrl_MediaControl.lnk"
    if FileExist(shortcutPath) {
        FileDelete(shortcutPath)
        MsgBox("已从开机启动移除", "RCtrl MediaControl", "Iconi T2")
    }
}

; 托盘提示
TrayTip("RCtrl 媒体控制", "已启动，按住右Ctrl暂停，松开恢复", 1)

; ===== 自启动设置 =====
shortcutPath := A_Startup "\RCtrl_MediaControl.lnk"
if !FileExist(shortcutPath) {
    try FileCreateShortcut(A_ScriptFullPath, shortcutPath, A_ScriptDir)
}

; ===== 主功能 =====
*RCtrl:: {
    Send "{RCtrl Down}"
    Send "{Media_Play_Pause}"
    KeyWait "RCtrl"
    Send "{Media_Play_Pause}"
    Send "{RCtrl Up}"
}
