# AHK Scripts

Windows 自动化脚本集合，基于 AutoHotkey v2。

## 脚本列表

| 脚本 | 功能 | 快捷键 |
|------|------|--------|
| `ClipboardImagePaste.ahk` | 剪贴板图片自动转文件 | `Ctrl+V` |
| `RCtrl_MediaControl.ahk` | 右Ctrl控制媒体播放 | 按住/释放右Ctrl |
| `translator.ahk` | DeepL 翻译工具 | `Ctrl+Shift+T` 等 |

## 功能详情

### ClipboardImagePaste

截图后自动将剪贴板中的图片转换为文件，使终端等不支持直接粘贴图片的应用可以粘贴。

- `Ctrl+V` - 自动检测剪贴板图片并转换
- `Shift+Enter` - 终端换行（用于 Claude Code）

### RCtrl_MediaControl

右 Ctrl 键增强，按住暂停媒体播放，释放恢复播放，同时保留 Ctrl 原有功能。

- 按住右 Ctrl → 暂停播放
- 释放右 Ctrl → 恢复播放

### translator

使用 DeepL API 翻译选中文本。

| 快捷键 | 功能 |
|--------|------|
| `Ctrl+Shift+T` | 翻译为英文并粘贴 |
| `Ctrl+Alt+Shift+T` | 翻译为中文并粘贴 |
| `Ctrl+Shift+Y` | 仅翻译到剪贴板 |

**依赖：**
- 环境变量 `DEEPL_API_KEY`
- Python 包：`pip install pywin32`

## 安装

1. 安装 [AutoHotkey v2](https://www.autohotkey.com/)
2. 克隆仓库：
   ```bash
   git clone git@github.com:bkerf/ahk_scripts.git
   ```
3. 双击运行需要的 `.ahk` 脚本

## 开机启动

所有脚本首次运行时会自动添加到 Windows 启动项。

可通过托盘图标右键菜单移除开机启动。

## License

MIT
