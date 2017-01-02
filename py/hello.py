from __future__ import print_function
import time
import pychromecast

chromecasts = pychromecast.get_chromecasts()
[cc.device.friendly_name for cc in chromecasts]

cast = next(cc for cc in chromecasts if cc.device.friendly_name == "L2-Bedroom-Guest")
# Wait for cast device to be ready
cast.wait()
print(cast.device)
#DeviceStatus(friendly_name='Living Room', model_name='Chromecast', manufacturer='Google Inc.', api_version=(1, 0), uuid=UUID('df6944da-f016-4cb8-97d0-3da2ccaa380b'), cast_type='cast')

print(cast.status)
#CastStatus(is_active_input=True, is_stand_by=False, volume_level=1.0, volume_muted=False, app_id=u'CC1AD845', display_name=u'Default Media Receiver', namespaces=[u'urn:x-cast:com.google.cast.player.message', u'urn:x-cast:com.google.cast.media'], session_id=u'CCA39713-9A4F-34A6-A8BF-5D97BE7ECA5C', transport_id=u'web-9', status_text='')


mc = cast.media_controller

mc.play_media('http://192.168.0.103:3000/audio/white-noise/1-01%20The%20Brahmin's%20Son.mp3', 'audio/mp3')
#mc.play_media('http://stream.wbez.org/wbez128.mp3', 'audio/mp3')
print(mc.status)
#MediaStatus(current_time=42.458322, content_id=u'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4', content_type=u'video/mp4', duration=596.474195, stream_type=u'BUFFERED', idle_reason=None, media_session_id=1, playback_rate=1, player_state=u'PLAYING', supported_media_commands=15, volume_level=1, volume_muted=False)

time.sleep(10)
#mc.pause()
#time.sleep(5)
#mc.play()
