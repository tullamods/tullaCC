--[[ A pool of objects for determining what text to display for a given cooldown, and notify subscribers when the text change ]]--

local AddonName, Addon = ...
local Timer = {}; Addon.Timer = Timer
local Timer_mt = { __index = Timer }
local active = {}
local inactive = {}

--local bindings!
local C = Addon.Config
local GetTime = _G.GetTime
local After = _G.C_Timer.After
local floor = math.floor
local max = math.max
local min = math.min
local round = function(x) return floor(x + 0.5) end
local next = next
local tinsert = table.insert
local tremove = table.remove

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
		local secondsFormat = seconds > C.expiringDuration and C.secondsFormat or C.expiringFormat
		return secondsFormat:format(seconds), s - (seconds - 0.51)
	--format text as minutes when below an hour
	elseif s < HOURISH then
		local minutes = round(s / MINUTE)
		return C.minutesFormat:format(minutes), minutes > 1 and (s - (minutes * MINUTE - HALFMINUTEISH)) or (s - MINUTEISH)
	--format text as hours when below a day
	elseif s < DAYISH then
		local hours = round(s / HOUR)
		return C.hoursFormat:format(hours), hours > 1 and (s - (hours * HOUR - HALFHOURISH)) or (s - HOURISH)
	--format text as days
	else
		local days = round(s / DAY)
		return C.daysFormat:format(days),  days > 1 and (s - (days * DAY - HALFDAYISH)) or (s - DAYISH)
	end
end

function Timer:GetOrCreate(start, duration)
	-- start and duration can have milisecond precision, so convert them into ints
	-- when creating a key to avoid floating point weirdness
	local key = ("%s-%s"):format(floor(start * 1000), floor(duration * 1000))

	-- first, look for an already active timer
	-- if we don't have one, then either reuse an old one or create a new one
	local timer = active[key]
	if not timer then
		if next(inactive) then
			timer = tremove(inactive)
			timer.key = key
			timer.start = start
			timer.duration = duration
			timer.text = nil
		else
			timer = setmetatable({
				key = key,
				start = start,
				duration = duration,
				subscribers = {},
				callback = function() timer:Update() end
			}, Timer_mt)
		end

		active[key] = timer
		timer:Update()
	end

	return timer
end

function Timer:Update()
	if not active[self.key] then return end

	local remain = (self.duration - (GetTime() - self.start)) or 0
	if round(remain) > 0 then
		local text, sleep = getTimeText(remain)

		-- notify subscribers only when the text of the timer changes
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
	if not active[self.key] then return end

	active[self.key] = nil

	for subscriber in pairs(self.subscribers) do
		subscriber:OnTimerDestroyed(self)
		self.subscribers[subscriber] = nil
	end

	tinsert(inactive, self)
end
