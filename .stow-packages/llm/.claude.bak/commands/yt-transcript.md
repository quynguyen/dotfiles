---
description: Fetch a YouTube video transcript and save as markdown
argument-hint: <youtube-url>
---

# /yt-transcript

## Purpose

Fetch a YouTube video's transcript and save it as a timestamped markdown file.

## Contract

**Inputs:** `$ARGUMENTS` — a YouTube URL (full, short, or shorts format)
**Outputs:** `STATUS=<OK|FAIL> PATH=<transcript-file>`

## Instructions

1. **Validate inputs:**
   - Check that `$ARGUMENTS` contains a YouTube URL
   - Accepted formats:
     - `https://www.youtube.com/watch?v=...`
     - `https://youtu.be/...`
     - `https://www.youtube.com/shorts/...`
   - If no URL is provided, ask the user for one

2. **Fetch the transcript:**

   ```bash
   yt-transcript "$ARGUMENTS"
   ```

3. **Output status:**
   - On success: print `STATUS=OK PATH=<path-to-generated-file>`
   - On failure: print `STATUS=FAIL ERROR="<error message>"`

## Constraints

- Requires `yt-transcript` CLI tool (uses `uv` to manage `youtube-transcript-api` dependency)
- Output file is saved in the current directory as `transcript-[date]-[video-title-slug].md`
- Timestamps formatted as [MM:SS] or [H:MM:SS] for videos over an hour
