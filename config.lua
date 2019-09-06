-- tullaCC configuration settings
local AddonName, Addon = ...
local DB_KEY = AddonName .. "DB"
local DB_VERSION = 1

local function removeDefaults(tbl, defaults)
	for k, v in pairs(defaults) do
		if type(tbl[k]) == "table" and type(v) == "table" then
			removeDefaults(tbl[k], v)
			if next(tbl[k]) == nil then
				tbl[k] = nil
			end
		elseif tbl[k] == v then
			tbl[k] = nil
		end
	end

	return tbl
end

local function copyDefaults(tbl, defaults)
	for k, v in pairs(defaults) do
		if type(v) == "table" then
			tbl[k] = copyDefaults(tbl[k] or {}, v)
		elseif tbl[k] == nil then
			tbl[k] = v
		end
	end

	return tbl
end

function Addon:SetupDatabase()
	local config = _G[DB_KEY]

	if not config then
		config = { version = DB_VERSION }

		-- luacheck: push ignore 122
		_G[DB_KEY] = config
		-- luacheck: pop
	end

	self.Config = copyDefaults(config, self:GetDatabaseDefaults())
end

function Addon:CleanupDatabase()
	local config = self.Config
	if config then
		removeDefaults(config, self:GetDatabaseDefaults())
	end
end

function Addon:GetDatabaseDefaults()
	return {
		-- what font to use
		fontFace = STANDARD_TEXT_FONT,
		-- the base font size to use at a scale of 1
		fontSize = 18,
		-- font outline: OUTLINE, THICKOUTLINE, MONOCHROME, or nil
		fontOutline = "OUTLINE",
		-- font shadow settings
		fontShadow = {
			-- color
			r = 0,
			g = 0,
			b = 0,
			a = 1,
			-- offsets
			x = 0,
			y = 0
		},
		-- text positioning
		anchor = "CENTER",
		xOff = 0,
		yOff = 0,
		-- scale text to fit within the cooldown frame
		scaleText = true,
		-- the minimum scale we want to show cooldown counts at, anything below this will be hidden
		-- this value is a percentage of the size of an ActionButton
		minScale = 0.6,
		-- the minimum number of seconds a cooldown's duration must be to display text
		minDuration = 3,
		-- the minimum number of miliseconds a cooldown must be to display in the expiring format
		expiringDuration = 5000,
		-- when to show tenths of seconds remaining, in miliseconds
		tenthsDuration = 0,
		-- when to show both minutes and seconds remaining, in miliseconds
		mmSSDuration = 0,
		--format for timers that are soon to expire
		tenthsFormat = "%0.1f",
		--format for timers that have seconds remaining
		secondsFormat = "%d",
		--format for timers displaying MM:SS
		mmssFormat = "%d:%02d",
		--format for timers that have minutes remaining
		minutesFormat = "%dm",
		--format for timers that have hours remaining
		hoursFormat = "%dh",
		--format for timers that have days remaining
		daysFormat = "%dd",

		-- enables styling text based upon duration remaining
		enableStyles = true,

		-- color and alpha values are percentages between 0 and 1
		-- scale values are multipliers
		styles = {
			-- ability will be ready shortly
			soon = {
				r = 1,
				g = 0.1,
				b = 0.1,
				a = 1,
				scale = 1.25
			},
			-- less than a minute to go
			seconds = {
				r = 1,
				g = 1,
				b = 0.1,
				a = 1,
				scale = 1
			},
			-- more than a minute to go
			minutes = {
				r = 1,
				g = 1,
				b = 1,
				a = 1,
				scale = 0.81
			},
			-- more than an hour to go
			hours = {
				r = 1,
				g = 1,
				b = 1,
				a = 1,
				scale = 0.81
			},
			-- more than a day to go
			days = {
				r = 1,
				g = 1,
				b = 1,
				a = 1,
				scale = 0.81
			}
		},

		-- enables cooldown style configuration
		enableCooldownStyles = true,

		-- cooldown styles are stored by cooldown type
		cooldownStyles = {
			-- normal cooldowns
			default = {
				-- enable text
				text = true,
				-- show cooldown swipes
				-- can be one of "default" (do whatever the game normally does)
				-- true (always enable)
				-- false (always disable)
				swipe = "default",
				-- show cooldown edges
				edge = "default",
				-- show cooldown sparkles
				bling = "default"
			},
			-- charges
			charge = {
				text = false,
				swipe = "default",
				edge = "default",
				bling = "default"
			},
			-- loss of control cooldowns
			loc = {
				text = true,
				swipe = "default",
				edge = "default",
				bling = "default"
			}
		}
	}
end

function Addon:ResetDatabase()
	-- luacheck: push ignore 122
	_G[DB_KEY] = nil
	-- luacheck: pop

	self:SetupDatabase()
end
