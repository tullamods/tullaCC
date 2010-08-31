--[[
	Curation settings for tullaCC
--]]


local C = select(2, ...) --retrieve addon table

--font settings
C.fontFace = STANDARD_TEXT_FONT  --what font to use
C.fontSize = 18  --the base font size to use at a scale of 1

--display settings
C.minScale = 0.6  --the minimum size ratio of an object relative to an action button for a cooldown text to display.  
C.minDuration = 3 --the minimum number of seconds a cooldown must be to use to display in the expiring format
C.expiringDuration = 5  --the minimum number of seconds a cooldown must be to use to display in the expiring format

--text format strings
C.expiringFormat = '|cffff0000%d|r' --format for timers that are soon to expire
C.secondsFormat = '|cffffff00%d|r' --format for timers that have seconds remaining
C.minutesFormat = '|cffffffff%dm|r' --format for timers that have minutes remaining
C.hoursFormat = '|cff66ffff%dh|r' --format for timers that have hours remaining
C.daysFormat = '|cff6666ff%dh|r' --format for timers that have days remaining