--[[
	In WoW 4.3 and later, action buttons can completely bypass lua for updating cooldown timers
	This set of code is there to check and force tullaCC to update timers on standard action buttons (henceforth defined as anything that reuses's blizzard's ActionButton.lua code
--]]

local ActionBarButtonEventsFrame = _G['ActionBarButtonEventsFrame']
if not ActionBarButtonEventsFrame then return end

local AddonName, Addon = ...
local Timer = Addon.Timer


--[[ cooldown timer updating ]]--

local active = {}

local function cooldown_OnShow(self)
	active[self] = true
end

local function cooldown_OnHide(self)
	active[self] = nil
end

--returns true if the cooldown timer should be updated and false otherwise
local function cooldown_ShouldUpdateTimer(self, start, duration, charges, maxCharges)
	local timer = self.timer
	if not timer then
		return true
	end
	return not(timer.start == start or timer.charges == charges or timer.maxCharges == maxCharges)
end

local function cooldown_Update(self)
	local button = self:GetParent()
	local action = button.action
	
	local start, duration, enable = GetActionCooldown(action)
	local charges, maxCharges, chargeStart, chargeDuration = GetActionCharges(action)
	
	if cooldown_ShouldUpdateTimer(self, start, duration, charges, maxCharges) then
		Timer.Start(self, start, duration, charges, maxCharges)
	end
end

local abEventWatcher = CreateFrame('Frame'); abEventWatcher:Hide()
abEventWatcher:SetScript('OnEvent', function(self, event)
	for cooldown in pairs(active) do
		cooldown_Update(cooldown)
	end
end)
abEventWatcher:RegisterEvent('ACTIONBAR_UPDATE_COOLDOWN')


--[[ hook action button registration ]]--

local hooked = {}

local function actionButton_Register(frame)
	local cooldown = frame.cooldown
	if not hooked[cooldown] then
		cooldown:HookScript('OnShow', cooldown_OnShow)
		cooldown:HookScript('OnHide', cooldown_OnHide)
		hooked[cooldown] = true
	end
end

if ActionBarButtonEventsFrame.frames then
	for i, frame in pairs(ActionBarButtonEventsFrame.frames) do
		actionButton_Register(frame)
	end
end
hooksecurefunc('ActionBarButtonEventsFrame_RegisterFrame', actionButton_Register)