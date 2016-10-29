--[[
	tullaCooldownCount
		A basic cooldown count addon

		The purpose of this addon is mainly for me to test performance optimizations
		and also for people who don't care about the extra features of OmniCC
--]]

local AddonName, Addon = ...
local Timer = {}; Addon.Timer = Timer
local timers = {}


--local bindings!
local Config = Addon.Config --pull in the addon table
local UIParent = _G['UIParent']
local GetTime = _G['GetTime']
local floor = math.floor
local max = math.max
local min = math.min
local round = function(x) return floor(x + 0.5) end

--sexy constants!
local ICON_SIZE = 36 --the normal size for an icon (don't change this)
local DAY, HOUR, MINUTE = 86400, 3600, 60 --used for formatting text
local DAYISH, HOURISH, MINUTEISH = 3600 * 23.5, 60 * 59.5, 59.5 --used for formatting text at transition points
local HALFDAYISH, HALFHOURISH, HALFMINUTEISH = DAY/2 + 0.5, HOUR/2 + 0.5, MINUTE/2 + 0.5 --used for calculating next update times
local MIN_DELAY = 0.01

--returns both what text to display, and how long until the next update
local function getTimeText(s)
	--format text as seconds when at 90 seconds or below
	if s < MINUTEISH then
		local seconds = round(s)
		local formatString = seconds > Config.expiringDuration and Config.secondsFormat or Config.expiringFormat
		return formatString, seconds, s - (seconds - 0.51)
	--format text as minutes when below an hour
	elseif s < HOURISH then
		local minutes = round(s/MINUTE)
		return Config.minutesFormat, minutes, minutes > 1 and (s - (minutes*MINUTE - HALFMINUTEISH)) or (s - MINUTEISH)
	--format text as hours when below a day
	elseif s < DAYISH then
		local hours = round(s/HOUR)
		return Config.hoursFormat, hours, hours > 1 and (s - (hours*HOUR - HALFHOURISH)) or (s - HOURISH)
	--format text as days
	else
		local days = round(s/DAY)
		return Config.daysFormat, days,  days > 1 and (s - (days*DAY - HALFDAYISH)) or (s - DAYISH)
	end
end

function Timer.SetNextUpdate(self, duration)
	C_Timer.After(max(duration, MIN_DELAY), self.OnTimerDone)
end

--stops the timer
function Timer.Stop(self)
	self.enabled = nil
	self.start = nil
	self.duration = nil

	self:Hide()
end

function Timer.UpdateText(self)
	local remain = self.enabled and (self.duration - (GetTime() - self.start)) or 0

	if round(remain) > 0 then
		if (self.fontScale * self:GetEffectiveScale() / UIParent:GetScale()) < Config.minScale then
			self.text:SetText('')
			Timer.SetNextUpdate(self, 1)
		else
			local formatStr, time, timeUntilNextUpdate = getTimeText(remain)
			self.text:SetFormattedText(formatStr, time)
			Timer.SetNextUpdate(self, timeUntilNextUpdate)
		end
	else
		Timer.Stop(self)
	end
end

--forces the given timer to update on the next frame
function Timer.ForceUpdate(self)
	Timer.UpdateText(self)

	self:Show()
end

--adjust font size whenever the timer's parent size changes
--hide if it gets too tiny
function Timer.OnSizeChanged(self, width, height)
	local fontScale = round(width) / ICON_SIZE
	if fontScale == self.fontScale then
		return
	end

	self.fontScale = fontScale
	if fontScale < Config.minScale then
		self:Hide()
	else
		self.text:SetFont(Config.fontFace, fontScale * Config.fontSize, 'OUTLINE')
		self.text:SetShadowColor(0, 0, 0, 0.8)
		self.text:SetShadowOffset(1, -1)
		if self.enabled then
			Timer.ForceUpdate(self)
		end
	end
end

--returns a new timer object
function Timer.Create(cooldown)
	--a frame to watch for OnSizeChanged events
	--needed since OnSizeChanged has funny triggering if the frame with the handler is not shown
	local scaler = CreateFrame('Frame', nil, cooldown)
	scaler:SetAllPoints(cooldown)

	local timer = CreateFrame('Frame', nil, scaler); timer:Hide()
	timer:SetAllPoints(scaler)

	timer.OnTimerDone = function() Timer.UpdateText(timer) end

	local text = timer:CreateFontString(nil, 'OVERLAY')
	text:SetPoint('CENTER', 0, 0)
	text:SetFont(Config.fontFace, Config.fontSize, 'OUTLINE')
	timer.text = text

	Timer.OnSizeChanged(timer, scaler:GetSize())
	scaler:SetScript('OnSizeChanged', function(self, ...) Timer.OnSizeChanged(timer, ...) end)

	-- prevent display of blizzard cooldown text
	cooldown:SetHideCountdownNumbers(true)

	timers[cooldown] = timer

	return timer
end

function Timer.Start(cooldown, start, duration, enable, forceShowDrawEdge, modRate)
	--start timer
	if start > 0 and duration > Config.minDuration and (not cooldown.noCooldownCount) then
		cooldown:SetDrawBling(Config.drawBling)
		cooldown:SetDrawSwipe(Config.drawSwipe)
		cooldown:SetDrawEdge(Config.drawEdge)

		local timer = timers[cooldown] or Timer.Create(cooldown)

		timer.enabled = true
		timer.start = start
		timer.duration = duration
		Timer.UpdateText(timer)

		if timer.fontScale >= Config.minScale then timer:Show() end
	--stop timer
	else
		local timer = timers[cooldown]
		if timer then
			Timer.Stop(timer)
		end
	end
end


do
	local f = CreateFrame('Frame'); f:Hide()

	f:SetScript('OnEvent', function()
		for cooldown, timer in pairs(timers) do
			Timer.ForceUpdate(timer)
		end
	end)

	f:RegisterEvent('PLAYER_ENTERING_WORLD')

	--hook the SetCooldown method of all cooldown frames
	--ActionButton1Cooldown is used here since its likely to always exist
	--and I'd rather not create my own cooldown frame to preserve a tiny bit of memory
	hooksecurefunc(getmetatable(_G['ActionButton1Cooldown']).__index, 'SetCooldown', Timer.Start)
end
