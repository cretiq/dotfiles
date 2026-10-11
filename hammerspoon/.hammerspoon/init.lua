require("hs.ipc")

-- Q10 right space (L3) sends meh (ctrl+shift+alt); left space belongs to aerospace
local meh = {"ctrl", "shift", "alt"}
-- Q10 M3 sends ctrl+shift+cmd
local m3 = {"ctrl", "shift", "cmd"}

local apps = {
  q = "Obsidian",
  f = "Finder",
  a = "Spotify",
  h = "Claude",
  z = "Bitwarden",
  j = "ChatGPT",
  e = "X Pro",
  x = "Xcode",
  b = "BetterTouchTool",
  s = "Simulator",
}
for key, app in pairs(apps) do
  hs.hotkey.bind(m3, key, function() hs.application.launchOrFocus(app) end)
end

local function minimizeFocused()
  local win = hs.window.focusedWindow()
  if win then win:minimize() end
end
hs.hotkey.bind({}, "f1", minimizeFocused)
hs.hotkey.bind({"ctrl", "alt", "cmd"}, "m", minimizeFocused)

hs.hotkey.bind({}, "f2", hs.spaces.toggleMissionControl)

-- CleanShot has no "capture the focused window" command, so capture its rectangle. Its origin is the display's lower left corner.
local function captureFocusedWindow()
  local win = hs.window.focusedWindow()
  if not win then return end
  local f, screen = win:frame(), win:screen()
  local sf = screen:fullFrame()
  local display, other = 1, 1
  for _, s in ipairs(hs.screen.allScreens()) do
    if s ~= hs.screen.primaryScreen() then other = other + 1 end
    if s == screen then display = (s == hs.screen.primaryScreen()) and 1 or other end
  end
  hs.urlevent.openURL(string.format("cleanshot://capture-area?x=%d&y=%d&width=%d&height=%d&display=%d",
    f.x - sf.x, sf.h - (f.y - sf.y) - f.h, f.w, f.h, display))
end
-- Q10 middle key (L2) + 7 sends alt+shift+cmd+7
hs.hotkey.bind({"alt", "shift", "cmd"}, "7", captureFocusedWindow)

local function mediaKey(name)
  return function()
    hs.eventtap.event.newSystemKeyEvent(name, true):post()
    hs.eventtap.event.newSystemKeyEvent(name, false):post()
  end
end
hs.hotkey.bind({}, "f7", mediaKey("PREVIOUS"))
hs.hotkey.bind({}, "f8", mediaKey("PLAY"))
hs.hotkey.bind({}, "f9", mediaKey("NEXT"))
hs.hotkey.bind({}, "f10", mediaKey("MUTE"))
volumeDownTap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(e)
  if e:getKeyCode() == hs.keycodes.map.f11 and next(e:getFlags()) == nil then
    mediaKey("SOUND_DOWN")()
    return true
  end
end):start()
hs.hotkey.bind({}, "f12", mediaKey("SOUND_UP"), nil, mediaKey("SOUND_UP"))

local lastDockMinimize = 0
dockScrollTap = hs.eventtap.new({hs.eventtap.event.types.scrollWheel}, function(e)
  local pos = hs.mouse.absolutePosition()
  local screen = hs.mouse.getCurrentScreen()
  if not screen or pos.y < screen:fullFrame().h - 110 then return false end
  local el = hs.axuielement.systemElementAtPosition(pos)
  if not el or el.AXSubrole ~= "AXApplicationDockItem" then return false end
  if e:getProperty(hs.eventtap.event.properties.scrollWheelEventDeltaAxis1) < 0 and hs.timer.secondsSinceEpoch() - lastDockMinimize > 0.5 then
    lastDockMinimize = hs.timer.secondsSinceEpoch()
    local app = hs.application.find(el.AXTitle)
    if app then
      for _, win in ipairs(app:allWindows()) do win:minimize() end
    end
  end
  return true
end):start()

local function typeSlowly(text, delay, done)
  local i = 0
  local timer
  timer = hs.timer.doEvery(delay, function()
    i = i + 1
    hs.eventtap.keyStrokes(text:sub(i, i))
    if i == #text then
      timer:stop()
      if done then done() end
    end
  end)
end

local function typeCommand(text, submit, done)
  typeSlowly(text, 0.003, function()
    hs.timer.doAfter(0.03, function()
      if submit then hs.eventtap.keyStroke({}, "return", 10000) end
      if done then hs.timer.doAfter(0.3, done) end
    end)
  end)
end

local commands = {
  n = "/next ",
  c = "/cut ",
  o = "/compact ",
  x = "/copy ",
  r = "/rebuild ",
  d = "done",
}
for key, text in pairs(commands) do
  hs.hotkey.bind(meh, key, function() typeCommand(text, true) end)
end

