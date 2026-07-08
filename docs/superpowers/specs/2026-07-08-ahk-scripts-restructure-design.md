# ahk_scripts 结构重构设计

- 日期：2026-07-08
- 状态：已实施（见 `docs/superpowers/plans/2026-07-08-ahk-scripts-restructure-implementation.md`）
- 目标：把这个长期维护的 AutoHotkey v2 自动化脚本项目理顺结构，消除代码重复，便于以后逐步增加功能。

## 背景与问题

当前仓库是扁平结构，存在以下混乱：

1. **内联重复**：`UnifiedHotkeys.ahk` 没有用 `Run()` 拉起各功能脚本，而是把 `ClipboardImagePaste.ahk`、`Home_MediaControl.ahk`、`VoiceMediaControl.ahk` 的逻辑**内联复制**了一份。同一段函数（`$^v`、`Home`、`$#h`、`TCP_QUERY`、截图清理等）在多个文件里重复，改一处行为要改两处。
2. **v1/v2 混放**：`clear-claude-login.ahk` 是 AHK **v1** 语法（`#NoEnv` / `SetTitleMatchMode, 2`），与其余 v2 脚本混在一起。
3. **多套未接入实现**：媒体检测有三套——生产用 `media_listener.py`（pycaw 音频峰值），另有 `check_media.py`（winsdk）和 `CheckMediaPlaying.ps1`（WinRT）未接入。
4. **死机制**：`ClipboardMonitor.ps1`（后台剪贴板监听）从未被 `StartAll.ahk` 拉起，实际生效的只有 AHK 的 `Ctrl+V` 内联兜底；但两套并存造成「看似有两个机制」的困惑。
5. **文档漂移**：`CLAUDE.md`、`AGENTS.md`、`README.md`、`README.txt` 内容分散、部分过时。

## 已确认的决策

| 决策点 | 选择 |
|--------|------|
| 整理幅度 | 完整地基重构：分子目录 + `#Include` 模块化去重 + 遗留归档 |
| 入口策略 | 单一入口：只有 `UnifiedHotkeys.ahk` 常驻运行；功能拆到 `lib/` 模块（模块自带热键绑定）；不再保留独立功能脚本 |
| 遗留处理 | 归档到 `legacy/`（保留可查，不参与运行） |
| 剪贴板机制 | 只留 AHK 内联兜底；`ClipboardMonitor.ps1` 归档 |
| 文档入口 | `AGENTS.md` 作为唯一 canonical 入口；`CLAUDE.md` 仅引用它 |

## 目标目录结构

```
ahk_scripts/
├─ StartAll.ahk            # 引导：启动 services/media_listener + UnifiedHotkeys，自注册开机启动，退出
├─ UnifiedHotkeys.ahk      # 组合根：全局初始化 + 托盘菜单 + 一串 #Include lib/*
├─ lib/                    # 可复用功能模块（每个自带热键绑定 + 相关函数）
│  ├─ Common.ahk           #   统一初始化 + 托盘菜单 + Log()（必须最先被 include）
│  ├─ Clipboard.ahk        #   $^v 图片转文件 + +Enter 终端换行
│  ├─ Media.ahk            #   Home 播放/暂停 + $#h 语音前暂停 + TCP_QUERY + 托盘开关
│  └─ SmartPlayer.ahk      #   $F1 拦截 + #+c 清 claude 痕迹
├─ services/               # 常驻后台服务
│  └─ media_listener.py    #   pycaw TCP 服务 127.0.0.1:5001
├─ tools/                  # 按需手动工具
│  ├─ translator.ahk       #   Ctrl+Shift+T 等（按需启动，不随开机）
│  ├─ translator.py        #   DeepL 后端
│  └─ clear-claude-login.ps1  # 被 SmartPlayer.ahk 的 #+c 调用
├─ legacy/                 # 归档：不参与运行，保留可查
│  ├─ README.md            #   逐个说明为何退役
│  ├─ ClipboardImagePaste.ahk
│  ├─ Home_MediaControl.ahk
│  ├─ VoiceMediaControl.ahk
│  ├─ ClipboardMonitor.ps1
│  ├─ check_media.py
│  ├─ CheckMediaPlaying.ps1
│  ├─ clear-claude-login.ahk   # v1
│  ├─ clear-claude-login.bat
│  └─ README.txt
├─ docs/
│  └─ superpowers/
│     ├─ specs/2026-07-08-ahk-scripts-restructure-design.md
│     └─ plans/2026-07-08-ahk-scripts-restructure-implementation.md
├─ AGENTS.md               # 唯一的 AI/协作 + 架构指南（canonical）
├─ CLAUDE.md               # 仅指向 AGENTS.md
├─ README.md               # 用户向说明（更新路径）
└─ .venv/                  # 本地（gitignore）
```

