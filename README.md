# Youtube editing manager
A simple Bash script to manage project folders and download YouTube videos optimized for editing in **DaVinci Resolve on Linux**.  

It allows you to open/create project folders, download YouTube videos converted to **DNxHD MOV format** (compatible with DaVinci Resolve Linux)

---
![obraz](https://github.com/user-attachments/assets/5ade8489-8be7-478d-bcd7-7ce42915074c)

## Features

- Create or open project directories inside `~/Videos/`
- Open project folder in GNOME file manager
- Command prompt for project management
- Download YouTube videos at 1080p+ quality and convert to **DNxHD MOV** with PCM audio
- Download audio-only MP3 files from YouTube videos
- Purge (delete) the entire project folder
- Simple commands: `yt`, `ytmp3`, `purge`, `exit`

---

## Requirements

- Linux environment (tested on Ubuntu/Debian)
- [yt-dlp](https://github.com/yt-dlp/yt-dlp) - YouTube downloader  
- [ffmpeg](https://ffmpeg.org/) - Multimedia converter  
- GNOME desktop environment (for `gio open` command to open folders)  

Install dependencies on Ubuntu/Debian:

```bash
sudo apt update
sudo apt install ffmpeg yt-dlp
```

## Usage

Open or create a project folder:
```bash
project open <project_name>
```

This will:
- Create ~/Videos/<project_name> folder if it doesn't exist
- Open it in GNOME file manager
- Enter an interactive shell for commands related to the project

## Commands

```bash
    yt <YouTube URL>
    Download best quality video + audio, convert to DNxHD MOV (1080p, PCM audio), ideal for DaVinci Resolve on Linux.

    ytmp3 <YouTube URL>
    Download audio-only and convert to MP3 format.

    purge
    Delete the entire project folder and exit the interactive mode.

    exit
    Exit the interactive mode without deleting anything.
```
