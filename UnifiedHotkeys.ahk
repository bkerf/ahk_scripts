; UnifiedHotkeys.ahk
; 单进程统一托管常用热键，避免多个托盘图标

#Requires AutoHotkey v2.0
#SingleInstance Force

#Include lib\Common.ahk

InitializeUnifiedHotkeys()

#Include lib\Clipboard.ahk
#Include lib\Media.ahk
#Include lib\SmartPlayer.ahk
