# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Windows 自动化脚本集合，基于 AutoHotkey v2。所有脚本使用 `#Requires AutoHotkey v2.0` 语法。

## Architecture

```
├── *.ahk           # AHK v2 热键脚本（入口）
├── translator.py   # Python 翻译后端（被 translator.ahk 调用）
└── *.ps1           # PowerShell 辅助脚本
```

**脚本模式：**
- AHK 脚本作为热键入口，常驻托盘
- 复杂逻辑通过 `Run()` 调用 Python/PowerShell 实现
- 所有脚本首次运行自动添加到 `A_Startup` 开机启动

## AHK v2 Conventions

```autohotkey
#Requires AutoHotkey v2.0
#SingleInstance Force

; 托盘菜单模板
A_TrayMenu.Delete()
A_TrayMenu.Add("脚本名称", (*) => "")
A_TrayMenu.Disable("脚本名称")
A_TrayMenu.Add()
A_TrayMenu.Add("退出", (*) => ExitApp())

; 自启动模板
shortcutPath := A_Startup "\ScriptName.lnk"
if !FileExist(shortcutPath) {
    try FileCreateShortcut(A_ScriptFullPath, shortcutPath, A_ScriptDir)
}
```

**热键前缀：**
- `$` - 防止热键自触发（用于拦截后重发同键）
- `*` - 允许与其他修饰键组合
- `~` - 保留原键功能

## Dependencies

translator.py 需要：
- 环境变量 `DEEPL_API_KEY`
- `pip install pywin32`（Windows 剪贴板操作）

## Running Scripts

```bash
# 启动单个脚本
start "" "脚本名.ahk"

# 启动所有脚本
for %f in (*.ahk) do start "" "%f"
```
