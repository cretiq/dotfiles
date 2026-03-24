# Phoenix Project Worktree + Claude Code Setup

Scaffold my Phoenix development environment with git worktrees and shared Claude Code config.

## 1. Clone the main repo

```bash
cd ~/Dev
git clone http://gitlab.rco.local/m5/phoenix.git phoenix
```

## 2. Create worktrees

From inside the main repo, create worktrees as subdirectories:

```bash
cd ~/Dev/phoenix
git worktree add p1 main
git worktree add p2 -b second
git worktree add p3 -b third
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

Each worktree needs a `.claude` symlink pointing to the shared config:

```bash
ln -sf ~/.claude_phoenix ~/Dev/phoenix/p1/.claude
ln -sf ~/.claude_phoenix ~/Dev/phoenix/p2/.claude
ln -sf ~/.claude_phoenix ~/Dev/phoenix/p3/.claude
```

**Why symlinks?** All worktrees share the same Claude Code config — one place to update CLAUDE.md, permissions, commands, and skills.

## 5. Verify

```bash
# Check worktrees
cd ~/Dev/phoenix && git worktree list

# Check symlinks
ls -la ~/Dev/phoenix/p*/.claude

# Each should show: .claude -> /home/filip/.claude_phoenix
```

## Notes

- The main repo at `~/Dev/phoenix/` has the full `.git/` directory; worktrees have `.git` files pointing back to it
- All worktrees share git objects — disk efficient
- Adjust username in symlink paths for the new machine
- The `.claude_phoenix` repo is independent of the Phoenix repo — update and push it separately
