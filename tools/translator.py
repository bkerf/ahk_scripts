#!/usr/bin/env python3
"""
跨平台翻译工具
使用 DeepL API 翻译剪贴板中的文本
"""

import os
import sys
import json
import urllib.request
import urllib.parse


def read_clipboard():
    """读取剪贴板内容（跨平台）"""
    if sys.platform == "darwin":  # macOS
        import subprocess
        result = subprocess.run(
            ["pbpaste"], capture_output=True, text=True, check=True
        )
        return result.stdout.strip()
    elif sys.platform == "win32":  # Windows
        import win32clipboard
        win32clipboard.OpenClipboard()
        try:
            data = win32clipboard.GetClipboardData()
        except Exception:
            data = ""
        finally:
            win32clipboard.CloseClipboard()
        return str(data)
    else:  # Linux
        try:
            import subprocess
            result = subprocess.run(
                ["xclip", "-selection", "clipboard", "-o"],
                capture_output=True, text=True, check=True
            )
            return result.stdout.strip()
        except (FileNotFoundError, subprocess.CalledProcessError):
            return ""


def write_clipboard(text):
    """写入剪贴板内容（跨平台）"""
    if sys.platform == "darwin":  # macOS
        import subprocess
        subprocess.run(["pbcopy"], input=text.encode(), check=True)
    elif sys.platform == "win32":  # Windows
        import win32clipboard
        win32clipboard.OpenClipboard()
        try:
            win32clipboard.EmptyClipboard()
            win32clipboard.SetClipboardText(text)
        finally:
            win32clipboard.CloseClipboard()
    else:  # Linux
        try:
            import subprocess
            subprocess.run(
                ["xclip", "-selection", "clipboard"],
                input=text.encode(), check=True
            )
        except (FileNotFoundError, subprocess.CalledProcessError):
            pass


def translate_deepl(text, target_lang="EN"):
    """
    使用 DeepL API 翻译文本

    Args:
        text: 要翻译的文本
        target_lang: 目标语言（EN、ZH等）

    Returns:
        翻译后的文本
    """
    api_key = os.environ.get("DEEPL_API_KEY")

    if not api_key:
        return "错误: 未找到 DEEPL_API_KEY 环境变量"

    if not text:
        return "错误: 剪贴板为空"

    # DeepL API 端点（免费版）
    api_url = "https://api-free.deepl.com/v2/translate"

    # 构建请求数据
    data = {
        "text": [text],
        "target_lang": target_lang
    }

    try:
        req = urllib.request.Request(
            api_url,
            data=json.dumps(data).encode("utf-8"),
            headers={
                "Authorization": f"DeepL-Auth-Key {api_key}",
                "Content-Type": "application/json"
            }
        )

        with urllib.request.urlopen(req, timeout=10) as response:
            result = json.loads(response.read().decode("utf-8"))

            if "translations" in result and len(result["translations"]) > 0:
                return result["translations"][0]["text"]
            else:
                return "错误: API 响应格式异常"

    except urllib.error.HTTPError as e:
        if e.code == 403:
            return "错误: API Key 无效或配额不足"
        elif e.code == 429:
            return "错误: 请求过于频繁，请稍后再试"
        else:
            return f"错误: HTTP {e.code} - {e.reason}"
    except urllib.error.URLError as e:
        return f"错误: 网络连接失败 - {e.reason}"
    except Exception as e:
        return f"错误: {str(e)}"


def show_notification(message):
    """显示系统通知（跨平台）"""
    if sys.platform == "darwin":  # macOS
        import subprocess
        subprocess.run([
            "osascript", "-e",
            f'display notification "{message}" with title "翻译工具"'
        ])
    elif sys.platform == "win32":  # Windows
        try:
            from win10toast import ToastNotifier
            toaster = ToastNotifier()
            toaster.show_toast(
                "翻译工具",
                message,
                duration=3,
                threaded=True
            )
        except ImportError:
            # 降级到消息框
            import ctypes
            ctypes.windll.user32.MessageBoxW(0, message, "翻译工具", 0)
    else:  # Linux
        try:
            import subprocess
            subprocess.run([
                "notify-send", "翻译工具", message
            ])
        except FileNotFoundError:
            pass


def main():
    """主函数"""
    # 解析命令行参数
    target_lang = "EN"  # 默认翻译为英文
    show_result = True  # 是否显示结果
    copy_result = True  # 是否复制结果到剪贴板

    if len(sys.argv) > 1:
        if sys.argv[1] in ["-h", "--help"]:
            print("用法: python translator.py [选项]")
            print("选项:")
            print("  -h, --help      显示帮助")
            print("  --zh            翻译为中文（默认为英文）")
            print("  --silent        静默模式，不显示通知")
            print("  --no-copy       不复制结果到剪贴板")
            sys.exit(0)

        if "--zh" in sys.argv:
            target_lang = "ZH"
        if "--silent" in sys.argv:
            show_result = False
        if "--no-copy" in sys.argv:
            copy_result = False

    # 读取剪贴板
    text = read_clipboard()

    if not text:
        if show_result:
            show_notification("剪贴板为空")
        sys.exit(1)

    # 翻译
    result = translate_deepl(text, target_lang)

    if copy_result and not result.startswith("错误"):
        write_clipboard(result)

    # 显示结果
    if show_result:
        show_notification(result if len(result) <= 100 else result[:100] + "...")

    # 输出到标准输出（用于调试）
    print(result)

    # 返回状态码
    sys.exit(0 if not result.startswith("错误") else 1)


if __name__ == "__main__":
    main()
