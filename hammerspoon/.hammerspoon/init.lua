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

-- Claude Code takes a pasted image on ctrl+v, not cmd+v.
local lundBundle = "app.supabit.supacode.debug"
local screencapture = "/usr/sbin/screencapture"

local function pasteToLund()
  hs.application.launchOrFocusByBundleID(lundBundle)
  hs.timer.doAfter(0.3, function()
    hs.eventtap.keyStroke({"ctrl"}, "v", 0)
    hs.timer.doAfter(0.3, function() hs.eventtap.keyStrokes(" ") end)
  end)
end

-- args: screencapture options that end with the image on the clipboard. An abandoned selection leaves the clipboard unchanged, so nothing is pasted.
local function captureToLund(args)
  local before = hs.pasteboard.changeCount()
  hs.task.new(screencapture, function()
    if hs.pasteboard.changeCount() ~= before then pasteToLund() end
  end, args):start()
end

local function captureFocusedWindow()
  local win = hs.window.focusedWindow()
  if not win then return false end
  local screen, f = win:screen(), win:frame()
  local origin = screen:fullFrame()
  local image = screen:snapshot(hs.geometry.rect(f.x - origin.x, f.y - origin.y, f.w, f.h))
  return image ~= nil and hs.pasteboard.writeObjects(image)
end
local function captureFocusedWindowToLund()
  if captureFocusedWindow() then pasteToLund() end
end
local function captureAreaToLund() captureToLund({"-x", "-c", "-i"}) end
local function capturePickedWindowToLund() captureToLund({"-x", "-c", "-i", "-w"}) end
local function capturePickedWindow() hs.task.new(screencapture, nil, {"-i", "-w"}):start() end

-- macshot URL actions do nothing while it is not running.
if not hs.application.get("macshot") then
  hs.task.new("/usr/bin/open", nil, {"-g", "-a", "macshot"}):start()
end

-- Q10 middle key (L2) number row, all alt+shift+cmd+: 1 sends 7 (focused window), 2 sends 9 (picked window), 3 sends 8 (area), each pasted into Lund.
-- 4 sends 0 (focused window, no paste), 5 sends 2 (picked window, saved as a file). 6, 7, 8 and 9 are macshot's own hotkeys: 4 (area), the + key (history), 3 (OCR text) and 5 (whole screen).
local csMods = {"alt", "shift", "cmd"}
hs.hotkey.bind(csMods, "7", captureFocusedWindowToLund)
hs.hotkey.bind(csMods, "8", captureAreaToLund)
hs.hotkey.bind(csMods, "9", capturePickedWindowToLund)
hs.hotkey.bind(csMods, "0", captureFocusedWindow)
hs.hotkey.bind(csMods, "2", capturePickedWindow)

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

-- Laptop only: with the Q10 attached, L2 already has S/D as tab cycle, arrows, word jump and the capture number row.
local laptopKeys = {
  hs.hotkey.new({"alt"}, "s", function() hs.eventtap.keyStroke({"ctrl", "shift"}, "tab", 0) end),
  hs.hotkey.new({"alt"}, "d", function() hs.eventtap.keyStroke({"ctrl"}, "tab", 0) end),
}

local arrowKeys = {
  h = {"left"}, j = {"down"}, k = {"up"}, l = {"right"},
  u = {"left", {alt = true}}, i = {"right", {alt = true}},
  y = {"left", {cmd = true}}, o = {"right", {cmd = true}},
}
for key, spec in pairs(arrowKeys) do
  local press = function()
    for _, down in ipairs({true, false}) do
      hs.eventtap.event.newKeyEvent(spec[1], down):setFlags(spec[2] or {}):post()
    end
  end
  table.insert(laptopKeys, hs.hotkey.new({"alt"}, key, press, nil, press))
end

local captureKeys = {
  captureFocusedWindowToLund,
  capturePickedWindowToLund,
  captureAreaToLund,
  captureFocusedWindow,
  capturePickedWindow,
  function() hs.urlevent.openURL("macshot://capture") end,
  function() hs.urlevent.openURL("macshot://history") end,
}
for i, capture in ipairs(captureKeys) do
  table.insert(laptopKeys, hs.hotkey.new({"cmd", "shift"}, tostring(i), capture))
end

for key, text in pairs(commands) do
  table.insert(laptopKeys, hs.hotkey.new({"alt", "shift"}, key, function() typeCommand(text, true) end))
end

local aerospaceBin = "/opt/homebrew/bin/aerospace"

