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
-- Installed, agent-built and scratch Lunds share one bundle id, so a bundle id lookup can land on a windowless or stale one.
-- The target is the instance last in front, else any with a window.
-- Lund-dev and the real Lund (/Applications/Lund.app) have different bundle ids; every Lund key applies to both.
local lundBundles = {"app.supabit.supacode.debug", "app.supabit.supacode"}
local function isLund(app)
  local id = app and app:bundleID()
  for _, bundle in ipairs(lundBundles) do
    if id == bundle then return true end
  end
  return false
end
local lundPath = os.getenv("HOME") .. "/Applications/Lund-dev.app"
local screencapture = "/usr/sbin/screencapture"

local lundLast = hs.application.frontmostApplication()
if not isLund(lundLast) then lundLast = nil end
lundWatcher = hs.application.watcher.new(function(_, event, app)
  if event == hs.application.watcher.activated and isLund(app) then lundLast = app end
end):start()

-- Cmd+. , Cmd+B and Cmd+U in Lund go to the first tab of the .dotfiles, business-hub and Lund repos. Lund's own Stop Run Script uses Cmd+. too, so while Lund is in front this takes it.
-- Cmd+L is Lund's split navigation, so the Lund repo sits on Cmd+U instead.
-- The Lund CLI of the instance in front talks to that instance's socket, which is named after its pid.
local lundRepoKeys = {
  ["."] = "/.dotfiles/",
  b = "/CursorProjects/webapps/business-hub/",
  u = "/CursorProjects/macapps/Lund/",
}
local function focusFirstRepoTab(repoPath)
  local app = hs.application.frontmostApplication()
  if not isLund(app) then return end
  local worktree = (os.getenv("HOME") .. repoPath):gsub("/", "%%2F")
  local cli = app:path() .. "/Contents/Resources/bin/supacode"
  local script = string.format(
    'export SUPACODE_SOCKET_PATH=/tmp/supacode-$(id -u)/pid-%d; tab=$("%s" tab list -w "%s" | head -n 1); [ -n "$tab" ] && "%s" tab focus -w "%s" -t "$tab"',
    app:pid(), cli, worktree, cli, worktree)
  hs.task.new("/bin/sh", nil, {"-c", script}):start()
end
lundRepoHotkeys = {}
for key, repoPath in pairs(lundRepoKeys) do
  table.insert(lundRepoHotkeys, hs.hotkey.new({"cmd"}, key, function() focusFirstRepoTab(repoPath) end))
end
local function setLundRepoHotkeys(enabled)
  for _, hotkey in ipairs(lundRepoHotkeys) do
    if enabled then hotkey:enable() else hotkey:disable() end
  end
end
setLundRepoHotkeys(isLund(hs.application.frontmostApplication()))
lundRepoWatcher = hs.application.watcher.new(function(_, event, app)
  if event ~= hs.application.watcher.activated then return end
  setLundRepoHotkeys(isLund(app))
end):start()

