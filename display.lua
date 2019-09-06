-- A cooldown text display
local _, Addon = ...

-- the expected size of an icon
local ICON_SIZE = 36
local After = C_Timer.After
local GetTickTime = GetTickTime
local min = math.min
local round = Round
local UIParent = UIParent

local displays = {}

local Display = CreateFrame("Frame")

Display:Hide()
Display.__index = Display

function Display:Get(owner)
    return displays[owner]
end

function Display:GetOrCreate(owner)
    if not owner then return end

    return displays[owner] or self:Create(owner)
end

function Display:Create(owner)
    local display = setmetatable(CreateFrame("Frame", nil, owner), Display)

    display:Hide()
    display:SetScript("OnSizeChanged", self.OnSizeChanged)
    display.text = display:CreateFontString(nil, "OVERLAY")
    display.text:SetFont(STANDARD_TEXT_FONT, 8, "THIN")

    display.cooldowns = {}
    display.updateScaleCallback = function() display:OnScaleChanged() end
    display:UpdateCooldownTextShadow()

    displays[owner] = display
    return display
end

-- adjust font size whenever the timer's size changes
-- and hide if it gets too tiny
function Display:OnSizeChanged()
    local oldSize = self.sizeRatio

    if oldSize ~= self:CalculateSizeRatio() then
        self:UpdateCooldownTextShown()

        self:UpdateCooldownTextFont()
        self:UpdateCooldownTextPosition()
    end
end

-- adjust font size whenever the timer's size changes
-- and hide if it gets too tiny
function Display:OnScaleChanged()
    local oldScale = self.scaleRatio

    if oldScale ~= self:CalculateScaleRatio() then
        self:UpdateCooldownTextShown()
    end
end

-- update text when the timer notifies us of a change
function Display:OnTimerTextUpdated(timer, text)
    if timer ~= self.timer then return end

    self.text:SetText(text or "")
end

function Display:OnTimerStateUpdated(timer, state)
    if timer ~= self.timer then return end

    state = state or "seconds"
    if self.state ~= state then
        self.state = state
        self:UpdateCooldownTextFont()
    end
end

function Display:OnTimerDestroyed(timer)
    if self.timer == timer then
        self:RemoveCooldown(self.activeCooldown)
    end
end

function Display:CalculateSizeRatio()
    local sizeRatio
    if Addon.Config.scaleText then
        sizeRatio = round(min(self:GetSize())) / ICON_SIZE
    else
        sizeRatio = 1
    end

    self.sizeRatio = sizeRatio

    return sizeRatio
end

function Display:CalculateScaleRatio()
    local scaleRatio = self:GetEffectiveScale() / UIParent:GetEffectiveScale()

    self.scaleRatio = scaleRatio

    return scaleRatio
end

function Display:AddCooldown(cooldown)
    local cooldowns = self.cooldowns
    if not cooldowns[cooldown] then
        cooldowns[cooldown] = true
    end

    self:UpdatePrimaryCooldown()
    self:UpdateTimer()
end

function Display:RemoveCooldown(cooldown)
    local cooldowns = self.cooldowns
    if cooldowns[cooldown] then
        cooldowns[cooldown] = nil

        self:UpdatePrimaryCooldown()
        self:UpdateTimer()
    end
end

function Display:UpdatePrimaryCooldown()
    local cooldown = self:GetCooldownWithHighestPriority()

    if self.activeCooldown ~= cooldown then
        if cooldown then
            self.activeCooldown = cooldown
            self:SetAllPoints(cooldown)
            self:SetFrameLevel(cooldown:GetFrameLevel() + 7)
        else
            self.activeCooldown = nil
        end
    end
end

function Display:UpdateTimer()
    local oldTimer = self.timer
    local oldTimerKey = oldTimer and oldTimer.key

    local newTimer = self.activeCooldown and Addon.Timer:GetOrCreate(self.activeCooldown)
    local newTimerKey = newTimer and newTimer.key

    -- update subscription if we're watching a different timer
    if oldTimer ~= newTimer then
        if oldTimer then
            oldTimer:Unsubscribe(self)
        end

        self.timer = newTimer
    end

    -- only show display if we have a timer to watch
    if newTimer then
        newTimer:Subscribe(self)

        -- only update text if the timer we're watching has changed
        if newTimerKey ~= oldTimerKey then
            self:OnTimerTextUpdated(newTimer, newTimer.text)
            self:OnTimerStateUpdated(newTimer, newTimer.state)
            self:Show()
        end

        -- SUF hack to update scale of frames after cooldowns are set
        After(GetTickTime(), self.updateScaleCallback)
    else
        self:Hide()
    end
end

do
    -- given two cooldowns, returns the more important one
    local function cooldown_Compare(lhs, rhs)
        if lhs == rhs then
            return lhs
        end

        -- prefer the one that isn't nil
        if rhs == nil then
            return lhs
        end

        if lhs == nil then
            return rhs
        end

        -- prefer cooldowns ending first
        local lEnd = lhs._tcc_start + lhs._tcc_duration
        local rEnd = rhs._tcc_start + rhs._tcc_duration

        if lEnd < rEnd then
            return lhs
        end

        if lEnd > rEnd then
            return rhs
        end

        -- then check priority
        if lhs._tcc_priority < rhs._tcc_priority then
            return lhs
        end

        return rhs
    end

    function Display:GetCooldownWithHighestPriority()
        local result

        for cooldown in pairs(self.cooldowns) do
            result = cooldown_Compare(cooldown, result)
        end

        return result
    end
end


function Display:UpdateCooldownTextShown()
    local sizeRatio = self.sizeRatio or self:CalculateSizeRatio()
    local scaleRatio = self.scaleRatio or self:CalculateScaleRatio()

    if (sizeRatio * scaleRatio) >= (Addon.Config.minScale or 0) then
        self.text:Show()
    else
        self.text:Hide()
    end
end

function Display:UpdateCooldownTextFont()
    local sets = Addon.Config
    local style = sets.styles[self.state or "seconds"]

    local fontSize = sets.fontSize * style.scale * (self.sizeRatio or self:CalculateSizeRatio())
    if self.fontSize == fontSize then
        return
    end

    self.fontSize = fontSize

    if fontSize > 0 then
        local text = self.text

        if not text:SetFont(sets.fontFace, fontSize, sets.fontOutline) then
            text:SetFont(STANDARD_TEXT_FONT, fontSize, sets.fontOutline)
        end

        text:SetTextColor(style.r, style.g, style.b, style.a)
    end
end

function Display:UpdateCooldownTextShadow()
    local fontShadow = Addon.Config.fontShadow
    local text = self.text

    text:SetShadowColor(fontShadow.r, fontShadow.g, fontShadow.b, fontShadow.a)
    text:SetShadowOffset(fontShadow.x, fontShadow.y)
end

function Display:UpdateCooldownTextPosition()
    local sets = Addon.Config
    local sizeRatio = self.sizeRatio or self:CalculateSizeRatio()

    self.text:ClearAllPoints()
    self.text:SetPoint(sets.anchor, sets.xOff * sizeRatio, sets.yOff * sizeRatio)
end

-- exports
Addon.Display = Display
