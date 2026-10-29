-- Healer Aggro: events, the check loop and the /healeraggro command.
local ADDON, ns = ...

local CHECK_EVERY = 0.2 -- seconds; events cover most changes, this catches the rest
local TEST_FOR = 3
local SAY_COOLDOWN = 10 -- seconds between /say announcements, so a target flipping back and forth can't spam

local function say(msg) print("|cffff6060Healer Aggro:|r " .. msg) end

-- Errors never become Lua popups: each distinct message is printed once.
local reported = {}
local function Safe(fn, ...)
  local ok, err = pcall(fn, ...)
  if not ok and not reported[tostring(err)] then
    reported[tostring(err)] = true
    say(tostring(err))
  end
end

local testUntil = 0
local toldHidden, toldChatLocked = false, false
local lastSaid = -math.huge
local wasAttacked = {} -- unit -> true while a monster was attacking them at the last check

-- "/say Aggro on healer Holyjoe (2 mobs)!" when a healer newly gets aggro, if /healeraggro say is on.
-- Only inside instances: outside them the game blocks addons from using /say.
local function Announce(attacked)
  local now = {}
  local fresh
  for _, a in ipairs(attacked) do
    now[a.unit] = true
    if not wasAttacked[a.unit] and not fresh then fresh = a end
  end
  wasAttacked = now
  if not fresh or not HealerAggroDB.say or GetTime() - lastSaid < SAY_COOLDOWN then return end
  if not IsInInstance() then return end
  if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then
    if not toldChatLocked then
      toldChatLocked = true
      say("the game blocks addon chat here, so I can't /say the warning.")
    end
    return
  end
  local mobs = ns.CountAttackers(fresh.unit)
  local count = mobs > 0 and (" (%d mob%s)"):format(mobs, mobs == 1 and "" or "s") or ""
  local who = fresh.name == ns.UnitShortName("player") and "Aggro on me" or ("Aggro on healer " .. fresh.name)
  -- Newer clients have C_ChatInfo.SendChatMessage; the global may only be a deprecated alias.
  local send = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
  send(who .. count .. "!", "SAY")
  lastSaid = GetTime()
end

function ns.Update()
  if GetTime() < testUntil then
    ns.Alert.Set({ (ns.UnitShortName("player") or "Test") .. " (test)" })
    return
  end
  if not ns.ShouldWatch() then
    wasAttacked = {}
    ns.Alert.Set({})
    return
  end
  local attacked, _, hidden = ns.Scan()
  if hidden and not toldHidden then
    toldHidden = true
    say("the game is hiding threat here, so warnings can't work.")
  end
  local names = {}
  for i, a in ipairs(attacked) do names[i] = a.name end
  ns.Alert.Set(names)
  Announce(attacked)
end

local function Defaults()
  HealerAggroDB = HealerAggroDB or {}
  HealerAggroDB.marked = HealerAggroDB.marked or {}
  if HealerAggroDB.sound == nil then HealerAggroDB.sound = false end
  if HealerAggroDB.anywhere == nil then HealerAggroDB.anywhere = false end
  if HealerAggroDB.say == nil then HealerAggroDB.say = false end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE", "PLAYER_ROLES_ASSIGNED",
  "UNIT_THREAT_SITUATION_UPDATE", "UNIT_THREAT_LIST_UPDATE", "PLAYER_REGEN_ENABLED" }) do
  frame:RegisterEvent(e)
end
frame:SetScript("OnEvent", function(_, event, arg)
  Safe(function()
    if event == "ADDON_LOADED" then
      if arg == ADDON then Defaults() end
      return
    end
    if not HealerAggroDB then return end
    -- A new zone gets the one-time notice again.
    if event == "PLAYER_ENTERING_WORLD" then toldHidden, toldChatLocked = false, false end
    ns.Update()
  end)
end)
local sinceCheck = 0
frame:SetScript("OnUpdate", function(_, dt)
  sinceCheck = sinceCheck + dt
  if sinceCheck < CHECK_EVERY or not HealerAggroDB then return end
  sinceCheck = 0
  Safe(ns.Update)
end)

local function onOff(v) return v and "on" or "off" end

local function Command(msg)
  local cmd = (msg or ""):lower():match("^%s*(%S*)")
  if cmd == "test" then
    testUntil = GetTime() + TEST_FOR
    ns.Update()
  elseif cmd == "mark" then
    local name = UnitIsPlayer("target") and ns.UnitShortName("target")
    if not name then return say("target a player first.") end
    HealerAggroDB.marked[name] = not HealerAggroDB.marked[name] or nil
    say(name .. (HealerAggroDB.marked[name] and " is marked as a healer." or " is no longer marked as a healer."))
  elseif cmd == "anywhere" then
    HealerAggroDB.anywhere = not HealerAggroDB.anywhere
    say(HealerAggroDB.anywhere and "warning anywhere in a group." or "warning only in dungeons and raids.")
  elseif cmd == "say" then
    HealerAggroDB.say = not HealerAggroDB.say
    say("/say announcements " .. onOff(HealerAggroDB.say) .. " (dungeons and raids only).")
  elseif cmd == "sound" then
    HealerAggroDB.sound = not HealerAggroDB.sound
    say("sound " .. onOff(HealerAggroDB.sound) .. ".")
  else
    local marked = {}
    for name in pairs(HealerAggroDB.marked) do marked[#marked + 1] = name end
    table.sort(marked)
    say("warns when a monster attacks a healer (Healer role, or marked).")
    say(("marked: %s. Sound %s. /say %s. %s."):format(#marked > 0 and table.concat(marked, ", ") or "nobody",
      onOff(HealerAggroDB.sound), onOff(HealerAggroDB.say), HealerAggroDB.anywhere and "Anywhere in a group" or "Dungeons and raids only"))
    say("/healeraggro test | mark (your target) | anywhere | sound | say")
  end
end
SLASH_HEALERAGGRO1, SLASH_HEALERAGGRO2 = "/healeraggro", "/hagro"
SlashCmdList.HEALERAGGRO = function(msg) Safe(Command, msg) end
