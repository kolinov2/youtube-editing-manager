#!/usr/bin/env bash

# Base directory
BASE_DIR="$HOME/Videos"

# Argument check
if [[ "$1" != "open" || -z "$2" ]]; then
  echo "Usage: project.sh open <project_name>"
  exit 1
fi

PROJECT_NAME="$2"
PROJECT_PATH="$BASE_DIR/$PROJECT_NAME"

# Create project folder if it doesn't exist
if [[ ! -d "$PROJECT_PATH" ]]; then
  mkdir -p "$PROJECT_PATH"
  echo "Created directory: $PROJECT_PATH"
else
  echo "Directory already exists: $PROJECT_PATH"
fi

# Open GNOME file manager
gio open "$PROJECT_PATH"

# Comands
echo "=== Project '$PROJECT_NAME' — Interactive Mode ==="
echo "Available commands:"
echo "  yt <YouTube URL>      — Download video as .mov (DNxHD, PCM audio)"
echo "  ytmp3 <YouTube URL>   — Download audio as .mp3"
echo "  purge                 — Delete this project folder and exit"
echo "  exit                  — Exit this project session"

while true; do
  read -rp "> " command args
  case "$command" in
    yt)
      if [[ -z "$args" ]]; then
        echo "Usage: yt <YouTube URL>"
        continue
      fi
      echo "Downloading best available video from YouTube: $args"

      # Download video + audio in best quality to temp file
      yt-dlp \
        -f "bv*[height>=1080]+ba/best" \
        -o "${PROJECT_PATH}/temp.%(ext)s" \
        "$args"

      TEMP_FILE=$(ls "${PROJECT_PATH}/temp."* 2>/dev/null)
      if [[ ! -f "$TEMP_FILE" ]]; then
        echo "Download failed."
        continue
      fi

      # Safe title for filename
      TITLE=$(yt-dlp --get-title "$args" | head -n 1 | tr -dc '[:alnum:] _-')
      OUTPUT_FILE="${PROJECT_PATH}/${TITLE}.mov"

      echo "Converting to DNxHD (.mov) without scaling..."
      ffmpeg -i "$TEMP_FILE" \
        -c:v dnxhd -b:v 120M \
        -c:a pcm_s16le \
        "$OUTPUT_FILE"

      rm "$TEMP_FILE"
      echo "Done. Saved as: $OUTPUT_FILE"
      ;;
    
    ytmp3)
      if [[ -z "$args" ]]; then
        echo "Usage: ytmp3 <YouTube URL>"
        continue
      fi
      echo "Downloading audio as MP3: $args"
      yt-dlp \
        -x --audio-format mp3 \
        -o "${PROJECT_PATH}/%(title)s.%(ext)s" \
        "$args"
      echo "Download complete."
      ;;

    purge)
      echo "Removing project folder: $PROJECT_PATH"
      rm -rf "$PROJECT_PATH"
      echo "Deleted. Exiting."
      break
      ;;

    exit)
      echo "Exiting."
      break
      ;;

    *)
      echo "Unknown command: '$command'. Available: yt, ytmp3, purge, exit"
      ;;
  esac
done
