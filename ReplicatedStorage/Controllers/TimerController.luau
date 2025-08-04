--no strict typing because its weird with replica :^0

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local util = ReplicatedStorage:WaitForChild("Util")
local formatSeconds = require(util.FormatSeconds)
local ReplicaClient = require(util.ReplicaClient)

type TimerControllerImpl = {
	SetTimer : (time : number) -> ();
}

local player = Players.LocalPlayer
local playerGui = player:FindFirstChildWhichIsA("PlayerGui")

local timerGui = script.TimerGui
local textLabel = timerGui.Frame.TextLabel
local shadow = timerGui.Frame.Shadow
local redScore = timerGui.Frame.RedScore
local blueScore = timerGui.Frame.BlueScore

timerGui.Parent = playerGui

local function tweenUIScale(instance : UIScale, scale : number)
	return TweenService:Create(
		instance,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true),
		{Scale = scale}
	)
end

local TimerController : TimerControllerImpl = {
	SetTimer = function(timeSet)
		local formattedTime = formatSeconds(timeSet)
		
		textLabel.Text = `{formattedTime}`
		shadow.Text = `{formattedTime}`
		if timeSet > 5 then
			tweenUIScale(textLabel.UIScale, 1.05):Play()
			tweenUIScale(shadow.UIScale, 1.05):Play()
		else
			tweenUIScale(textLabel.UIScale, 1.2):Play()
			tweenUIScale(shadow.UIScale, 1.05):Play()
		end
	end,
}

redScore.Text = `{Teams.Red:GetAttribute("Score")}`
blueScore.Text = `{Teams.Blue:GetAttribute("Score")}`

Teams.Red:GetAttributeChangedSignal("Score"):Connect(function()
	redScore.Text = `{Teams.Red:GetAttribute("Score")}`
end)

Teams.Blue:GetAttributeChangedSignal("Score"):Connect(function()
	blueScore.Text = `{Teams.Blue:GetAttribute("Score")}`
end)

ReplicaClient.OnNew("GameData", function(replica)
	replica:OnSet({"Timer"}, function(newValue, oldValue)
		TimerController.SetTimer(newValue)
	end)
end)

return TimerController
