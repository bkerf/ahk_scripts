# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with this codebase.

## Project Overview

Windows 自动化脚本集合，基于 AutoHotkey v2。所有脚本使用 `#Requires AutoHotkey v2.0` 语法。

## Architecture

```
├── StartAll.ahk            # 开机启动入口（启动 UnifiedHotkeys + media_listener）
├── UnifiedHotkeys.ahk      # 统一热键入口（单托盘图标）
├── ClipboardImagePaste.ahk # 剪贴板图片转换（Ctrl+V）
├── Home_MediaControl.ahk   # 媒体控制（Home键）
├── VoiceMediaControl.ahk   # Win+H 语音前暂停媒体
├── translator.ahk          # 翻译工具入口（调用 translator.py）
├── translator.py           # DeepL 翻译后端（跨平台）
└── *.ps1                   # PowerShell 辅助脚本
```

**启动机制：**
- `StartAll.ahk` 是唯一的开机启动入口，只启动 `UnifiedHotkeys.ahk` 和 `media_listener.py`
- `UnifiedHotkeys.ahk` 负责统一托管常用热键，只保留一个托盘图标
- 各脚本**不再**独立添加自启动项

**脚本模式：**
- `UnifiedHotkeys.ahk` 作为默认常驻热键入口
- `translator.ahk` 保留为按需手动启动
- 复杂逻辑通过 `Run()` 调用 Python/PowerShell 实现

## Scripts

| 脚本 | 功能 | 热键 |
|------|------|------|
| `UnifiedHotkeys.ahk` | 默认统一热键入口 | `Ctrl+V` / `Shift+Enter` / `Home` / `Win+H` |
| `ClipboardImagePaste.ahk` | 剪贴板图片自动转文件 | `Ctrl+V`（智能检测） |
| `ClipboardImagePaste.ahk` | 终端换行 | `Shift+Enter`（仅终端） |
| `Home_MediaControl.ahk` | 媒体播放/暂停 | `Home` |
| `VoiceMediaControl.ahk` | 语音前暂停媒体 | `Win+H` |
| `translator.ahk` | 翻译选中文本 | `Ctrl+Shift+T`（→英文） |

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
```

**热键前缀：**
- `$` - 防止热键自触发（用于拦截后重发同键）
- `*` - 允许与其他修饰键组合
- `~` - 保留原键功能

**条件热键：**
```autohotkey
#HotIf WinActive("ahk_exe WindowsTerminal.exe")
+Enter:: SendInput("\{Enter}")
#HotIf
```

## Dependencies

translator.py 需要：
- 环境变量 `DEEPL_API_KEY`
- `pip install pywin32`（Windows 剪贴板操作）

## Running Scripts

```bash
# 启动默认开机集合（推荐）
start "" "F:/code/ahk_scripts/StartAll.ahk"

# 按需单独启动翻译工具
start "" "F:/code/ahk_scripts/translator.ahk"
```
