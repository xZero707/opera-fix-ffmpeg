#!/usr/bin/env bash
# default installation path of Opera using their .deb file on Pop!_OS
OPERA_PATH="${1:-/usr/lib/x86_64-linux-gnu/opera}"
SNAP_BINARY="${2:-/usr/bin/snap}"

validate_symlink() {
  if [ ! -d "/snap/chromium-ffmpeg" ]; then
    return 1;
  fi

  SYMLINK_DEST=$(readlink "${1}/libffmpeg.so" | grep -E '^/snap/chromium-ffmpeg/current/chromium-ffmpeg-[[:digit:]]')

  if [ ! -f "${SYMLINK_DEST}" ]; then
    return 1
  fi
}

if [ ! -d "${OPERA_PATH}" ]; then
  echo "Directory not found '${OPERA_PATH}'. Have you supplied correct Opera path?"
  echo "Example: sudo $0 /usr/lib/opera"
  exit 1
fi

if validate_symlink "${OPERA_PATH}"; then
  echo "Symlink is already up to date. Nothing to do."
# setting exit code to 0 so that the script does not create issues with apt post operations if automated
# also, why would you set this to non-zero? This is a correct behaviour...
  exit 0
fi

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
  if [ ! -f "${SNAP_BINARY}" ] || [ ! -x "${SNAP_BINARY}" ]; then
    echo "All checks have failed. ${SNAP_BINARY} is not present and/or valid."
    echo "If you think this is a mistake, you can supply correct path as second argument."
    echo "Example: sudo $0 /usr/lib/opera /usr/bin/snap"
    exit 1
  fi

  echo "However, executable ${SNAP_BINARY} has been found. Attempting to proceed anyway..."
fi

if [ ! -d "/snap/chromium-ffmpeg" ]; then
  echo "Attempting to install library chromium-ffmpeg"
  "${SNAP_BINARY}" install chromium-ffmpeg
else
  echo "Attempting to update library chromium-ffmpeg"
  "${SNAP_BINARY}" refresh chromium-ffmpeg
fi

LATEST_FFMPEG_VER="$(ls /snap/chromium-ffmpeg/current/ | grep -E '^chromium-ffmpeg-[[:digit:]]'| awk -F- '{ print $3; }'|sort -n|tail -1)"
LATEST_FFMPEG_LIB="/snap/chromium-ffmpeg/current/chromium-ffmpeg-${LATEST_FFMPEG_VER}/chromium-ffmpeg/libffmpeg.so"

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