**扩展方式（本重构的核心收益）**：以后加功能 = 新建 `lib/Xxx.ahk` + 在 `UnifiedHotkeys.ahk` 加一行 `#Include lib\Xxx.ahk`。

## 模块拆分与边界

把 `UnifiedHotkeys.ahk` 现有内联逻辑按职责切成 4 个单一真相源模块：

归属原则：**谁用谁持有、模块自初始化**——只有被 2 个以上模块共用的才放 `Common.ahk`。

| 模块 | 热键 | 函数 | 自持全局 / 自初始化 |
|------|------|------|------|
| `Common.ahk` | — | `Log()` | 日志路径（`Log()` 被 Media 与组合根共用）；启动时清空日志 |
| `Clipboard.ahk` | `Ctrl+V`(`$^v`)、`Shift+Enter`(`+Enter`, 仅终端) | `ClipboardHasImage/HasFiles`、`SaveClipboardImage`、`SetClipboardToFile`、`IsTerminalWindowActive`、`CleanupOldScreenshots`、`SortByTime` | `ScreenshotDir`、`MaxScreenshots`；启动时建目录 + 清理旧截图 |
| `Media.ahk` | `Home`、`Win+H`(`$#h`) | `WSAStartup`、`TCP_QUERY`、`ResumeMedia`、`ToggleHomeMediaControl` | `HomeMediaEnabled` |
| `SmartPlayer.ahk` | `F1`(`$F1`, `#HotIf` 条件)、`Win+Shift+C`(`#+c`) | `IsSmartPlayerWindowActive` | `SmartPlayerAllowedTitleKeywords` |

`UnifiedHotkeys.ahk` 组合根只保留：按顺序 `#Include`（Common 最先）+ 调用 `InitializeUnifiedHotkeys()`。托盘菜单构建（`打开截图目录`、`Home Media Control` 开关等）在 `Common.ahk` 中集中处理；截图目录创建与清理由 `Clipboard.ahk` 的初始化函数负责，日志清空由 `Common.ahk` 负责。

### AHK `#Include` 机制约定（避免路径与作用域坑）

- **组合根显式包含、模块不互相 include**：`UnifiedHotkeys.ahk` 里
  ```autohotkey
  #Include lib\Common.ahk      ; 必须最先，定义全局 + 通用函数
  #Include lib\Clipboard.ahk
  #Include lib\Media.ahk
  #Include lib\SmartPlayer.ahk
  ```
  `#Include` 是文本插入，函数/全局是脚本级作用域。Common 先包含后，其函数与全局对后续模块全部可见，因此**功能模块无需再互相 include**，从根本上绕开嵌套相对路径解析的歧义。
- **`A_ScriptDir` 恒指向主脚本目录（根）**：模块被文本插入后，模块内所有对外部文件的路径引用统一写成根相对，例如 `A_ScriptDir "\tools\clear-claude-login.ps1"`。
- **函数访问全局需 `global` 声明**：沿用现有写法（如 `SaveClipboardImage()` 内 `global ScreenshotDir`）。
- **每个模块末尾复位 `#HotIf`**：防止条件热键上下文污染后续模块。
- **实现时需实测校验**：`#Include` 相对路径解析、`A_ScriptDir` 根相对引用、`#HotIf` 复位——落地后逐一手动验证。

## 启动流程调整

`StartAll.ahk` 更新被移动文件的路径，并在启动前精确清理本仓库旧的媒体监听进程树：

