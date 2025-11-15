#!/usr/bin/env bash

TARGET_CAPTURE_DEV="/dev/video0"
TARGET_INPUT="1"

# 1. ビデオ入力（Composite1）
v4l2-ctl -d $TARGET_CAPTURE_DEV --set-input="$TARGET_INPUT"

# 2. ビデオ標準（NTSC-M）
v4l2-ctl -d $TARGET_CAPTURE_DEV --set-standard=0x00001000   # NTSC-M のビットマスク
#v4l2-ctl -d $DEV --set-standard=ntsc

# 3. フォーマット（720x480, YU12, Interlaced）
v4l2-ctl -d $TARGET_CAPTURE_DEV --set-fmt-video=width=720,height=480,pixelformat=YU12,field=interlaced

# 4. フレームレート（29.97fps = 30000/1001）
v4l2-ctl -d $TARGET_CAPTURE_DEV --set-parm=30000/1001

# 5. クロップ（必要なら。デフォルトで 768x480 → 720x480 にトリミング）
v4l2-ctl -d $TARGET_CAPTURE_DEV --set-crop=left=128,top=46,width=768,height=480

# 6. ターゲットを再生
mpv av://v4l2:${TARGET_CAPTURE_DEV} \
    --no-cache \
    --profile=low-latency \
    --untimed \
    --video-sync=display-resample \
    --hwdec=auto-safe \
    --stream-lavf-o=fflags=nobuffer