local function focusLund()
  local target = lundLast
  if not (target and target:isRunning() and #target:allWindows() > 0) then
    target = nil
    for _, bundle in ipairs(lundBundles) do
      for _, app in ipairs(hs.application.applicationsForBundleID(bundle)) do
        if not target and #app:allWindows() > 0 then target = app end
      end
    end
  end
  if target then target:activate() else hs.application.launchOrFocus(lundPath) end
end

-- Abort when Lund did not come to the front: the space would scroll whatever app is there instead.
local function pasteToLund()
  focusLund()
  hs.timer.doAfter(0.3, function()
    local front = hs.application.frontmostApplication()
    if not isLund(front) then return end
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
local function titleCopyRename(titleCommand)
  typeCommand(titleCommand, true, function()
    typeCommand("/copy ", true, function()
      typeCommand("/rename ", false)
    end)
  end)
end
hs.hotkey.bind(meh, "z", function() titleCopyRename("/generate:short-title ") end)

-- Voyager layer 7 (ctrl+alt+cmd): the Mac side of the Windows AutoHotkey slash-command chords, run from voyagerKeyTap so no other keyboard triggers them.
-- The keys are still held when the chord arrives, so typing waits for them to be released.
local function whenModifiersReleased(fn)
  if next(hs.eventtap.checkKeyboardModifiers()) == nil then return fn() end
  hs.timer.doAfter(0.02, function() whenModifiersReleased(fn) end)
end
local voyagerCommands = {
  [hs.keycodes.map.d] = "/dev:restart ",
  [hs.keycodes.map.n] = "/next ",
  [hs.keycodes.map.c] = "/cut ",
  [hs.keycodes.map.r] = "/rebuild ",
  [hs.keycodes.map.o] = "/git:commit-detailed-push ",
  [hs.keycodes.map.h] = "/how-to-test ",
}

-- Hammerspoon has no Bluetooth permission, so blueutil aborts under it. AirPodsConnect.app holds the grant; source in hammerspoon/airpods-connect.
local airpodsOutputUID = "34-0E-22-23-9F-BA:output"
hs.hotkey.bind(meh, "1", function()
  local dev = hs.audiodevice.findOutputByUID(airpodsOutputUID)
  if dev then
    dev:setDefaultOutputDevice()
    dev:setDefaultEffectDevice()
  else
    hs.task.new("/usr/bin/open", nil, {"-g", os.getenv("HOME") .. "/Applications/AirPodsConnect.app"}):start()
  end
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

-- Q10 or Voyager attached (cable or 2.4 GHz receiver) = desk: JKLÖ. Otherwise laptop keyboard: HJKL.
local keymapScript = os.getenv("HOME") .. "/.dotfiles/my_scripts/.script/vim-keymap-toggle.sh"
local keymapStateFile = os.getenv("HOME") .. "/.dotfiles/vim/.vim/keymap_state"

local function q10Attached()
  for _, d in ipairs(hs.usb.attachedDevices()) do
    if d.vendorID == 0x3434 and (d.productID == 0x08A1 or d.productID == 0xD030) then return true end
  end
  return false
end

-- With ~/.local/share/voyager/auto-off present the Voyager counts as absent: its key tap and the JKLÖ rule both stand down.
local function voyagerAttached()
  if hs.fs.attributes(os.getenv("HOME") .. "/.local/share/voyager/auto-off") then return false end
  for _, d in ipairs(hs.usb.attachedDevices()) do
    if d.vendorID == 0x3297 then return true end
  end
  return false
end

local function syncVimKeymap()
  local want = (q10Attached() or voyagerAttached()) and "custom" or "default"
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

local arrowHotkeys = {}
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
  table.insert(arrowHotkeys, hs.hotkey.new({"alt"}, key, press, nil, press))
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
table.insert(laptopKeys, hs.hotkey.new({"alt", "shift"}, "z", function() titleCopyRename("/generate:short-title ") end))

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

local rotateDegreesPerStep = 2.6
local rotateDeadZone = 6
local rotateAcc, rotateActive, rotateLastAt, scrollLastAt = 0, false, 0, 0

-- Shift+Option makes the key step in quarters (1.56%), and macOS shows its volume overlay for the key.
local function fineVolumeKey(name)
  for _, down in ipairs({true, false}) do
    hs.eventtap.event.newSystemKeyEvent(name, down):setFlags({shift = true, alt = true}):post()
  end
end

-- Only macOS's own rotate events count: when two fingers turn it stops sending touches and sends rotate events (field 110 is 5, field 164 holds the float32 degrees, counter-clockwise positive).
-- Two-finger scrolling and pinching can wobble the finger angle, so rotation is ignored for 0.4 s after any scroll and until a new gesture has turned past the dead zone.
rotateTap = hs.eventtap.new({hs.eventtap.event.types.gesture, hs.eventtap.event.types.scrollWheel}, function(e)
  local now = hs.timer.secondsSinceEpoch()
  if e:getType() == hs.eventtap.event.types.scrollWheel then
    scrollLastAt = now
    return false
  end
  if #(e:getTouches() or {}) > 0 or e:getProperty(110) ~= 5 then return false end
  if now - rotateLastAt > 0.3 then rotateAcc, rotateActive = 0, false end
  rotateLastAt = now
  if now - scrollLastAt < 0.4 then
    rotateAcc, rotateActive = 0, false
    return false
  end
  rotateAcc = rotateAcc + string.unpack("<f", string.pack("<I4", e:getProperty(164) & 0xFFFFFFFF))
  if not rotateActive then
    if math.abs(rotateAcc) < rotateDeadZone then return false end
    rotateActive, rotateAcc = true, 0
  end
  while math.abs(rotateAcc) >= rotateDegreesPerStep do
    fineVolumeKey(rotateAcc < 0 and "SOUND_UP" or "SOUND_DOWN")
    rotateAcc = rotateAcc + (rotateAcc < 0 and rotateDegreesPerStep or -rotateDegreesPerStep)
  end
  return false
end)

local function q10ReceiverAttached()
  for _, d in ipairs(hs.usb.attachedDevices()) do
    if d.vendorID == 0x3434 and d.productID == 0xD030 then return true end
  end
  return false
end

-- Everything the Voyager gets on the Mac lives in this tap, so no other keyboard is affected. The Voyager reports keyboard type 40,
-- as does a Q10 on its 2.4 GHz receiver, so it runs only while the Voyager is attached and that receiver is not.
-- Pause it with keyboard/voyager/mac-voyager.sh off, resume with on.
do
  local map = hs.keycodes.map
  local ouml = 41
  -- Rounded corners on the orange-to-pink gradient of the window border, with a soft shadow, like CleanShot's preset.
  local function framedImage(image)
    local size = image:size()
    local pad, radius = 64, 22
    local box = {x = pad, y = pad, w = size.w, h = size.h}
    local radii = {xRadius = radius, yRadius = radius}
    local c = hs.canvas.new({x = 0, y = 0, w = size.w + 2 * pad, h = size.h + 2 * pad})
    c:appendElements(
      {type = "rectangle", action = "fill", fillGradient = "linear", fillGradientAngle = 45,
       fillGradientColors = {{red = 1, green = 0.584, blue = 0}, {red = 1, green = 0.176, blue = 0.529}}},
      {type = "rectangle", action = "fill", frame = box, roundedRectRadii = radii, fillColor = {white = 0, alpha = 1},
       shadow = {blurRadius = 28, color = {alpha = 0.5}, offset = {h = -10, w = 0}}},
      {type = "rectangle", action = "clip", frame = box, roundedRectRadii = radii},
      {type = "image", image = image, frame = box, imageScaling = "scaleToFit"},
      {type = "resetClip"}
    )
    local framed = c:imageFromCanvas()
    c:delete()
    return framed
  end
  local function framedClipboard()
    local image = hs.pasteboard.readImage()
    return image ~= nil and hs.pasteboard.writeObjects(framedImage(image))
  end
  local function captureAreaMacshot() hs.urlevent.openURL("macshot://capture") end
  -- -o leaves out the window's own shadow, so only the frame's shadow shows.
  local function framedPickedToLund()
    local before = hs.pasteboard.changeCount()
    hs.task.new(screencapture, function()
      if hs.pasteboard.changeCount() ~= before and framedClipboard() then pasteToLund() end
    end, {"-x", "-c", "-i", "-w", "-o"}):start()
  end

  -- Hold Space + the far-left Ctrl key: Q W E R T A send Alt+Ctrl+key, read as Alt+Cmd+key. Q W E send the key the Q10's L2 number row 1, 2, 3 sends for the same screenshot action (Alt+Shift+Cmd+key), R and A are macshot's area capture, S sends the + key (key code 27, macshot history). T is W with rounded corners and a background.
  local keyToCapture = {
    [map.q] = map["7"], [map.w] = map["9"], [map.e] = map["8"], [map.r] = captureAreaMacshot, [map.t] = framedPickedToLund, [map.a] = captureAreaMacshot, [map.s] = 27,
  }
  local watched = {}
  for _, code in ipairs({map["delete"], map.f4, map.k, map.tab, map.space, map.j, map.l, map.z, ouml, map.left, map.right, map.down, map.up, map.d, 44, 27}) do watched[code] = true end
  for code in pairs(voyagerCommands) do watched[code] = true end
  for code in pairs(keyToCapture) do watched[code] = true end

  -- The firmware sends the Windows AltGr combos for these, which type | [ ] ≈ on the Mac's Swedish layout, and Lund reads Right Option as Alt.
  local altGrChar = {[map["7"]] = "{", [map["8"]] = "[", [map["9"]] = "]", [map["0"]] = "}"}
  for code in pairs(altGrChar) do watched[code] = true end

  local function exactly(f, ...)
    local want = {}
    for _, name in ipairs({...}) do want[name] = true end
    for _, name in ipairs({"cmd", "alt", "ctrl", "shift"}) do
      if (f[name] or false) ~= (want[name] or false) then return false end
    end
    return true
  end

  local function post(mods, code)
    for _, isDown in ipairs({true, false}) do hs.eventtap.event.newKeyEvent(mods, code, isDown):post() end
  end

  -- VoxFlow's hotkey is Ctrl+Shift+Space. The firmware combo Space + E sends Ctrl+E, read as Cmd+E, and it becomes that hotkey:
  -- down on press, up on release, so VoxFlow's smart hotkey toggles on a tap and does push-to-talk on a hold.
  -- The homerow D (Cmd) held with E makes the same Cmd+E, so that chord starts dictation too.
  local function postDictationKey(isDown)
    hs.eventtap.event.newKeyEvent({"ctrl", "shift"}, map.space, isDown):post()
  end
  local dictation = {run = function() postDictationKey(true) end, up = function() postDictationKey(false) end}

  local function shell(script)
    hs.task.new("/bin/sh", nil, {"-c", "export PATH=/opt/homebrew/bin:$PATH; " .. script}):start()
  end
  local function aerospace(command) shell("aerospace " .. command) end

  -- AeroSpace cannot change gaps while running, so this rewrites the wide monitor's left and right outer gap in its config and reloads it.
  -- 1920 keeps the outer quarters of the 7680-wide screen empty, 960 the outer eighths, 16 uses the full width.
  local function cycleWideGap()
    local path = os.getenv("HOME") .. "/.config/aerospace/aerospace.toml"
    local file = assert(io.open(path, "r"))
    local text = file:read("a")
    file:close()
    local steps = {1920, 960, 16}
    local current = tonumber(text:match('monitor%."Odyssey G95NC" = (%d+)'))
    local width = steps[1]
    for i, step in ipairs(steps) do if step == current then width = steps[i % #steps + 1] end end
    local out = assert(io.open(path, "w"))
    out:write((text:gsub('(monitor%."Odyssey G95NC" = )%d+', "%1" .. width)))
    out:close()
    aerospace("reload-config --no-gui")
    hs.alert.show("Wide monitor side gap " .. width, 1)
  end

  -- GlazeWM's keys from the Windows machine as AeroSpace commands: Option + key runs the first, Option+Control (A+S held) + key the second.
  -- Left out: resize mode, cycle focus, centered floating and moving a workspace between monitors (no AeroSpace match, or no Voyager key).
  local glaze = {
    [map.j] = {"focus left", "move left"}, [ouml] = {"focus right", "move right"},
    [map.l] = {"focus up", "move up"}, [map.k] = {"focus down", "move down"},
    [map.u] = {"resize width -50"}, [map.p] = {"resize width +50", "enable toggle"},
    [map.o] = {"resize height +50"}, [map.i] = {"resize height -50"},
    [map.v] = {"layout tiles horizontal vertical"}, [map.t] = {"layout tiling"}, [map.f] = {"fullscreen"},
    [map.space] = {false, "layout floating tiling"}, [map.q] = {false, "close"}, [map.r] = {false, "reload-config"},
    [map.m] = {minimizeFocused},
    [map.g] = {false, cycleWideGap},
    -- From workspace 1 go to 2, from any other go to 1.
    [map.h] = {function() shell('if [ "$(aerospace list-workspaces --focused)" = 1 ]; then aerospace workspace 2; else aerospace workspace 1; fi') end},
  }
  for i = 1, 9 do
    glaze[map[tostring(i)]] = {"workspace " .. i, "move-node-to-workspace --focus-follows-window " .. i}
  end
  for code in pairs(glaze) do watched[code] = true end

  -- Space + Esc holds RAlt+Ctrl+Shift+Win, read as Ctrl+Opt+Shift+Cmd. With a key it launches the apps the Q10's M3 launchers do.
  local appByCode = {}
  for key, app in pairs(apps) do
    appByCode[map[key]] = app
    watched[map[key]] = true
  end
  -- On the Voyager B opens Bitwarden; the Q10's B stays BetterTouchTool.
  appByCode[map.b] = "Bitwarden"
  appByCode[map.w] = function() hs.task.new("/usr/bin/open", nil, {"x-apple.systempreferences:com.apple.Wallpaper-Settings.extension"}):start() end
  watched[map.w] = true
  appByCode[map.c] = "Safari"
  watched[map.c] = true

  -- An action either replaces the key (code and flags) or runs once and swallows it.
  -- Windows Terminal moves between panes with A + Space + J K L Ö, which arrives as Alt + arrow. Lund's keys are Cmd+H J K L.
  local paneKey = {[map.left] = map.h, [map.down] = map.j, [map.up] = map.k, [map.right] = map.l}
  local function choose(code, f, rightAlt)
    local front = hs.application.frontmostApplication()
    local inLund = isLund(front)
    if inLund and paneKey[code] and exactly(f, "alt") then return {code = paneKey[code], flags = {cmd = true}} end
    if code == map["delete"] then
      -- Cmd+Backspace deletes a word and Option+Backspace deletes to the line start, the reverse of macOS.
      if exactly(f, "cmd") then
        -- Lund treats only the right Option key as Alt, so the word delete is sent as Ctrl+W there.
        if inLund then return {code = map.w, flags = {ctrl = true}} end
        return {flags = {alt = true}}
      end
      if exactly(f, "alt") then return {flags = {cmd = true}} end
      if exactly(f, "ctrl") then return {run = function() end} end
    elseif code == map.left or code == map.right then
      -- Like the Backspace pair: Cmd+arrow moves by word and Option+arrow to the line start or end, so Nav+I and Nav+O move by word and Nav+U and Nav+P go to the start and end.
      if exactly(f, "alt") then return {flags = {cmd = true}} end
      if exactly(f, "cmd") then return {flags = {alt = true}} end
      if exactly(f, "alt", "shift") then return {flags = {cmd = true, shift = true}} end
      if exactly(f, "cmd", "shift") then return {flags = {alt = true, shift = true}} end
    elseif code == map.f4 then
      -- Nav+Q sends Alt+F4, the Windows close key.
      if exactly(f, "alt") then return {code = map.q, flags = {cmd = true}} end
    elseif code == map.tab then
      -- Nav+S and Nav+D send Ctrl+Shift+Tab and Ctrl+Tab, which the Control/Command swap turns into Cmd+Tab.
      if exactly(f, "cmd") then return {flags = {ctrl = true}} end
      if exactly(f, "cmd", "shift") then return {flags = {ctrl = true, shift = true}} end
      -- Cmd+Tab is taken by the tab cycling above, so Option+Tab (hold A) switches to the previous app.
      if exactly(f, "alt") then return {run = function() post({"cmd"}, map.tab) end} end
    elseif code == map.space then
      -- Hold S (Control) + Space opens Spotlight, whose system shortcut stays Cmd+Space.
      if exactly(f, "ctrl") then return {run = function() post({"cmd"}, map.space) end} end
    end
    -- Option+Shift+Cmd+Q logs out at once, with no confirmation and no chance to save.
    if code == map.q and exactly(f, "alt", "shift", "cmd") then return {run = function() end} end
    if keyToCapture[code] and exactly(f, "alt", "cmd") then
      return {run = function()
        local capture = keyToCapture[code]
        if type(capture) == "function" then capture() else post({"alt", "shift", "cmd"}, capture) end
      end}
    end
    if (voyagerCommands[code] or code == map.z) and exactly(f, "ctrl", "alt", "cmd") then
      return {run = function()
        whenModifiersReleased(function()
          if code == map.z then titleCopyRename("/generate:short-title ") else typeCommand(voyagerCommands[code], true) end
        end)
      end}
    end
    -- The top-right key sends Ctrl+Alt+Shift+K and opens Convey Mac's keyboard cheat sheet (Cmd+Shift+§, key code 10).
    if code == map.k and exactly(f, "cmd", "alt", "shift") then
      return {run = function() post({"cmd", "shift"}, 10) end}
    end
    -- Layer 7 + 1 cycles VolumeGuard's headphone listening mode (Ctrl+Alt+Shift+§, key code 10).
    if code == map["1"] and exactly(f, "ctrl", "alt", "cmd") then
      return {run = function() post({"ctrl", "alt", "shift"}, 10) end}
    end
    -- Windows Terminal's split keys with the same presses in Lund: Alt+- splits down (key code 44, the - key) and Alt+Shift+D splits right.
    -- Lund's own keys are Option+Shift+- (code 44) and Option+Shift++ (code 27). Both are re-sent as new events, which Lund accepts where it ignores the Voyager's own left Option key.
    if inLund then
      if code == 44 and exactly(f, "alt") then return {flags = {alt = true, shift = true}} end
      if code == 27 and (exactly(f, "alt") or exactly(f, "alt", "shift")) then return {flags = {alt = true, shift = true}} end
      if code == map.d and exactly(f, "alt", "shift") then return {code = 27, flags = {alt = true, shift = true}} end
    end
    if code == map.e and exactly(f, "cmd") then return dictation end
    local app = appByCode[code]
    if app and exactly(f, "ctrl", "alt", "shift", "cmd") then
      return {run = function() if type(app) == "function" then app() else hs.application.launchOrFocus(app) end end}
    end
    if rightAlt and exactly(f, "alt") and altGrChar[code] then
      return {run = function() hs.eventtap.keyStrokes(altGrChar[code]) end}
    end
    -- The right Option key types symbols (AltGr: @ [ ] { } | \), so only the left one, the A hold, runs these.
    local entry = not rightAlt and glaze[code]
    if entry then
      local command
      if exactly(f, "alt") then command = entry[1] elseif exactly(f, "alt", "ctrl") then command = entry[2] end
      if command then return {run = type(command) == "function" and command or function() aerospace(command) end} end
    end
  end

  local pending = {}
  voyagerKeyTap = hs.eventtap.new({hs.eventtap.event.types.keyDown, hs.eventtap.event.types.keyUp}, function(e)
    local code = e:getKeyCode()
    if not watched[code] then return false end
    if e:getProperty(hs.eventtap.event.properties.keyboardEventKeyboardType) ~= 40 then return false end
    local action
    if e:getType() == hs.eventtap.event.types.keyDown then
      local ok, raw = pcall(function() return e:getRawEventData().CGEventData.flags end)
      action = choose(code, e:getFlags(), ok and raw & 0x40 ~= 0)
      pending[code] = action
      if action and action.run and e:getProperty(hs.eventtap.event.properties.keyboardEventAutorepeat) == 0 then action.run() end
    else
      action = pending[code]
      pending[code] = nil
      if action and action.up then action.up() end
    end
    if not action then return false end
    if action.run then return true end
    local copy = e:copy():setFlags(action.flags)
    if action.code then copy:setKeyCode(action.code) end
    return true, {copy}
  end)

  -- Hold A and D (Option and Cmd on the Mac) and scroll: one volume step per notch, scroll up is louder.
  -- A smooth-scrolling mouse sends several events per notch (a 0.1 line event, then bursts up to 45 times larger),
  -- so only the direction counts, and one direction steps at most once per 0.15 s.
  local scrollStepGap = 0.15
  local scrollLastStep, scrollLastSign = 0, 0
  voyagerScrollTap = hs.eventtap.new({hs.eventtap.event.types.scrollWheel}, function(e)
    if not exactly(e:getFlags(), "alt", "cmd") then return false end
    local delta = e:getProperty(hs.eventtap.event.properties.scrollWheelEventFixedPtDeltaAxis1)
    local sign = delta > 0 and 1 or delta < 0 and -1 or 0
    local now = hs.timer.secondsSinceEpoch()
    if sign ~= 0 and (sign ~= scrollLastSign or now - scrollLastStep >= scrollStepGap) then
      scrollLastStep, scrollLastSign = now, sign
      mediaKey(sign > 0 and "SOUND_UP" or "SOUND_DOWN")()
    end
    return true
  end)
end

local function syncLaptop()
  if voyagerAttached() and not q10ReceiverAttached() then
    voyagerKeyTap:start()
    voyagerScrollTap:start()
  else
    voyagerKeyTap:stop()
    voyagerScrollTap:stop()
  end
  hs.task.new(aerospaceBin, nil, {"mode", q10Attached() and "main" or "laptop"}):start()
  for _, k in ipairs(laptopKeys) do
    if q10Attached() then k:disable() else k:enable() end
  end
  for _, k in ipairs(arrowHotkeys) do
    if q10Attached() then k:disable() else k:enable() end
  end
  if q10Attached() then fnTap:stop() else fnTap:start() end
  if q10Attached() then rotateTap:stop() else rotateTap:start() end
end

keymapWatcher = hs.usb.watcher.new(function(e)
  if e.vendorID == 0x3434 or e.vendorID == 0x3297 then
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
-- Q10 M4 sends ctrl+alt; held with the volume knob it turns the knob into brightness.
local brightnessOf = {SOUND_UP = "BRIGHTNESS_UP", SOUND_DOWN = "BRIGHTNESS_DOWN"}
fineStepTap = hs.eventtap.new({hs.eventtap.event.types.systemDefined}, function(e)
  local k = e:systemKey()
  local f = e:getFlags()
  if k and brightnessOf[k.key] and f.ctrl and f.alt and not f.cmd then
    local ev = hs.eventtap.event.newSystemKeyEvent(brightnessOf[k.key], k.down)
    ev:setFlags(f.shift and {shift = true, alt = true} or {})
    ev:post()
    return true
  end
  if k and fineKeys[k.key] and f.shift and not f.alt then
    local ev = hs.eventtap.event.newSystemKeyEvent(k.key, k.down)
    ev:setFlags({shift = true, alt = true})
    ev:post()
    return true
  end
end):start()

-- Over the 2.4 GHz dongle macOS numbers the key above Tab as 50 instead of 10, and Convey Mac and VolumeGuard listen for 10.
for _, mods in ipairs({{"cmd", "shift"}, meh}) do
  hs.hotkey.bind(mods, 50, function()
    hs.eventtap.event.newKeyEvent(mods, 10, true):post()
    hs.eventtap.event.newKeyEvent(mods, 10, false):post()
  end)
end

-- Safari ignores the mouse's Back and Forward buttons (buttons 3 and 4), so run its History menu items instead.
local safariHistoryItem = {[3] = "Back", [4] = "Forward"}
safariMouseTap = hs.eventtap.new({hs.eventtap.event.types.otherMouseDown, hs.eventtap.event.types.otherMouseUp}, function(e)
  local item = safariHistoryItem[e:getProperty(hs.eventtap.event.properties.mouseEventButtonNumber)]
  local app = hs.application.frontmostApplication()
  if not item or app:bundleID() ~= "com.apple.Safari" then return false end
  if e:getType() == hs.eventtap.event.types.otherMouseDown then app:selectMenuItem({"History", item}) end
  return true
end):start()

hs.alert.show("Hammerspoon config loaded")
