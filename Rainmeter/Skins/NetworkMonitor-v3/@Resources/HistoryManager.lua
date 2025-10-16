function Initialize()
	-- Initialize history tracking for last 6 pings (60 seconds at 10s interval)
	history = {}
	historyCount = 0
	colorBar = SKIN:GetVariable('colorBar')
	colorBarDim = SKIN:GetVariable('colorBarDim')

	-- Track consecutive successes
	consecutiveSuccess = 0

	-- Initialize display variables to 0
	SKIN:Bang('!SetVariable', 'History60sUptime', '0')
	SKIN:Bang('!SetVariable', 'History60sSuccess', '0')
	SKIN:Bang('!SetVariable', 'History60sTotal', '0')
	SKIN:Bang('!SetVariable', 'ConsecutiveSuccess', '0')
	SKIN:Bang('!SetVariable', 'ConsecutiveSuccessDisplay', '0')
end

function FormatConsecutiveSuccess(count)
	if count >= 10000 then
		return "∞"
	elseif count >= 1000 then
		return math.floor(count / 1000) .. "k"
	else
		return tostring(count)
	end
end

function UpdateHistory()
	-- Get current ping result from MeasurePing
	local pingResult = tonumber(SKIN:GetMeasure('MeasurePing'):GetValue())

	-- Track consecutive successes
	if pingResult >= 0 then
		-- Success - increment counter
		consecutiveSuccess = consecutiveSuccess + 1
	else
		-- Failure - reset to 0
		consecutiveSuccess = 0
	end

	-- Update the consecutive success display with formatted value
	local displayValue = FormatConsecutiveSuccess(consecutiveSuccess)
	SKIN:Bang('!SetVariable', 'ConsecutiveSuccess', tostring(consecutiveSuccess))
	SKIN:Bang('!SetVariable', 'ConsecutiveSuccessDisplay', displayValue)

	-- Add new result to history array
	if pingResult >= 0 then
		table.insert(history, 1)  -- Success
	else
		table.insert(history, 0)  -- Failure
	end

	historyCount = historyCount + 1

	-- Keep only last 6 pings (60 seconds worth)
	if #history > 6 then
		table.remove(history, 1)  -- Remove oldest
	end

	-- Calculate uptime percentage for last 60 seconds
	local successCount = 0
	for i = 1, #history do
		if history[i] == 1 then
			successCount = successCount + 1
		end
	end

	local uptimePercent = 0
	if #history > 0 then
		uptimePercent = (successCount / #history) * 100
	end

	-- Update the History60sUptime variable (for the bar)
	SKIN:Bang('!SetVariable', 'History60sUptime', tostring(uptimePercent))

	-- Update the success count (for the text display)
	SKIN:Bang('!SetVariable', 'History60sSuccess', tostring(successCount))
	SKIN:Bang('!SetVariable', 'History60sTotal', tostring(#history))

	-- Force update meters
	SKIN:Bang('!UpdateMeter', 'meterValueStatus')
	SKIN:Bang('!UpdateMeter', 'meterBarStatus')
	SKIN:Bang('!UpdateMeter', 'meterValueUptime')
	SKIN:Bang('!UpdateMeter', 'meterValueHistory')
	SKIN:Bang('!UpdateMeter', 'meterBarHistory')
	SKIN:Bang('!Redraw')

	return true
end

function Update()
	-- This function is called every update cycle
	-- We use FinishAction in the ping measure to trigger UpdateHistory when needed
	return 0
end
