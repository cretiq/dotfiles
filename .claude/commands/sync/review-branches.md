---
description: Review divergence between wsl and mac branches — categorized, with timeline and recommendations
allowed-tools: Bash(git:*), Read
---

## Branch Divergence Review

Compare the current branch against the other machine's branch to understand what diverged, when, and what's worth porting.

### Setup

1. Detect the current branch and the other branch:
   - If on `wsl`, compare against `origin/mac`
   - If on `mac`, compare against `origin/wsl`

2. Fetch the remote branch: `git fetch origin <other-branch>`

3. Find the merge base: `git merge-base HEAD origin/<other>`

### Data Collection

Run these git commands to gather data:

```bash
# Merge base info
git log --format="%ai %s" -1 <merge-base>

# Full diff stat between branches
git diff --stat HEAD origin/<other>

# Per-directory breakdown: files changed and line counts
git diff --numstat HEAD origin/<other>

# Commit log since merge base on CURRENT branch (what we changed)
git log --oneline --since-as-filter=<merge-base-date> HEAD

# Commit log since merge base on OTHER branch (what they changed)
git log --oneline --since-as-filter=<merge-base-date> origin/<other>

# Files only changed on one side (low-hanging fruit)
# Compare: files in `git diff HEAD <merge-base>` vs `git diff origin/<other> <merge-base>`
```

### Presentation

#### 1. Overview Block

```
Branch Review: wsl ↔ mac
Diverged: <date> (<N months ago>) at commit <short-hash> "<message>"
Total: <N> files changed, +<ins> -<del>
```

#### 2. Category Table

Group files by top-level directory (ghostty/, nvim/, zsh/, etc.). Files in the root go under "root".

For each category, show:

```
### <category> — <N files>, +<ins> -<del>

  Local changes (<branch>):
    <date> <commit message>
    <date> <commit message>

  Remote changes (<other-branch>):
    <date> <commit message>
    <date> <commit message>

  Classification: <mac-only | wsl-only | both-changed | one-side-stale>
  Verdict: <keep separate | consider porting → <direction> | investigate | already equivalent>
```

**Classification rules:**
- `mac-only`: files only exist or changed on mac since merge base
- `wsl-only`: files only exist or changed on wsl since merge base
- `both-changed`: both sides modified the same files
- `one-side-stale`: one side has the file but hasn't touched it since the merge base

**Verdict guidelines:**
- Platform-specific configs (windows-terminal, ghostty on mac, powershell) → `keep separate`
- Shared tools where only one side evolved (nvim plugins, zsh aliases) → `consider porting → <direction>`
- Both sides changed the same files → `investigate` (may need manual merge)
- Identical content despite being on both branches → `already equivalent`

#### 3. Low-Hanging Fruit

List files that only changed on ONE side and would apply cleanly to the other:

```
### Easy Ports

→ From mac to wsl:
  ghostty/.config/ghostty/config (theme updates, 2 weeks ago)
  nvim/.config/nvim/lua/plugins/colorscheme.lua (new scheme)

← From wsl to mac:
  zsh/worktree-nav.zsh (new navigation shortcuts)
```

Only include files where the other side still has the original merge-base version (clean apply).

#### 4. Summary Table

```
| Category         | Files | Local | Remote | Verdict          |
|------------------|-------|-------|--------|------------------|
| ghostty          |     5 | stale | active | port ← mac       |
| nvim             |    12 | active| active | investigate      |
| zsh              |     8 | active| stale  | port → wsl       |
| windows-terminal |     3 | active| —      | wsl-only         |
| ...              |       |       |        |                  |
```

### Rules

- Sort categories by most actionable first (investigate > port > keep separate)
- Use relative dates everywhere ("2 weeks ago", "3 months ago")
- Keep commit message summaries to one line each, max 5 per side per category
- If a category has >10 files, summarize rather than listing each one
- Do NOT show diffs — this is a high-level review, not a merge tool
- End with: "Run `git diff HEAD origin/<other> -- <dir>/` to drill into any category."