-- Claude Code queues a command sent mid-turn and runs it after the turn, so /copy picks up the generated title.
hs.hotkey.bind(meh, "z", function()
  typeCommand("/generate:short-title ", true, function()
    typeCommand("/copy ", true, function()
      typeCommand("/rename ", false)
    end)
  end)
end)

-- Keychron Q10 Max: the cable (PID 0x08A1) gets the newest Mac layout on connect. The 2.4 GHz receiver is never written.
-- Pause: create ~/.local/share/q10/auto-off. The q10 binary is built from keyboard/q10max/q10.swift.
local q10Bin = os.getenv("HOME") .. "/.local/share/q10"
local q10Layouts = os.getenv("HOME") .. "/.dotfiles/keyboard/q10max"
local q10Tries = 0

local function newestMacLayout()
  local best, bestN = nil, -1
  for f in hs.fs.dir(q10Layouts) do
    local n = tonumber(f:match("^q10max%-v(%d+)%.json$"))
    if n and n > bestN then best, bestN = f, n end
  end
  return best and (q10Layouts .. "/" .. best)
end

local function launcherOpen()
  for _, w in ipairs(hs.window.allWindows()) do
    if (w:title() or ""):find("Keychron Launcher", 1, true) then return true end
  end
  return false
end

local q10Waits = 0
local function applyQ10()
  if hs.fs.attributes(q10Bin .. "/auto-off") then return end
  local layout = newestMacLayout()
  if not layout then return end
  if launcherOpen() and q10Waits < 12 then
    if q10Waits == 0 then hs.alert.show("Q10: close the Keychron Launcher tab to apply the Mac layout", 8) end
    q10Waits = q10Waits + 1
    hs.timer.doAfter(5, applyQ10)
    return
  end
  q10Waits = 0
  hs.task.new(q10Bin .. "/q10", function(_, out)
    if out:find("Verified") then
      hs.alert.show("Q10: Mac layout applied")
    elseif out:find("already matches") then
      hs.alert.show("Q10: Mac layout already set")
    else
      q10Tries = q10Tries + 1
      if q10Tries < 3 then
        hs.timer.doAfter(3, applyQ10)
      else
        hs.alert.show("Q10: could not apply the Mac layout. Is the Keychron Launcher tab open?", 8)
      end
    end
  end, {"apply", "-f", layout, "--yes", "--max-cells", "150"}):start()
end

q10Watcher = hs.usb.watcher.new(function(e)
  if e.eventType == "added" and e.vendorID == 0x3434 and e.productID == 0x08A1 then
    q10Tries = 0
    hs.timer.doAfter(3, applyQ10)
  end
end):start()

for _, d in ipairs(hs.usb.attachedDevices()) do
  if d.vendorID == 0x3434 and d.productID == 0x08A1 then hs.timer.doAfter(3, applyQ10) end
end

-- Q10 attached (cable or 2.4 GHz receiver) = desk: JKLÖ. Otherwise laptop keyboard: HJKL.
local keymapScript = os.getenv("HOME") .. "/.dotfiles/my_scripts/.script/vim-keymap-toggle.sh"
local keymapStateFile = os.getenv("HOME") .. "/.dotfiles/vim/.vim/keymap_state"

local function q10Attached()
  for _, d in ipairs(hs.usb.attachedDevices()) do
    if d.vendorID == 0x3434 and (d.productID == 0x08A1 or d.productID == 0xD030) then return true end
  end
  return false
end

local function syncVimKeymap()
  local want = q10Attached() and "custom" or "default"
  local f = io.open(keymapStateFile)
  local have = f and f:read("*l")
  if f then f:close() end
  if have ~= want then hs.task.new(keymapScript, nil, {want}):start() end
end

keymapWatcher = hs.usb.watcher.new(function(e)
  if e.vendorID == 0x3434 then hs.timer.doAfter(1, syncVimKeymap) end
end):start()
syncVimKeymap()

-- macOS steps volume and brightness in quarters when Option is held with Shift; the knob cannot send that conditionally.
local fineKeys = {SOUND_UP = true, SOUND_DOWN = true, BRIGHTNESS_UP = true, BRIGHTNESS_DOWN = true}
fineStepTap = hs.eventtap.new({hs.eventtap.event.types.systemDefined}, function(e)
  local k = e:systemKey()
  local f = e:getFlags()
  if k and fineKeys[k.key] and f.shift and not f.alt then
    local ev = hs.eventtap.event.newSystemKeyEvent(k.key, k.down)
    ev:setFlags({shift = true, alt = true})
    ev:post()
    return true
  end
end):start()

-- Over the 2.4 GHz dongle macOS numbers the key above Tab as 50 instead of 10, and Convey and VolumeGuard listen for 10.
for _, mods in ipairs({{"cmd", "shift"}, meh}) do
  hs.hotkey.bind(mods, 50, function()
    hs.eventtap.event.newKeyEvent(mods, 10, true):post()
    hs.eventtap.event.newKeyEvent(mods, 10, false):post()
  end)
end

hs.alert.show("Hammerspoon config loaded")
