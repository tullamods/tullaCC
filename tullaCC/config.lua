--[[
	Confuration settings for tullaCC
--]]


local Conf = select(2, ...)

--font settings
Conf.fontFace = STANDARD_TEXT_FONT  --what font to use
Conf.fontSize = 18  --the base font size to use at a scale of 1
Conf.fontColor = {1, 0.92, 0}  --the minimum scale we want to show cooldown counts at, anything below this will be hidden

--display settings
Conf.minScale = 0.6  --the minimum duration to show cooldown text for
Conf.minDuration = 3 --the minimum number of seconds a cooldown must be to use to display in the expiring format
Conf.expiringDuration = 5  --the minimum number of seconds a cooldown must be to use to display in the expiring format

--text format strings
Conf.expiringFormat = '|cffff0000%d|r' --format for timers that are soon to expire
Conf.secondsFormat = '|cffffff00%d|r' --format for timers that have seconds remaining
Conf.minutesFormat = '|cffffffff%dm|r' --format for timers that have minutes remaining
Conf.hoursFormat = '|cff66ffff%dh|r' --format for timers that have hours remaining
Conf.daysFormat = '|cff6666ff%dh|r' --format for timers that have days remaining