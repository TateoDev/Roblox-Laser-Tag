--!strict
return function(seconds : number) : string
	seconds = math.max(0, math.floor(seconds))
	if seconds < 60 then
		return string.format("%02d", seconds)
	else
		local minutes = math.floor(seconds / 60)
		local secs = seconds % 60
		return string.format("%d:%02d", minutes, secs)
	end
end