-- Fn + key runs an AeroSpace command, Fn + Shift + key the second one. Keycodes 43, 44, 27 and 24 are the keys
-- AeroSpace calls comma, slash, minus and equal: , - + ´ on the Swedish layout.
local fnActions = {
  [hs.keycodes.map.h] = {"focus left", "move left"},
  [hs.keycodes.map.j] = {"focus down", "move down"},
  [hs.keycodes.map.k] = {"focus up", "move up"},
  [hs.keycodes.map.l] = {"focus right", "move right"},
  [hs.keycodes.map.u] = {"join-with left"},
  [hs.keycodes.map.i] = {"join-with down"},
  [hs.keycodes.map.o] = {"join-with up"},
  [hs.keycodes.map.p] = {"join-with right"},
  [hs.keycodes.map.f] = {"layout floating tiling", "fullscreen"},
  [hs.keycodes.map.t] = {"flatten-workspace-tree && aerospace layout tiles horizontal && aerospace balance-sizes"},
  [44] = {"layout tiles horizontal vertical"},
  [43] = {"layout accordion horizontal vertical"},
  [27] = {"resize smart -50"},
  [24] = {"resize smart +50"},
}
for i = 1, 9 do
  fnActions[hs.keycodes.map[tostring(i)]] = {"workspace " .. i, "move-node-to-workspace " .. i}
end
fnTap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(e)
  local f = e:getFlags()
  if not f.fn or f.cmd or f.alt or f.ctrl then return false end
  local code = e:getKeyCode()
  local command = fnActions[code] and fnActions[code][f.shift and 2 or 1]
  if code == hs.keycodes.map.m and not f.shift then
    if e:getProperty(hs.eventtap.event.properties.keyboardEventAutorepeat) == 0 then minimizeFocused() end
    return true
  end
  if not command then return false end
  if e:getProperty(hs.eventtap.event.properties.keyboardEventAutorepeat) == 0 then
    hs.task.new("/bin/sh", nil, {"-c", "export PATH=/opt/homebrew/bin:$PATH; aerospace " .. command}):start()
  end
  return true
end)

local rotatePercentPerDegree = 1
local rotateAngle, rotateVolume, rotateDevice, rotateWrittenAt, rotateNativeAt = nil, nil, nil, 0, 0
local rotateIdle = hs.timer.delayed.new(0.15, function()
  if rotateDevice and rotateVolume then rotateDevice:setVolume(rotateVolume) end
  rotateVolume, rotateDevice = nil, nil
end)
-- degrees: positive is counter-clockwise. Touch frames arrive about 250 times a second and a volume write blocks for about 4 ms, so writes are limited to one per 20 ms and the last value is written once input stops.
local function rotateBy(degrees)
  if not rotateVolume then
    rotateDevice = hs.audiodevice.defaultOutputDevice()
    if not rotateDevice then return end
    rotateVolume = rotateDevice:volume()
  end
  rotateVolume = math.max(0, math.min(100, rotateVolume - degrees * rotatePercentPerDegree))
  local now = hs.timer.secondsSinceEpoch()
  if now - rotateWrittenAt >= 0.02 then
    rotateDevice:setVolume(rotateVolume)
    rotateWrittenAt = now
  end
  rotateIdle:start()
end

-- When both fingers turn, macOS stops sending touches and sends its own rotate events instead: field 110 is 5 and field 164 holds the float32 degrees.
-- When one finger stays put, only touches arrive. Touch y grows upward, so clockwise gives a negative angle change.
-- Touch order and identities change between frames, so the two fingers are treated as an unordered line: the angle is taken modulo 180 degrees.
rotateTap = hs.eventtap.new({hs.eventtap.event.types.gesture}, function(e)
  local now = hs.timer.secondsSinceEpoch()
  local touches = {}
  for _, t in ipairs(e:getTouches() or {}) do
    if t.phase ~= "ended" and t.phase ~= "cancelled" then touches[#touches + 1] = t.normalizedPosition end
  end
  if #touches == 0 then
    if e:getProperty(110) == 5 then
      rotateNativeAt = now
      rotateBy(string.unpack("<f", string.pack("<I4", e:getProperty(164) & 0xFFFFFFFF)))
    end
    return false
  end
  if #touches ~= 2 then
    rotateAngle = nil
    return false
  end
  local angle = math.atan(touches[2].y - touches[1].y, touches[2].x - touches[1].x)
  if rotateAngle and now - rotateNativeAt > 0.15 then
    rotateBy(math.deg((angle - rotateAngle + math.pi / 2) % math.pi - math.pi / 2))
  end
  rotateAngle = angle
  return false
end)

local function syncLaptop()
  hs.task.new(aerospaceBin, nil, {"mode", q10Attached() and "main" or "laptop"}):start()
  for _, k in ipairs(laptopKeys) do
    if q10Attached() then k:disable() else k:enable() end
  end
  if q10Attached() then fnTap:stop() else fnTap:start() end
  if q10Attached() then rotateTap:stop() else rotateTap:start() end
end

keymapWatcher = hs.usb.watcher.new(function(e)
  if e.vendorID == 0x3434 then
    hs.timer.doAfter(1, function()
      syncVimKeymap()
      syncLaptop()
    end)
  end
end):start()
syncVimKeymap()
syncLaptop()

-- AeroSpace starts in main mode, so set the mode again when it launches.
aerospaceWatcher = hs.application.watcher.new(function(name, event)
  if name == "AeroSpace" and event == hs.application.watcher.launched then hs.timer.doAfter(1, syncLaptop) end
end):start()

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
