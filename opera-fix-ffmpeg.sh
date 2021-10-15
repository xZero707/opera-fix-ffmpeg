#!/usr/bin/env bash
# See: https://forums.opera.com/topic/37539/solving-the-problem-of-the-opera-browser-with-video-playback-in-ubuntu-and-similar-distributions-linux-mint-kde-neon/

OPERA_PATH="${1:-/usr/lib/opera}"

validate_symlink() {
  SYMLINK_DEST=$(readlink "${1}/libffmpeg.so" | egrep '^/snap/chromium-ffmpeg/current/chromium-ffmpeg-[[:digit:]]')

  if [ ! -f "${SYMLINK_DEST}" ]; then
    return 1
  fi
}

# Elevate privileges if possible. Required.
if [ "${EUID:-1000}" != 0 ]; then
  echo "Elevating privileges..."
  sudo "$0" "$@"
  exit $?
fi

if ! command -v snap &>/dev/null; then
  echo "Error: snapd is not installed"
  echo "Command 'snap' not found"

  # For some reason, 'command -v snap' reportedly fails even if snap is installed
  if [ -f /usr/bin/snap ] && [ -x /usr/bin/snap ]; then
    echo "However, executable /usr/bin/snap has been found. Attempting to proceed anyway..."
  else
    exit 1
  fi
fi

if [ ! -d "${OPERA_PATH}" ]; then
  echo "Directory not found '${OPERA_PATH}'. Have you supplied correct Opera path?"
  echo "Example: sudo $0 /usr/lib/opera"
  exit 1
fi

if validate_symlink "${OPERA_PATH}"; then
  echo "Symlink is already up to date. Nothing to do."
  exit 1
fi

if [ ! -d "/snap/chromium-ffmpeg" ]; then
  echo "Attempting to install library chromium-ffmpeg"
  snap install chromium-ffmpeg
else
  echo "Attempting to update library chromium-ffmpeg"
  snap refresh chromium-ffmpeg
fi

LATEST_FFMPEG_VER="$(ls /snap/chromium-ffmpeg/current/ | egrep '^chromium-ffmpeg-[[:digit:]]' | tail -1)"
LATEST_FFMPEG_LIB="/snap/chromium-ffmpeg/current/${LATEST_FFMPEG_VER}/chromium-ffmpeg/libffmpeg.so"

echo "Backing up original ${OPERA_PATH}/libffmpeg.so -> ${OPERA_PATH}/libffmpeg.so.bak"
cp "${OPERA_PATH}/libffmpeg.so" "${OPERA_PATH}/libffmpeg.so.bak"

echo "Symlinking ${LATEST_FFMPEG_LIB} to ${OPERA_PATH}/libffmpeg.so"
ln -sf "${LATEST_FFMPEG_LIB}" "${OPERA_PATH}/libffmpeg.so"

if validate_symlink "${OPERA_PATH}"; then
  echo "Done."
  exit 0
else
  echo "Something went wrong."
  exit 1
fi
