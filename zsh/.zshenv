. "$HOME/.cargo/env"

# Claude Code cross-session messaging needs a private 0700 runtime dir. WSLg sets
# XDG_RUNTIME_DIR=/mnt/wslg/runtime-dir, which is 0777 with no sticky bit, and
# Claude refuses to bind sockets under it:
#   "a sockets-directory component is not a private-or-sticky directory owned by
#    us or root — refusing to bind"
# Symlink the WSLg entries back in so wayland-0, pulse and fnm_multishells keep
# resolving. This lives in .zshenv, not .zshrc, so non-interactive zsh gets it too
# (`zsh -c claude`, IDE terminals, scripts). Must run before the fnm eval in .zshrc.
if [[ -n $WSL_DISTRO_NAME && -d /dev/shm ]]; then
  export XDG_RUNTIME_DIR=/dev/shm/cc-run-$UID
  mkdir -p "$XDG_RUNTIME_DIR" && chmod 700 "$XDG_RUNTIME_DIR"
  for _wslg_entry in /mnt/wslg/runtime-dir/*(N); do
    ln -sfn "$_wslg_entry" "$XDG_RUNTIME_DIR/${_wslg_entry:t}"
  done
  unset _wslg_entry
fi
