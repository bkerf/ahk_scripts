; ============================================================
; VoiceMediaControl.ahk
; ============================================================
; Win+H: 暂停媒体 → 启动语音 → 1分钟后自动恢复
; ============================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; ===== Tray Menu =====
A_TrayMenu.Delete()
A_TrayMenu.Add("Voice Media Control", (*) => "")
A_TrayMenu.Disable("Voice Media Control")
A_TrayMenu.Add()
A_TrayMenu.Add("退出", (*) => ExitApp())

; ===== Winsock =====
WSAStartup() {
    static started := false
    if started
        return true
    wsadata := Buffer(400)
    if DllCall("Ws2_32\WSAStartup", "UShort", 0x0202, "Ptr", wsadata) = 0 {
        started := true
        return true
    }
    return false
}

TCP_QUERY(host := "127.0.0.1", port := 5001) {
    if !WSAStartup()
        return ""
    socket := DllCall("Ws2_32\socket", "Int", 2, "Int", 1, "Int", 6, "Ptr")
    if (socket = -1 || socket = 0)
        return ""
    sockaddr := Buffer(16)
    NumPut("UShort", 2, sockaddr)
    NumPut("UShort", DllCall("Ws2_32\htons", "UShort", port), sockaddr, 2)
    NumPut("UInt", DllCall("Ws2_32\inet_addr", "AStr", host), sockaddr, 4)
    if (DllCall("Ws2_32\connect", "Ptr", socket, "Ptr", sockaddr, "Int", 16, "Int") != 0) {
        DllCall("Ws2_32\closesocket", "Ptr", socket)
        return ""
    }
    buf := Buffer(64)
    received := DllCall("Ws2_32\recv", "Ptr", socket, "Ptr", buf, "Int", 64, "Int", 0)
    DllCall("Ws2_32\closesocket", "Ptr", socket)
    return received > 0 ? StrGet(buf, received, "UTF-8") : ""
}

; ===== 恢复播放 =====
ResumeMedia(*) {
    PostMessage(0x0319, 0, 14 << 16,, "ahk_class Shell_TrayWnd")
}

; ===== Win+H =====
$#h:: {
    global

    if (TCP_QUERY() = "playing") {
        ; 取消之前的定时器
        SetTimer(ResumeMedia, 0)
        ; 暂停媒体
        PostMessage(0x0319, 0, 14 << 16,, "ahk_class Shell_TrayWnd")
        ; 2分钟后恢复
        SetTimer(ResumeMedia, -60000)
    }

    Sleep(200)
    Send("#h")
}
