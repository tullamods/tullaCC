-- hooks for watching cooldown events
local _, Addon = ...

local GCD_SPELL_ID = 61304
local COOLDOWN_TYPE_LOSS_OF_CONTROL = COOLDOWN_TYPE_LOSS_OF_CONTROL
local GetSpellCooldown = GetSpellCooldown
local GetTime = GetTime
local cooldowns = {}

local Cooldown = {}

-- queries
function Cooldown:CanShow()
    local start, duration = self._tcc_start, self._tcc_duration

    -- no active cooldown
    if start <= 0 or duration <= 0 then
        return false
    end

    -- text enabled
    local sets = self._tcc_settings
    if not sets then
        return false
    end

    -- at least min duration
    if duration < sets.minDuration then
        return false
    end

    local t = GetTime()

    -- expired cooldowns
    if (start + duration) <= t then
        return false
    end

    -- future cooldowns that don't start for at least a day
    -- these are probably buggy ones
    if (start - t) > 86400 then
        return false
    end

    -- filter GCD
    local gcdStart, gcdDuration = GetSpellCooldown(GCD_SPELL_ID)
    if start == gcdStart and duration == gcdDuration then
        return false
    end

    return true
end

function Cooldown:GetKind()
    if self.currentCooldownType == COOLDOWN_TYPE_LOSS_OF_CONTROL then
        return "loc"
    end

    local parent = self:GetParent()
    if parent and parent.chargeCooldown == self then
        return "charge"
    end

    return "default"
end

function Cooldown:GetPriority()
    if self._tcc_kind ==  "charge" then
        return 2
    end

    return 1
end

-- actions
function Cooldown:Initialize()
    if cooldowns[self] then return end
    cooldowns[self] = true

    self._tcc_start = 0
    self._tcc_duration = 0
    self._tcc_settings = Addon.Config

    self:HookScript("OnShow", Cooldown.OnVisibilityUpdated)
    self:HookScript("OnHide", Cooldown.OnVisibilityUpdated)
end

function Cooldown:ShowText()
    local oldDisplay = self._tcc_display
    local newDisplay = Addon.Display:GetOrCreate(self:GetParent() or self)

    if oldDisplay ~= newDisplay then
        self._tcc_display = newDisplay

        if oldDisplay then
            oldDisplay:RemoveCooldown(self)
        end
    end

    if newDisplay then
        newDisplay:AddCooldown(self)
    end
end

function Cooldown:HideText()
    local display = self._tcc_display

    if display then
        display:RemoveCooldown(self)
        self._tcc_display  = nil
    end
end

function Cooldown:UpdateText()
    if self._tcc_show and self:IsVisible() then
        Cooldown.ShowText(self)
    else
        Cooldown.HideText(self)
    end
end

do
    local pending = {}

    local updater = CreateFrame('Frame')

    updater:Hide()

    updater:SetScript("OnUpdate", function(self)
        for cooldown in pairs(pending) do
            Cooldown.UpdateText(cooldown)
            pending[cooldown] = nil
        end

        self:Hide()
    end)

    function Cooldown:RequestUpdateText()
        if not pending[self] then
            pending[self] = true
            updater:Show()
        end
    end
end

function Cooldown:Refresh(force)
    local start, duration = self:GetCooldownTimes()

    start = (start or 0) / 1000
    duration = (duration or 0) / 1000

    if force then
        self._tcc_start = nil
        self._tcc_duration = nil
    end

    Cooldown.Initialize(self)
    Cooldown.SetTimer(self, start, duration)
end

function Cooldown:SetTimer(start, duration)
    if self._tcc_start == start and self._tcc_duration == duration then
        return
    end

    self._tcc_start = start
    self._tcc_duration = duration
    self._tcc_kind = Cooldown.GetKind(self)
    self._tcc_show = Cooldown.CanShow(self)
    self._tcc_priority = Cooldown.GetPriority(self)

    Cooldown.RequestUpdateText(self)
end

function Cooldown:SetNoCooldownCount(disable, owner)
    owner = owner or true

    if disable then
        if not self.noCooldownCount then
            self.noCooldownCount = owner
            Cooldown.HideText(self)
        end
    elseif self.noCooldownCount == owner then
        self.noCooldownCount = nil
        Cooldown.Refresh(self, true)
    end
end

-- events
function Cooldown:OnSetCooldown(start, duration)
    if self.noCooldownCount or self:IsForbidden() then return end

    start = start or 0
    duration = duration or 0

    Cooldown.Initialize(self)
    Cooldown.SetTimer(self, start, duration)
end

function Cooldown:OnSetCooldownDuration()
    if self.noCooldownCount or self:IsForbidden() then return end

    Cooldown.Refresh(self)
end

function Cooldown:SetDisplayAsPercentage()
    if self.noCooldownCount or self:IsForbidden() then return end

    Cooldown.SetNoCooldownCount(self, true)
end

function Cooldown:OnVisibilityUpdated()
    if self.noCooldownCount or self:IsForbidden() then return end

    Cooldown.RequestUpdateText(self)
end

-- misc
function Cooldown:SetupHooks()
    local cooldown_mt = getmetatable(ActionButton1Cooldown).__index

    hooksecurefunc(cooldown_mt, "SetCooldown", Cooldown.OnSetCooldown)
    hooksecurefunc(cooldown_mt, "SetCooldownDuration", Cooldown.OnSetCooldownDuration)
    hooksecurefunc("CooldownFrame_SetDisplayAsPercentage", Cooldown.SetDisplayAsPercentage)
end

-- exports
Addon.Cooldown = Cooldown