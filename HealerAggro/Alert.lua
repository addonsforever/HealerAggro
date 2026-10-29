-- Healer Aggro: the warning. A thin, softly pulsing red border round the screen plus a line of
-- text naming the healer. It never takes mouse clicks, so it can't get in the way of playing.
local _, ns = ...

local Alert = {}
ns.Alert = Alert

local EDGE = 5    -- border thickness
local PULSE = 1.4 -- seconds per pulse

local function Create()
  local f = CreateFrame("Frame", "HealerAggroAlert", UIParent)
  f:SetAllPoints(UIParent)
  f:SetFrameStrata("HIGH")
  f:EnableMouse(false)
  f:Hide()

  local function edge(a, b, w, h)
    local t = f:CreateTexture(nil, "OVERLAY")
    t:SetColorTexture(1, 0.15, 0.15, 0.6)
    t:SetPoint(a)
    t:SetPoint(b)
    if w then t:SetWidth(w) else t:SetHeight(h) end
  end
  edge("TOPLEFT", "TOPRIGHT", nil, EDGE)
  edge("BOTTOMLEFT", "BOTTOMRIGHT", nil, EDGE)
  edge("TOPLEFT", "BOTTOMLEFT", EDGE)
  edge("TOPRIGHT", "BOTTOMRIGHT", EDGE)

  f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  f.title:SetPoint("TOP", 0, -180)
  f.title:SetTextColor(1, 0.35, 0.35)
  f.title:SetText("Healer aggro")
  f.names = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  f.names:SetPoint("TOP", f.title, "BOTTOM", 0, -4)

  f.elapsed = 0
  f:SetScript("OnUpdate", function(self, dt)
    self.elapsed = self.elapsed + dt
    local phase = (self.elapsed % PULSE) / PULSE
    self:SetAlpha(0.6 + 0.4 * math.abs(1 - 2 * phase))
  end)
  return f
end

-- names: the attacked healers, or an empty list to clear. Clears the moment nobody is attacked.
function Alert.Set(names)
  Alert.frame = Alert.frame or Create()
  local f = Alert.frame
  if #names > 0 then
    f.names:SetText(table.concat(names, ", "))
    if not f:IsShown() then
      f.elapsed = 0
      f:Show()
      if HealerAggroDB.sound and PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.RAID_WARNING, "Master") end
    end
  else
    f:Hide()
  end
end

function Alert.IsShown() return Alert.frame ~= nil and Alert.frame:IsShown() end
