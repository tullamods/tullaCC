--[[
	tullaCooldownCount
		A basic cooldown count addon
		
		The purpose of this addon is mainly for me to test performance optimizations
		and also for people who don't care about the extra features of OmniCC
--]]

--constants!
local ICON_SIZE = 36 --the normal size for an icon (don't change this)
local FONT_FACE = STANDARD_TEXT_FONT --what font to use
local FONT_SIZE = 18 --the base font size to use at a scale of 1
local MIN_SCALE = 0.5 --the minimum scale we want to show cooldown counts at, anything below this will be hidden
local MIN_DURATION = 3 --the minimum duration to show cooldown text for
local DAY, HOUR, MINUTE = 86400, 3600, 60 --used for formatting text
local DAYISH, HOURISH, MINUTEISH = 3600 * 23.5, 60 * 59.5, 59.5 --used for formatting text at transition points
local HALFDAYISH, HALFHOURISH, HALFMINUTEISH = DAY/2 + 0.5, HOUR/2 + 0.5, MINUTE/2 + 0.5 --used for calculating next update times

--local bindings!
local format = string.format
local floor = math.floor
local min = math.min
local round = function(x) return floor(x + 0.5) end
local GetTime = GetTime

--returns both what text to display, and how long until the next update
local function getTimeText(s)
	--format text as seconds when at 90 seconds or below
	if s < MINUTEISH then 
		local seconds = round(s)
		return seconds, s - (seconds - 0.51)
	--format text as minutes when below an hour
	elseif s < HOURISH then
		local minutes = round(s/MINUTE)
		return minutes .. 'm', minutes > 1 and (s - (minutes*MINUTE - HALFMINUTEISH)) or (s - MINUTEISH)
	--format text as hours when below a day
	elseif s < DAYISH then
		local hours = round(s/HOUR)
		return hours .. 'h', hours > 1 and (s - (hours*HOUR - HALFHOURISH)) or (s - HOURISH)
	--format text as days
	else 
		local days = round(s/DAY)
		return days .. 'd', days > 1 and (s - (days*DAY - HALFDAYISH)) or (s - DAYISH)
	end
end

local function Timer_OnUpdate(self, elapsed)
	if self.nextUpdate > 0 then
		self.nextUpdate = self.nextUpdate - elapsed
	else
		local remain = self.duration - (GetTime() - self.start)
		if round(remain) > 0 then
			local time, nextUpdate = getTimeText(remain)
			self.text:SetText(time)
			self.nextUpdate = nextUpdate
		else
			self.text:Hide()
			self.nextUpdate = 0
			self:SetScript('OnUpdate', nil)
		end
	end
end

local function Timer_OnSizeChanged(self)
	if (self:GetParent():GetWidth() / ICON_SIZE) < MIN_SCALE then
		self.text:Hide()
		self:SetScript('OnUpdate', nil)
	else
		self.text:Show()
		self:SetScript('OnUpdate', Timer_OnUpdate)
	end
end

local function Timer_Create(self)
	local text = self:CreateFontString(nil, 'OVERLAY'); text:Hide()
	text:SetPoint('CENTER', 0, 36)
	text:SetFont(FONT_FACE, FONT_SIZE, 'OUTLINE')
	text:SetTextColor(1, 0.92, 0)
	self.text = text
	
	self:SetScript('OnSizeChanged', Timer_OnSizeChanged)
	return text
end

--ActionButton1Cooldown here, is something we think will always exist
hooksecurefunc(getmetatable(ActionButton1Cooldown).__index, 'SetCooldown', function(self, start, duration)
	--start timer
	if start > 0 and duration > MIN_DURATION then
		self.start = start
		self.duration = duration
		self.nextUpdate = 0

		local text = self.text or Timer_Create(self)
		if text then
			text:Show()
			self:SetScript('OnUpdate', Timer_OnUpdate)
		end
	--stop timer
	else	
		local text = self.text
		if text then
			text:Hide()
		end
	end
end)