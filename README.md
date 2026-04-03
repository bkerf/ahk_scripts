# AHK Scripts

Windows 自动化脚本集合，基于 AutoHotkey v2。

## 脚本列表

| 脚本 | 功能 | 快捷键 |
|------|------|--------|
| `UnifiedHotkeys.ahk` | 统一热键入口（推荐） | 见下方 |
| `ClipboardImagePaste.ahk` | 剪贴板图片自动转文件 | `Ctrl+V` |
| `Home_MediaControl.ahk` | Home键控制媒体播放 | `Home` |
| `VoiceMediaControl.ahk` | Win+H 语音前暂停媒体 | `Win+H` |
| `translator.ahk` | DeepL 翻译工具 | `Ctrl+Shift+T` 等 |

## 功能详情

### ClipboardImagePaste

截图后自动将剪贴板中的图片转换为文件，使终端等不支持直接粘贴图片的应用可以粘贴。

- `Ctrl+V` - 自动检测剪贴板图片并转换
- `Shift+Enter` - 终端换行（用于 Claude Code）

### UnifiedHotkeys

`UnifiedHotkeys.ahk` 会把常用功能合并到一个托盘进程中，避免右下角出现多个 AHK 图标。

- `Ctrl+V` - 自动检测剪贴板图片并转换
- `Shift+Enter` - 终端换行（用于 Claude Code）
- `Home` - 媒体播放/暂停
- `Win+H` - 语音输入前暂停媒体，2 分钟后自动恢复

### translator

翻译功能默认不随开机启动。需要时可单独运行 `translator.ahk`。

使用 DeepL API 翻译选中文本。

| 快捷键 | 功能 |
|--------|------|
| `Ctrl+Shift+T` | 翻译为英文并粘贴 |
| `Ctrl+Alt+Shift+T` | 翻译为中文并粘贴 |
| `Ctrl+Shift+Y` | 仅翻译到剪贴板 |

**依赖：**
- 环境变量 `DEEPL_API_KEY`
- Python 包：`pip install pywin32`

### Home_MediaControl

Home 键切换媒体播放/暂停。

- `Home` - 媒体播放/暂停

## 安装

1. 安装 [AutoHotkey v2](https://www.autohotkey.com/)
2. 克隆仓库：
   ```bash
   git clone git@github.com:bkerf/ahk_scripts.git
   ```
3. 双击运行 `StartAll.ahk` 启动统一热键脚本和后台服务

## 开机启动

运行 `StartAll.ahk` 后会自动添加到 Windows 启动项。

开机时只会启动一个统一托盘脚本 `UnifiedHotkeys.ahk`，并拉起 `media_listener.py` 后台服务。`translator.ahk` 不在默认启动集合内，需要时手动运行。旧的功能脚本仍可单独调试，但不再作为默认开机启动路径。

## License

MIT
