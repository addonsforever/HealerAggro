-- Healer Aggro: who the healers are and whether a monster is attacking one of them.
-- UnitThreatSituation with one unit token is not secret in Forever (SecretWhenUnitThreatStateRestricted
-- only hides two-token queries), but every value is still checked with issecretvalue.
local _, ns = ...

-- UnitThreatSituation: 2 = a monster's current target (another unit has more threat),
-- 3 = its current target with the most threat. Either way it is hitting them.
local ATTACKED = 2

local function secret(v) return issecretvalue ~= nil and issecretvalue(v) end
-- True only for a readable true value; a secret can't be tested, so it counts as no.
local function yes(v) return v ~= nil and not secret(v) and v == true end

-- "player", then party1-4 or raid1-40.
function ns.GroupUnits()
  local units = {}
  if IsInRaid() then
    for i = 1, GetNumGroupMembers() do units[#units + 1] = "raid" .. i end
  else
    units[1] = "player"
    for i = 1, GetNumSubgroupMembers() do units[#units + 1] = "party" .. i end
  end
  return units
end

-- Name without the realm, or nil if the game hides it.
function ns.UnitShortName(unit)
  local name = UnitName(unit)
  if name == nil or secret(name) then return nil end
  return name
end

-- A healer is anyone in the Healer role, or anyone marked with /healeraggro mark.
function ns.IsHealer(unit)
  local role = UnitGroupRolesAssigned and UnitGroupRolesAssigned(unit)
  if role ~= nil and not secret(role) and role == "HEALER" then return true end
  local name = ns.UnitShortName(unit)
  return name ~= nil and HealerAggroDB.marked[name] == true
end

-- How many visible enemy nameplates are attacking unit (0 if none are visible or the game hides it).
-- One ally token plus a nameplate token is not secret in Forever, but it's checked anyway.
function ns.CountAttackers(unit)
  local n = 0
  for i = 1, 40 do
    local plate = "nameplate" .. i
    if yes(UnitExists(plate)) and yes(UnitCanAttack("player", plate)) then
      local status = UnitThreatSituation(unit, plate)
      if status ~= nil and not secret(status) and status >= ATTACKED then n = n + 1 end
    end
  end
  return n
end

-- Returns the healers a monster is attacking ({ unit, name } each), how many healers were checked,
-- and "hidden" if the game hid threat for any of them.
function ns.Scan()
  local attacked, healers, hidden = {}, 0, nil
  for _, unit in ipairs(ns.GroupUnits()) do
    if UnitExists(unit) and ns.IsHealer(unit) then
      healers = healers + 1
      local status = UnitThreatSituation(unit)
      if status ~= nil and secret(status) then
        hidden = "hidden"
      elseif status ~= nil and status >= ATTACKED and not UnitIsDeadOrGhost(unit) then
        attacked[#attacked + 1] = { unit = unit, name = ns.UnitShortName(unit) or "Healer" }
      end
    end
  end
  return attacked, healers, hidden
end

-- Watch inside dungeons and raids, or anywhere in a group with /healeraggro anywhere.
function ns.ShouldWatch()
  if not IsInGroup() then return false end
  if HealerAggroDB.anywhere then return true end
  local inInstance, kind = IsInInstance()
  return inInstance == true and (kind == "party" or kind == "raid")
end
