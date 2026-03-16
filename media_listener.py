"""
Windows 媒体播放状态监听器
用于检测系统是否有音频输出，供 AHK 脚本调用

输出格式（stdout）：
- playing: 检测到音频播放
- silent: 系统静音
"""

import sys
import time
from pycaw.pycaw import AudioUtilities, IAudioMeterInformation
from comtypes import CLSCTX_ALL
from ctypes import cast, POINTER
from comtypes import POINTER as c_POINTER


def get_audio_peak() -> float:
    """获取系统音频输出峰值 (0.0 - 1.0)"""
    # 获取默认音频输出设备
    deviceEnumerator = AudioUtilities.GetDeviceEnumerator()
    device = deviceEnumerator.GetDefaultAudioEndpoint(0, 0)  # 0 = eRender, 0 = eConsole

    # 激活音频计量接口
    meter = device.Activate(IAudioMeterInformation._iid_, CLSCTX_ALL, None)
    meter = cast(meter, POINTER(IAudioMeterInformation))
    return meter.GetPeakValue()


def is_playing(threshold: float = 0.001) -> bool:
    """
    判断是否有音频播放

    Args:
        threshold: 峰值阈值，低于此值视为静音

    Returns:
        True: 有声音 / False: 静音
    """
    peak = get_audio_peak()
    return peak > threshold


def tcp_server(port: int = 5001):
    """TCP 服务模式（供 AHK 高效查询）"""
    import socket

    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(("127.0.0.1", port))
    server.listen(1)

    print(f"[TCP 服务] 监听: 127.0.0.1:{port}")
    print("按 Ctrl+C 退出\n")

    try:
        while True:
            conn, addr = server.accept()
            try:
                resp = "playing" if is_playing() else "silent"
                conn.sendall(resp.encode())
            finally:
                conn.close()
    except KeyboardInterrupt:
        print("\n[TCP 服务已停止]")
    finally:
        server.close()


def main():
    """主入口"""
    args = sys.argv[1:] if len(sys.argv) > 1 else []

    # TCP 服务模式
    if "--tcp" in args:
        tcp_server()
        return

    # 单次查询模式
    if "--check" in args:
        print("playing" if is_playing() else "silent")
        return

    # 持续监听模式
    print("=" * 50)
    print("Windows 媒体播放状态监听器")
    print("=" * 50)
    print("Usage:")
    print("  --tcp    TCP 服务模式（推荐，供 AHK 查询）")
    print("  --check  单次查询模式")
    print("\n按 Ctrl+C 退出\n")

    try:
        while True:
            status = "playing" if is_playing() else "silent"
            peak = get_audio_peak()
            print(f"[{time.strftime('%H:%M:%S')}] {status} (peak: {peak:.4f})")
            time.sleep(0.5)
    except KeyboardInterrupt:
        print("\n[监听器已停止]")


if __name__ == "__main__":
    main()
