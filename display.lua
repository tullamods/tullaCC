--[[ A cooldown text display ]]--

local AddonName, Addon = ...
local _C = Addon.Config
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
		local display = setmetatable(CreateFrame('Frame', nil, cooldown), Display_mt)

		display:SetAllPoints(cooldown)
		display:SetScript('OnSizeChanged', self.OnSizeChanged)
		display:Hide()

		local text = display:CreateFontString(nil, 'OVERLAY')
		text:SetPoint('CENTER', 0, 0)
		text:SetFont(_C.fontFace, _C.fontSize, 'OUTLINE')
		display.text = text

		displays[cooldown] = display
		return display
end

function Display:Destroy()
	self:Hide()

	if self.timer then
		self.timer:Unsubscribe(self)
		self.timer = nil
	end
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

		if scale >= _C.minScale then
			text:Show()
			text:SetFont(_C.fontFace, scale * _C.fontSize, 'OUTLINE')
			text:SetShadowColor(0, 0, 0, 0.8)
			text:SetShadowOffset(1, -1)
			text:SetText(self.timer and self.timer.text or '')
		else
			text:Hide()
		end
	end
end

-- hook the SetCooldown method of all cooldown frames
-- ActionButton1Cooldown is used here since its likely to always exist
-- and I'd rather not create my own cooldown frame to preserve a tiny bit of memory
do
	local registered = {}

	hooksecurefunc(getmetatable(_G.ActionButton1Cooldown).__index, 'SetCooldown', function(cooldown, start, duration, modRate)
		if cooldown.noCooldownCount then return end

		-- reskin cooldown if we've not registered it before
		if not registered[cooldown] then
			registered[cooldown] = true

			cooldown:SetDrawBling(_C.drawBling)
			cooldown:SetDrawSwipe(_C.drawSwipe)
			cooldown:SetDrawEdge(_C.drawEdge)
			cooldown:SetHideCountdownNumbers(true)
		end

		local shouldShowDisplay = (start and start > 0) and (duration and duration > _C.minDuration) and (modRate == nil or modRate > 0)
		if shouldShowDisplay then
			local display = Display:Get(cooldown) or Display:Create(cooldown)
			local newTimer = Timer:GetOrCreate(start, duration)
			local oldTimer = display.timer

			if oldTimer ~= newTimer then
				display.timer = newTimer

				if oldTimer then
					oldTimer:Unsubscribe(display)
				end

				newTimer:Subscribe(display)
			end

			display:Show()
		else
			local display = Display:Get(cooldown)

			if display then
				display:Destroy()
			end
		end
	end)
end
