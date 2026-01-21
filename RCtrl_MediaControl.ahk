; ============================================================
; RCtrl_MediaControl.ahk
; ============================================================
; 功能：右 Ctrl 键增强，实现"按住暂停、释放恢复"的媒体控制
;
; 使用场景：
;   - 听音乐/播客时，有人叫你，按住右Ctrl暂停
;   - 回应完毕，松开右Ctrl自动恢复播放
;   - 右Ctrl原有功能（如Ctrl+C复制）不受影响
;
; 智能检测：
;   - 只有媒体正在播放时才会暂停
;   - 如果媒体本身没有播放，按右Ctrl不会触发播放
;   - 避免误操作导致意外播放
;
; 依赖：
;   - Python + winsdk 库 (pip install winsdk)
;   - check_media.py 用于检测媒体播放状态
;
; 快捷键：
;   - 按住右Ctrl：暂停当前播放的媒体
;   - 释放右Ctrl：恢复播放（仅当之前是本脚本暂停的）
;
; ============================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; 状态标记：记录媒体是否由本脚本暂停
; 用于判断释放时是否需要恢复播放
global pausedByScript := false

; ===== 托盘菜单配置 =====
A_TrayMenu.Delete()
A_TrayMenu.Add("RCtrl 媒体控制", (*) => "")
A_TrayMenu.Disable("RCtrl 媒体控制")
A_TrayMenu.Add()
A_TrayMenu.Add("暂停脚本", TrayPauseScript)      ; 临时禁用热键
A_TrayMenu.Add("移除开机启动", TrayRemoveAutoStart)
A_TrayMenu.Add()
A_TrayMenu.Add("退出", (*) => ExitApp())

; 暂停/恢复脚本功能
TrayPauseScript(*) {
    Suspend(-1)  ; 切换暂停状态
    if A_IsSuspended
        A_TrayMenu.Check("暂停脚本")
    else
        A_TrayMenu.Uncheck("暂停脚本")
}

; 从开机启动中移除
TrayRemoveAutoStart(*) {
    shortcutPath := A_Startup "\RCtrl_MediaControl.lnk"
    if FileExist(shortcutPath) {
        FileDelete(shortcutPath)
        MsgBox("已从开机启动移除", "RCtrl MediaControl", "Iconi T2")
    }
}

; 启动提示
TrayTip("RCtrl 媒体控制", "已启动，按住右Ctrl暂停，松开恢复", 1)

; ===== 自启动设置 =====
; 首次运行时自动创建开机启动快捷方式
shortcutPath := A_Startup "\RCtrl_MediaControl.lnk"
if !FileExist(shortcutPath) {
    try FileCreateShortcut(A_ScriptFullPath, shortcutPath, A_ScriptDir)
}

; ===== 媒体状态检测 =====
; 调用 Python 脚本检测当前是否有媒体正在播放
; 返回值：true=正在播放，false=未播放或检测失败
IsMediaPlaying() {
    pyFile := A_ScriptDir "\check_media.py"
    if !FileExist(pyFile)
        return false

    ; pythonw 静默运行，通过退出码判断状态
    ; 退出码 0 = 正在播放
    ; 退出码 1 = 未播放
    exitCode := RunWait("pythonw `"" . pyFile . "`"",, "Hide")
    return exitCode = 0
}

; ===== 主热键逻辑 =====
; * 前缀：允许与其他修饰键组合（如 Ctrl+Shift+RCtrl）
*RCtrl:: {
    global pausedByScript

    ; 保持右Ctrl原有功能
    Send "{RCtrl Down}"

    ; 检测媒体状态，只有正在播放时才暂停
    if IsMediaPlaying() {
        Send "{Media_Play_Pause}"
        pausedByScript := true   ; 标记为本脚本暂停
    } else {
        pausedByScript := false  ; 媒体未播放，不做任何操作
    }

    ; 阻塞等待按键释放
    KeyWait "RCtrl"

    ; 释放时，只有本脚本暂停的才恢复播放
    if pausedByScript {
        Send "{Media_Play_Pause}"
        pausedByScript := false
    }

    ; 释放右Ctrl
    Send "{RCtrl Up}"
}
