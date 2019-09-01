-- tullaCC configuration settings
local _, Addon = ...

local defaults = {
	-- what font to use
	fontFace = function() return STANDARD_TEXT_FONT end,

	-- the base font size to use at a scale of 1
	fontSize = 18,

	-- font outline: OUTLINE, THICKOUTLINE, MONOCHROME, or nil
	fontOutline = nil,

	-- font shadow settings
	fontShadow = {
		-- color
		r = 0,
		g = 0,
		b = 0,
		a = 1,

		-- offsets
		x = 1,
		y = -1
	},

	-- the minimum scale we want to show cooldown counts at, anything below this will be hidden
	minScale = 0.6,

	-- the minimum number of seconds a cooldown's duration must be to display text
	minDuration = 3,

	-- the minimum number of seconds a cooldown must be to display in the expiring format
	expiringDuration = 5,

	-- when to show tenths of seconds remaining
	tenthsDuration = 3,

	-- when to show both minutes and seconds remaining
	mmSSDuration = 0,

	--format for timers that are soon to expire
	tenthsFormat = '0.1f',

	--format for timers that have seconds remaining
	secondsFormat = '%d',

	--format for timers displaying MM:SS
	mmssFormat = '%d:%02d',

	--format for timers that have minutes remaining
	minutesFormat = '%dm',

	--format for timers that have hours remaining
	hoursFormat = '%dh',

	--format for timers that have days remaining
	daysFormat = '%dd',

	styles = {
		-- loss of control
		controlled = {
			r = 1,
			g = 0.1,
			b = 0.1,
			a = 1,
			scale = 1.5
		},

		-- ability recharging
		charging = {
			r = 0.8,
			g = 1,
			b = 0.3,
			a = 0.8,
			scale = 0.75
		},

		-- ability will be ready shortly
		soon = {
			r = 1,
			g = 0.1,
			b = 0.1,
			a = 1,
			scale = 1.5
		},

		-- less than a minute to go
		seconds = {
			r = 1,
			g = 1,
			b = 0.1,
			a = 1,
			scale = 1
		},

		-- less than an hour to go
		minutes = {
			r = 1,
			g = 1,
			b = 1,
			a = 1,
			scale = 1
		},

		-- less than a day to go
		hours = {
			r = 0.7,
			g = 0.7,
			b = 0.7,
			a = 0.7,
			scale = 0.75
		},

		-- a day or longer to go
		days = {
			r = 0.7,
			g = 0.7,
			b = 0.7,
			a = 0.7,
			scale = 0.75
		}
	}
}

Addon.Config = setmetatable({}, {
	__index = function(t, k)
		local value = defaults[k]

		if type(value) == 'function' then
			return value()
		end

		return value
	end
})