- `media_listener.py` → `services\media_listener.py`；
- `.venv\Scripts\pythonw.exe` 保持根目录不变；
- 清理命令行匹配本仓库 `media_listener.py --tcp` / `services\media_listener.py --tcp` 的 `python.exe` / `pythonw.exe`；
- 其余（写 `A_Startup\StartAll.lnk` 自启、拉起 `UnifiedHotkeys.ahk`、随后 `ExitApp()`）保持不变。

启动后仍是**单托盘图标**。

## 遗留归档与机制收敛

移入 `legacy/` 并在 `legacy/README.md` 注明退役原因：

| 文件 | 退役原因 |
|------|----------|
| `ClipboardImagePaste.ahk` / `Home_MediaControl.ahk` / `VoiceMediaControl.ahk` | 逻辑已提取到 `lib/`，改为单一入口 |
| `ClipboardMonitor.ps1` | 从未被 StartAll 拉起；改为只用 AHK 内联兜底 |
| `check_media.py` / `CheckMediaPlaying.ps1` | 未接入的备用媒体检测；生产用 pycaw |
| `clear-claude-login.ahk`(v1) / `clear-claude-login.bat` | v1 遗留入口；生产触发是 `UnifiedHotkeys` 的 `#+c` |
| `README.txt` | 旧的 clear-claude-login 使用说明，已被 README.md/AGENTS.md 取代 |

> **行为影响说明**：因 `ClipboardMonitor.ps1` 本就未被拉起，「只留内联兜底」**不改变现有实际行为**，只是把死代码归档。

## 文档策略

- **`AGENTS.md`（唯一 canonical 入口）**：合并架构四事实、热键总表、常用命令、依赖、约定，按**新结构**更新；保留原有 PR/提交/风格规范。
- **`CLAUDE.md`（指针）**：保留 Claude Code 要求的开头声明 + 一句「本仓库规范与架构以 `./AGENTS.md` 为唯一入口，请先阅读」。使 Claude 与 Codex 共用一份事实源，避免重复漂移。
- **`README.md`**：用户向，更新脚本路径与启动说明。

## 热键总表（重构后不变，以 `UnifiedHotkeys.ahk` 为准）

| 热键 | 行为 | 生效条件 | 所属模块 |
|------|------|----------|----------|
| `Ctrl+V` | 剪贴板图片自动转文件后再粘贴 | 检测到图片且非文件时 | Clipboard |
| `Shift+Enter` | 发送 `\` + 回车（Claude Code 换行） | 仅终端窗口 | Clipboard |
| `Home` | 媒体播放/暂停 | 托盘勾选时；否则发原始 `Home` | Media |
| `Win+H` | 播放中则暂停媒体、2 分钟后自动恢复，再透传 `Win+H` | — | Media |
| `F1` | 拦截吞掉，防止误弹帮助页 | 仅当**非** Smart Player 窗口时拦截 | SmartPlayer |
| `Win+Shift+C` | 运行 `clear-claude-login.ps1` 清 claude 痕迹 | — | SmartPlayer |
| `Ctrl+Shift+T` / `Ctrl+Alt+Shift+T` / `Ctrl+Shift+Y` | DeepL 翻译（英/中/仅到剪贴板） | 仅 `tools/translator.ahk`，按需启动 | tools |

## 迁移与验证

除归档外**行为保持不变**。无自动化测试，落地后手动冒烟：

1. `start "" ".\StartAll.ahk"` → 只出现一个托盘图标；
2. 逐个验热键：`Ctrl+V`、`Shift+Enter`、`Home`（含托盘开关）、`Win+H`（暂停+2 分钟恢复）、`F1`（仅 Smart Player 窗口放行）、`Win+Shift+C`；
3. `.venv\Scripts\python.exe services\media_listener.py --check` → 打印 `playing`/`silent`；
4. `start "" ".\tools\translator.ahk"` → 验翻译剪贴板读写与 `DEEPL_API_KEY`。

## 非目标（YAGNI）

- 不引入构建系统、不加自动化测试框架（当前项目规模不需要）。
- 不改任何热键的用户可见行为。
- 不重写 Python/PowerShell 后端逻辑，仅移动位置 + 更新引用路径。
- 不做 `lib/` 之外的进一步分层（如按平台细分），留待真有需要时再说。
