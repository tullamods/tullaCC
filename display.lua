--[[ A cooldown text display ]]--

local AddonName, Addon = ...
local C = Addon.Config
local ICON_SIZE = math.ceil(_G.ActionButton1:GetWidth()) -- the expected size of an icon

local Timer = Addon.Timer
local Display = CreateFrame('Frame'); Display:Hide()
local Display_mt = { __index = Display }
local floor = math.floor
local displays = {}

function Display:Get(cooldown)
	return displays[cooldown]
end

function Display:Create(cooldown)
	-- skin cooldown on display creation
	cooldown:SetDrawBling(C.drawBling)
	cooldown:SetDrawSwipe(C.drawSwipe)
	cooldown:SetDrawEdge(C.drawEdge)
	cooldown:SetHideCountdownNumbers(true)

	local display = setmetatable(CreateFrame('Frame', nil, cooldown), Display_mt)

	display:SetAllPoints(cooldown)
	display:SetScript('OnSizeChanged', self.OnSizeChanged)
	display:Hide()

	local text = display:CreateFontString(nil, 'OVERLAY')
	text:SetPoint('CENTER', 0, 0)
	text:SetFont(C.fontFace, C.fontSize, 'OUTLINE')
	display.text = text

	displays[cooldown] = display
	return display
end

-- update text when the timer notifies us of a change
function Display:OnTimerUpdated(timer)
	if self.timer == timer and self.text:IsShown() then
		self.text:SetText(timer.text or '')
	end
end

-- hide the display when its parent timer is destroyed
function Display:OnTimerDestroyed(timer)
	if self.timer == timer then
		self.timer = nil
		self.text:SetText('')
		self:Hide()
	end
end

-- adjust font size whenever the timer's size changes
-- and hide if it gets too tiny
function Display:OnSizeChanged(width, height)
	local scale = floor(width + 0.5) / ICON_SIZE

	if scale ~= self.scale then
		self.scale = scale

		local text = self.text

		if scale >= C.minScale then
			text:Show()
			text:SetFont(C.fontFace, scale * C.fontSize, 'OUTLINE')
			text:SetShadowColor(0, 0, 0, 0.8)
			text:SetShadowOffset(1, -1)
			text:SetText(self.timer and self.timer.text or '')
		else
			text:Hide()
		end
	end
end

function Display:Activate(timer)
	local oldTimer = self.timer

	if oldTimer ~= timer then
		self.timer = timer

		if oldTimer then
			oldTimer:Unsubscribe(self)
		end

		timer:Subscribe(self)
	end

	self:Show()
end

function Display:Deactivate()
	local timer = self.timer

	if timer then
		timer:Unsubscribe(self)
		self.timer = nil
	end

	self.text:SetText('')
	self:Hide()
end

-- hook the SetCooldown method of all cooldown frames
-- ActionButton1Cooldown is used here since its likely to always exist
-- and I'd rather not create my own cooldown frame to preserve a tiny bit of memory
hooksecurefunc(getmetatable(_G.ActionButton1Cooldown).__index, 'SetCooldown', function(cooldown, start, duration, modRate)
	if cooldown.noCooldownCount or cooldown:IsForbidden()  then return end

	local show = (start and start > 0)
			 and (duration and duration > C.minDuration)
			 and (modRate == nil or modRate > 0)

	if show then
		local display = Display:Get(cooldown) or Display:Create(cooldown)
		display:Activate(Timer:GetOrCreate(start, duration))
	else
		local display = Display:Get(cooldown)
		if display then
			display:Deactivate()
		end
	end
end)

hooksecurefunc(getmetatable(_G.ActionButton1Cooldown).__index, 'Clear', function(cooldown)
	local display = Display:Get(cooldown)
	if display then
		display:Deactivate()
	end
end)
