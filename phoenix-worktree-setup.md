# Phoenix Project Worktree + Claude Code Setup

Scaffold my Phoenix development environment with git worktrees and shared Claude Code config.

## 1. Clone the main repo

```bash
cd /mnt/c/Dev
git clone http://gitlab.rco.local/m5/phoenix.git phoenix
```

## 2. Create worktrees

From inside the main repo, create worktrees at the same directory level:

```bash
cd /mnt/c/Dev/phoenix
git worktree add ../phoenix-main main
git worktree add ../phoenix-second -b second
git worktree add ../phoenix-third -b third
git worktree add ../phoenix-fourth -b fourth
```

Adjust branch names as needed — these are just slots for parallel work.

## 3. Clone shared Claude Code config

```bash
cd ~
git clone git@github.com:cretiq/claude-phoenix.git .claude_phoenix
```

This repo contains:
- `CLAUDE.md` — project instructions, quality gates, architecture docs
- `commands/` — custom slash commands
- `skills/` — custom skills/workflows
- `settings.local.json` — permission patterns (allow/ask/deny lists)

## 4. Symlink .claude into every worktree

Each worktree (and the main repo) needs a `.claude` symlink pointing to the shared config:

```bash
ln -s /home/filip/.claude_phoenix /mnt/c/Dev/phoenix/.claude
ln -s /home/filip/.claude_phoenix /mnt/c/Dev/phoenix-main/.claude
ln -s /home/filip/.claude_phoenix /mnt/c/Dev/phoenix-second/.claude
ln -s /home/filip/.claude_phoenix /mnt/c/Dev/phoenix-third/.claude
ln -s /home/filip/.claude_phoenix /mnt/c/Dev/phoenix-fourth/.claude
```

**Why symlinks?** All worktrees share the same Claude Code config — one place to update CLAUDE.md, permissions, commands, and skills.

**Important:** The symlink target is a WSL path (`/home/...`), not a Windows path. This works because Claude Code runs inside WSL.

## 5. Verify

```bash
# Check worktrees
cd /mnt/c/Dev/phoenix && git worktree list

# Check symlinks
ls -la /mnt/c/Dev/phoenix*/.claude

# Each should show: .claude -> /home/filip/.claude_phoenix
```

## Notes

- The main repo at `/mnt/c/Dev/phoenix/` has the full `.git/` directory; worktrees have `.git` files pointing back to it
- All worktrees share git objects — disk efficient
- Adjust username in symlink paths for the new machine
- The `.claude_phoenix` repo is independent of the Phoenix repo — update and push it separately
