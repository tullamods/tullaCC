--[[ A pool of objects for determining what text to display for a given cooldown, and notify subscribers when the text change ]]--

local AddonName, Addon = ...
local Timer = {}; Addon.Timer = Timer
local Timer_mt = { __index = Timer }
local cache = {}

--local bindings!
local _C = Addon.Config --pull in the addon table
local GetTime = _G.GetTime
local After = _G.C_Timer.After
local floor = math.floor
local max = math.max
local min = math.min
local round = function(x) return floor(x + 0.5) end

--sexy constants!
local DAY, HOUR, MINUTE = 86400, 3600, 60 --used for formatting text
local DAYISH, HOURISH, MINUTEISH = 3600 * 23.5, 60 * 59.5, 59.5 --used for formatting text at transition points
local HALFDAYISH, HALFHOURISH, HALFMINUTEISH = DAY/2 + 0.5, HOUR/2 + 0.5, MINUTE/2 + 0.5 --used for calculating next update times
local MIN_DELAY = 0.01

--returns both what text to display, and how long until the next update
local function getTimeText(s)
	--format text as seconds when at 90 seconds or below
	if s < MINUTEISH then
		local seconds = round(s)
		local formatString = seconds > _C.expiringDuration and _C.secondsFormat or _C.expiringFormat
		return formatString, seconds, s - (seconds - 0.51)
	--format text as minutes when below an hour
	elseif s < HOURISH then
		local minutes = round(s / MINUTE)
		return _C.minutesFormat, minutes, minutes > 1 and (s - (minutes * MINUTE - HALFMINUTEISH)) or (s - MINUTEISH)
	--format text as hours when below a day
	elseif s < DAYISH then
		local hours = round(s / HOUR)
		return _C.hoursFormat, hours, hours > 1 and (s - (hours * HOUR - HALFHOURISH)) or (s - HOURISH)
	--format text as days
	else
		local days = round(s / DAY)
		return _C.daysFormat, days,  days > 1 and (s - (days * DAY - HALFDAYISH)) or (s - DAYISH)
	end
end

function Timer:GetOrCreate(start, duration)
	local key = ("%s-%d"):format(start, duration)
	local timer = cache[key]

	if not timer then
		timer = setmetatable({
			start = start,
			duration = duration,
			subscribers = {},
			callback = function() timer:Update() end
		}, Timer_mt)

		timer:Update()

		cache[key] = timer
	end

	return timer
end

function Timer:Update()
	if self.destroyed then return end

	local remain = (self.duration - (GetTime() - self.start)) or 0

	if round(remain) > 0 then
		local template, value, sleep = getTimeText(remain)
		local text = template:format(value)

		-- notify timers only when the text of the timer changes
		if self.text ~= text then
			self.text = text

			for subscriber in pairs(self.subscribers) do
				subscriber:OnTimerUpdated(self)
			end
		end

		After(max(sleep, MIN_DELAY), self.callback)
	else
		self:Destroy()
	end
end

function Timer:Subscribe(subscriber)
	if self.subscribers[subscriber] then return end

	self.subscribers[subscriber] = true
	subscriber:OnTimerUpdated(self)
end

function Timer:Unsubscribe(subscriber)
	self.subscribers[subscriber] = nil

	if not next(self.subscribers) then
		self:Destroy()
	end
end

function Timer:Destroy()
	if self.destroyed then return end

	self.destroyed = true

	for subscriber in pairs(self.subscribers) do
		subscriber:OnTimerDestroyed(self)
	end

	cache[self] = nil
end