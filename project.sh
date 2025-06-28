#!/usr/bin/env bash

# === Project Manager Script ===

PROJECTS_DIR="$HOME/Wideo"
PROJECT_NAME="$2"
PROJECT_PATH="$PROJECTS_DIR/$PROJECT_NAME"

function open_folder() {
  gio open "$PROJECT_PATH"
}

function ensure_dir_exists() {
  mkdir -p "$PROJECT_PATH"
}

function sanitize_filename() {
  echo "$1" | tr -cd 'A-Za-z0-9._ -' | tr ' ' '_'
}

# === yt: adaptive quality based on resolution ===
function download_video_adaptive() {
  local url="$1"
  local title clean_title mp4_path mov_path width height dnx_preset scale_filter

  title=$(yt-dlp --get-title "$url")
  clean_title=$(sanitize_filename "$title")
  mp4_path="$PROJECT_PATH/${clean_title}.mp4"
  mov_path="$PROJECT_PATH/${clean_title}.mov"

  echo "[+] Downloading MP4: $title"
  yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]" \
         -o "$mp4_path" "$url" || { echo "[!] Download failed"; return 1; }

  read width height < <(
    ffprobe -v error -select_streams v:0 \
      -show_entries stream=width,height \
      -of default=noprint_wrappers=1:nokey=1 \
      "$mp4_path"
  )
  echo "[i] Source resolution: ${width}x${height}"

  if (( width >= 1920 )); then
    dnx_preset="-c:v dnxhd -b:v 90M -pix_fmt yuv422p"
    scale_filter="scale=1920:1080"
  elif (( width >= 1280 )); then
    dnx_preset="-c:v dnxhd -b:v 75M -pix_fmt yuv422p"
    scale_filter="scale=1280:720"
  else
    echo "[!] Resolution too low for DNxHD target. Skipping conversion."
    return 1
  fi

  echo "[+] Converting to DNxHD MOV..."
  ffmpeg -y -i "$mp4_path" \
    -vf "${scale_filter},fps=30" \
    $dnx_preset \
    -c:a pcm_s16le \
    "$mov_path" || { echo "[!] Conversion failed"; return 1; }

  rm -f "$mp4_path"
  echo "[✓] Saved as: $mov_path"
}

# === ythigh: always convert to full 1080p ===
function download_video_high() {
  local url="$1"
  local title clean_title mp4_path mov_path

  title=$(yt-dlp --get-title "$url")
  clean_title=$(sanitize_filename "$title")
  mp4_path="$PROJECT_PATH/${clean_title}.mp4"
  mov_path="$PROJECT_PATH/${clean_title}.mov"

  echo "[+] Downloading MP4 (up to 1080p): $title"
  yt-dlp -f 'bv*[ext=mp4][height<=1080]+ba[ext=m4a]/b[ext=mp4]' \
         -o "$mp4_path" "$url" || { echo "[!] Download failed"; return 1; }

  echo "[+] Converting to MOV (DNxHD 185M, 1080p)..."
  ffmpeg -i "$mp4_path" \
    -vf "scale=1920:1080,fps=30" \
    -c:v dnxhd -b:v 185M -pix_fmt yuv422p \
    -c:a pcm_s16le \
    "$mov_path" || { echo "[!] Conversion failed"; return 1; }

  rm -f "$mp4_path"
  echo "[✓] Saved as: $mov_path"
}

function download_mp3() {
  local url="$1"
  echo "[+] Downloading MP3: $url"
  yt-dlp -x --audio-format mp3 \
         -o "$PROJECT_PATH/%(title)s.%(ext)s" \
         "$url" || echo "[!] MP3 download failed"
}

function purge_project() {
  echo "[!] Deleting project folder: $PROJECT_PATH"
  rm -rf "$PROJECT_PATH"
  echo "[✓] Deleted"
}

function repl_loop() {
  echo "[*] Entered project shell: '$PROJECT_NAME'"
  echo "Available commands:"
  echo "  yt <url>      - adaptive MOV (DNxHD, based on resolution)"
  echo "  ythigh <url>  - forced high MOV (1080p DNxHD 185M)"
  echo "  ytmp3 <url>   - download audio as MP3"
  echo "  purge         - delete this project folder"
  echo "  exit          - exit project shell"

  while true; do
    read -rp "[$PROJECT_NAME]> " cmd args
    case "$cmd" in
      yt)
        download_video_adaptive "$args"
        ;;
      ythigh)
        download_video_high "$args"
        ;;
      ytmp3)
        download_mp3 "$args"
        ;;
      purge)
        purge_project
        break
        ;;
      exit)
        break
        ;;
      *)
        echo "Unknown command: $cmd"
        ;;
    esac
  done
}

# === Entry Point ===
if [[ "$1" == "open" && -n "$PROJECT_NAME" ]]; then
  ensure_dir_exists
  open_folder
  repl_loop
else
  echo "Usage: project open <project_name>"
  exit 1
fi
