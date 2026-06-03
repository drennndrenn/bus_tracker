Free-tier tracking ad assets (shown before Track Bus for non-Pro users)

VIDEO (preferred):
  video-ads.mp4
  - Plays once (no loop) with sound on by default. Mute/unmute via the speaker icon on the video.
  - When it ends, tracking starts automatically.
  - Continue is enabled after a 6-second countdown; the video keeps playing until the user taps Continue or the clip ends.
  - H.264 MP4 recommended (e.g. 1280 x 720 landscape).

IMAGE (fallback if video is missing or fails):
  free_tracking_ad.png

If both fail, the app uses assets/logo.png with a 7–9 second timer.

After adding or replacing files: flutter pub get, then fully restart the app.
