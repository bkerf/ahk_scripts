# check_media.py
# 检测当前媒体是否正在播放
# 退出码: 0=正在播放, 1=未播放

import sys

try:
    import asyncio
    from winsdk.windows.media.control import GlobalSystemMediaTransportControlsSessionManager
    from winsdk.windows.media.control import GlobalSystemMediaTransportControlsSessionPlaybackStatus

    async def get_media_status():
        session_manager = await GlobalSystemMediaTransportControlsSessionManager.request_async()
        session = session_manager.get_current_session()
        if session:
            playback_info = session.get_playback_info()
            if playback_info.playback_status == GlobalSystemMediaTransportControlsSessionPlaybackStatus.PLAYING:
                return True
        return False

    is_playing = asyncio.run(get_media_status())
    sys.exit(0 if is_playing else 1)

except ImportError:
    # winsdk 未安装，尝试安装提示
    print("需要安装: pip install winsdk", file=sys.stderr)
    sys.exit(1)
except Exception as e:
    sys.exit(1)
