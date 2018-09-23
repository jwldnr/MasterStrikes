-- locals and speed
local AddonName, Addon = ...

local _G = _G

local TEXTURE_OFFSET = 12
local BUTTON_TYPE_SPELL = "spell"
local BUTTON_TYPE_MACRO = "macro"

local COLOR_RED = { 1, .1, .1 }
local COLOR_WHITE = { 1, 1, 1 }

local SPEC_MISTWEAVER = "Mistweaver"
local SPEC_WINDWALKER = "Windwalker"

local SPELL_IDS_MISTWEAVER = {
  [124682] = true, -- enveloping mist
  [116670] = true  -- vivify
}

local SPELL_IDS_WINDWALKER = {
  [100780] = true, -- tiger palm
  [100784] = true, -- blackout kick
  [107428] = true, -- rising sun kick
  [113656] = true, -- fists of fury
  [101546] = true, -- spinning crane kick
  [261947] = true, -- fist of the white tiger
  [123986] = true, -- chi burst
  [152175] = true, -- whirling dragon punch
  [115098] = true  -- chi wave
}

local SPELL_IDS = {
  [SPEC_MISTWEAVER] = SPELL_IDS_MISTWEAVER,
  [SPEC_WINDWALKER] = SPELL_IDS_WINDWALKER
}

-- main
function Addon:Load()
  self.frame = CreateFrame("Frame", nil)

  -- set OnEvent handler
  self.frame:SetScript("OnEvent", function(handler, ...)
    self:OnEvent(...)
  end)

  self.frame:RegisterEvent("PLAYER_LOGIN")
  self.frame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
  self.frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
end

-- frame events
function Addon:OnEvent(event, ...)
  local action = self[event]

  if (action) then
    action(self, ...)
  end
end

function Addon:PLAYER_LOGIN()
  self.frame:UnregisterEvent("PLAYER_LOGIN")

  self:HookActionEvents()
  self:AddButtonFlash()

  self.lastSpellId = nil
  self.buttons = {}

  self:SetSpecialization()
end

function Addon:SetSpecialization()
  self.spells = {}

  local spec = GetSpecialization()
  local name = spec and select(2, GetSpecializationInfo(spec)) or nil

  if (not name) then
    return
  end

  if (SPEC_MISTWEAVER == name) then
    self.spells = SPELL_IDS[SPEC_MISTWEAVER]

    print("Specialization set to " .. SPEC_MISTWEAVER)
  end

  if (SPEC_WINDWALKER == name) then
    self.spells = SPELL_IDS[SPEC_MISTWEAVER]

    print("Specialization set to " .. SPEC_WINDWALKER)
  end
end

function Addon:PLAYER_SPECIALIZATION_CHANGED()
  self:SetSpecialization()
end

function Addon:UNIT_SPELLCAST_SUCCEEDED(unit, lineId, spellId)
  if (nil == self.spells[spellId]) then
    return
  end

  local button = self.buttons[spellId]

  if (button) then
    self:ColorOverlay(spellId)
    self:ShowOverlay(button)
  end
end

function Addon:AddButtonFlash()
  local overlay = CreateFrame("Frame", nil)
  overlay:SetFrameStrata("TOOLTIP")

  local texture = overlay:CreateTexture()
  texture:SetTexture([[Interface\Cooldown\starburst]])
  -- texture:SetTexture([[Interface\SpellActivationOverlay\IconAlert]])
  -- texture:SetTexCoord(0.00781250, 0.50781250, 0.53515625, 0.78515625)
  texture:SetAlpha(0)
  texture:SetAllPoints(overlay)
  texture:SetBlendMode("ADD")
  texture:SetDrawLayer("OVERLAY", 7)

  overlay.texture = texture

  local animation = texture:CreateAnimationGroup()
  animation:SetLooping("REPEAT")
  
  overlay.animation = animation

  local alpha1 = animation:CreateAnimation("Alpha")
  alpha1:SetFromAlpha(0)
  alpha1:SetToAlpha(1)
  alpha1:SetDuration(.3)
  alpha1:SetOrder(1)
  alpha1:SetSmoothing("IN")

  local rotation = animation:CreateAnimation("Rotation")
  rotation:SetDegrees(12)
  rotation:SetDuration(.9)
  rotation:SetOrder(1)

  local alpha2 = animation:CreateAnimation("Alpha")
  alpha2:SetFromAlpha(1)
  alpha2:SetToAlpha(0)
  alpha2:SetStartDelay(.6)
  alpha2:SetDuration(.3)
  alpha2:SetOrder(1)
  alpha2:SetSmoothing("OUT")

  self.overlay = overlay
end

-- hooks
do
  local function Button_ActionButtonDown(id)
    Addon:ActionButtonDown(id)
  end

  local function Button_MultiActionButtonDown(bar, id)
    Addon:MultiActionButtonDown(bar, id)
  end

  function Addon:HookActionEvents()
    hooksecurefunc("ActionButtonDown", Button_ActionButtonDown)
    hooksecurefunc("MultiActionButtonDown", Button_MultiActionButtonDown)
  end
end

function Addon:ActionButtonDown(id)
  local button = _G.GetActionButtonForID(id)

  if (button) then
    self:AddButton(button)
  end
end

function Addon:MultiActionButtonDown(bar, id)
  local button = _G[bar.."Button"..id]
  
  if (button) then
    self:AddButton(button)
  end
end

function Addon:AddButton(button)
  local type, id = _G.GetActionInfo(button.action)

  if (type == BUTTON_TYPE_SPELL and id) then
    self.buttons[id] = button
  elseif (type == BUTTON_TYPE_MACRO) then
    local m_id = _G.GetMacroSpell(id)

    if (m_id) then
      self.buttons[m_id] = button
    end
  end
end

function Addon:GetOverlayColor(spellId)
  return self.lastSpellId == spellId and COLOR_RED or COLOR_WHITE
end

function Addon:ColorOverlay(spellId)
  local color = self:GetOverlayColor(spellId)
  self.overlay.texture:SetVertexColor(unpack(color))

  self.lastSpellId = spellId
end

function Addon:ShowOverlay(anchor)
  self.overlay:SetPoint("TOPLEFT", anchor, "TOPLEFT", -TEXTURE_OFFSET, TEXTURE_OFFSET)
  self.overlay:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", TEXTURE_OFFSET, -TEXTURE_OFFSET)

  self.overlay.animation:Stop()
  self.overlay.animation:Play()
end

-- call
Addon:Load()
