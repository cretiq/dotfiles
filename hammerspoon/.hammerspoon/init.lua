require("hs.ipc")

-- Q10 right space (L3) sends meh (ctrl+shift+alt); left space belongs to aerospace
local meh = {"ctrl", "shift", "alt"}

local apps = {
  q = "Obsidian",
  f = "Finder",
  a = "Spotify",
  h = "Claude",
  c = "Microsoft Edge",
  z = "Bitwarden",
  j = "ChatGPT",
  e = "X Pro",
  x = "Xcode",
  b = "BetterTouchTool",
  s = "Simulator",
}
for key, app in pairs(apps) do
  hs.hotkey.bind(meh, key, function() hs.application.launchOrFocus(app) end)
end

hs.hotkey.bind({}, "f1", function()
  local win = hs.window.focusedWindow()
  if win then win:minimize() end
end)

hs.hotkey.bind({}, "f2", hs.spaces.toggleMissionControl)

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

hs.hotkey.bind(meh, "n", function()
  typeSlowly("/next ", 0.003, function()
    hs.timer.doAfter(0.03, function() hs.eventtap.keyStroke({}, "return", 10000) end)
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

-- Over the 2.4 GHz dongle macOS numbers the key above Tab as 50 instead of 10, and Convey listens for 10.
hs.hotkey.bind({"cmd", "shift"}, 50, function()
  hs.eventtap.event.newKeyEvent({"cmd", "shift"}, 10, true):post()
  hs.eventtap.event.newKeyEvent({"cmd", "shift"}, 10, false):post()
end)

hs.alert.show("Hammerspoon config loaded")
