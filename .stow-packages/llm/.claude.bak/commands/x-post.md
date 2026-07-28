---
description: Fetch an X/Twitter post (with threads and images) and save as markdown
argument-hint: <x-post-url>
---

# /x-post

## Purpose

Fetch X/Twitter posts using the `browse` skill with authenticated cookies. Captures full thread content, downloads images, saves to `./docs/media/x/`, and prints inline for immediate conversation use.

## Contract

**Inputs:** `$ARGUMENTS` — one or more X/Twitter post URLs (space-separated)
**Outputs:** For each URL: markdown file + inline content + `STATUS=OK PATH=<path>` or `STATUS=FAIL ERROR="<message>"`

## Instructions

Process each URL in `$ARGUMENTS` sequentially. For each URL, follow steps 1-6 below.

### 1. Validate the URL

Check that the URL matches one of these patterns (with or without query parameters):
- `https://x.com/{user}/status/{id}`
- `https://twitter.com/{user}/status/{id}`

Extract `{user}` (the handle) and `{id}` (the post ID) from the URL.

**If `$ARGUMENTS` is empty:** ask the user for a URL.
**If a URL doesn't match:** print `STATUS=FAIL ERROR="Invalid X/Twitter URL: <url>"` and skip it.

### 2. Authenticate

Start a browse session and check for authentication:

```bash
$B goto "https://x.com"
$B text
```

Check the page text for login wall indicators: "Sign in", "Log in to X", "Create your account", or a redirect to a login/signup page.

**If unauthenticated:**
1. Tell the user: "X requires authentication. Importing cookies..."
2. Try importing cookies from available browsers (try `chrome` first, then `comet`, then `brave`, then `edge`):
   ```bash
   $B cookie-import-browser chrome --domain x.com
   ```
   If one browser fails, try the next. After a successful import, the browse session may need a restart:
   ```bash
   $B stop
   # (browse auto-restarts on next command)
   ```
3. Retry: `$B goto "https://x.com"` and `$B text`
4. If still unauthenticated: print `STATUS=FAIL ERROR="Authentication required — could not import x.com cookies"` and stop.

**If authenticated:** proceed to step 3.

### 3. Extract the post

Navigate to the post URL:

```bash
$B goto "<post-url>"
```

Use `$B text` to get the page content. Extract:

- **Author display name** — the name shown above the post
- **Author handle** — the `@username`
- **Post text** — the full text content, preserving line breaks
- **Post date** — the date/time shown on the post
- **Engagement metrics** (best-effort) — replies, reposts, likes, views
- **Quote tweet** (if present) — the quoted post's author, handle, and text
- **Media** — note any images or videos attached

If `$B text` doesn't give clean structured data, use `$B snapshot` to get the accessibility tree and extract from element labels, or use `$B html` with selectors like `[data-testid="tweetText"]`, `[data-testid="User-Name"]`, etc.

### 4. Detect and follow threads

After extracting the target post, check if it's part of a self-reply thread:

**Detection:** Look for indicators that the post is a reply to the same author, or that there are earlier posts in a thread by the same author above the target post on the page.

**If thread detected:**
1. Walk back to the thread root — the first post in the self-reply chain by this author. The thread view on X typically shows the full chain when you view any post in it.
2. Extract each post in the thread by the same author, in chronological order, using step 3's extraction logic.
3. Stop at replies by other users — only follow self-replies.

**If standalone post:** use only the single post from step 3.

### 5. Download images

For each post (including thread posts):

1. Identify attached images by checking for `pbs.twimg.com/media/` URLs in the page. Use JavaScript to query for them:
   ```bash
   $B js "JSON.stringify(Array.from(document.querySelectorAll('img[src*=\"pbs.twimg.com/media\"]')).map(i => i.src))"
   ```
   Alternatively, try `$B media --images` (may not be available in all browse versions).
2. Create the output directory if needed: `mkdir -p ./docs/media/x/`
3. Download each image:
   ```bash
   $B download "<image-url>" "./docs/media/x/{handle}-{postid}-{n}.jpg"
   ```
   Where:
   - `{handle}` — author handle without `@`
   - `{postid}` — the status ID of the specific post containing the image
   - `{n}` — 1-indexed image number within that post
   - Use the actual file extension if detectable, otherwise default to `.jpg`

4. For videos: do not download. Note `[Video]` in the markdown output.

### 6. Generate markdown and print inline

Assemble the output markdown file:

```markdown
---
author: "@{handle}"
name: "{display_name}"
url: {canonical_x_url}
date: {YYYY-MM-DD}
fetched: {today_YYYY-MM-DD}
thread: {true|false}
---

# @{handle} — {Mon DD, YYYY}

{post_text}

{for each image: ![image-{n}](./{handle}-{postid}-{n}.jpg)}

{if quote tweet:}
> **@{quoted_handle}:** {quoted_text}

---

**Replies:** {N} · **Reposts:** {N} · **Likes:** {N} · **Views:** {N}
```

For threads, append each subsequent post:

```markdown

## Thread (2/{total})

{post_text}

{images if any}

---

**Replies:** {N} · **Reposts:** {N} · **Likes:** {N} · **Views:** {N}

## Thread (3/{total})

{post_text}

...
```

Write the file to `./docs/media/x/{handle}-{postid}.md` where `{postid}` is the root post's ID (from the URL, or the thread root if thread was detected).

Print the full markdown content inline to the conversation, then print:
`STATUS=OK PATH=./docs/media/x/{handle}-{postid}.md`

## Constraints

- Thread following is self-replies only (same author), not general replies
- Videos are referenced as `[Video]`, not downloaded
- Engagement metrics are best-effort — page rendering varies
- Re-fetching the same URL overwrites the existing file
- Requires the `browse` skill (`$B` binary) for all browser interaction
