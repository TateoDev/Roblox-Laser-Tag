--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local ReplicaServer = require(ServerScriptService.ReplicaServer)

local util = ReplicatedStorage:WaitForChild("Util")
local GameSettings = require(util.GameSettings)

export type GameData = {
	Timer : number, 
	GameStatus: "Intermission" | "Playing"
}

type RoundServiceImpl = {
	assignTeams : () -> ();
	returnToLobby : () -> ();
}

local gameDataReplica = ReplicaServer.New({
	Token = ReplicaServer.Token("GameData"),
	Data = {
		Timer = 0,
		GameStatus = "Intermission"
	} :: GameData
})
gameDataReplica:Replicate()

local RoundService : RoundServiceImpl = {
	assignTeams = function()
		local playersInLobby = Teams.Lobby:GetPlayers()
		Random.new():Shuffle(playersInLobby)
		for index, player in playersInLobby do
			if index % 2 == 0 then
				player.Team = Teams.Red				
			else
				player.Team = Teams.Blue
			end
			player:LoadCharacter()
		end
	end,
	
	returnToLobby = function()
		for _, player in Teams.Red:GetPlayers() do
			player.Team = Teams.Lobby
			player:LoadCharacter()
		end
		for _, player in Teams.Blue:GetPlayers() do
			player.Team = Teams.Lobby
			player:LoadCharacter()
		end
	end,
}

while true do
	gameDataReplica:Set({"GameStatus"}, "Intermission")
	repeat
		for i = GameSettings.intermissionTime, 0, -1 do
			gameDataReplica:Set({"Timer"}, i)
			task.wait(1)
		end
	until #Players:GetPlayers() >= GameSettings.minimumPlayers
	
	gameDataReplica:Set({"GameStatus"},"Playing")
	RoundService.assignTeams()
	
	for i = GameSettings.roundTime, 0, -1 do
		gameDataReplica:Set({"Timer"}, i)
		task.wait(1)
	end
	RoundService.returnToLobby()
end

return RoundService
