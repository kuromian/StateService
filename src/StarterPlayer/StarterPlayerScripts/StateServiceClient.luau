--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

local Modules_RS = ReplicatedStorage:WaitForChild("Modules")

local StateService = require(
	Modules_RS:WaitForChild(
		"StateService",
		60
	) -- WaitForChild is crucial for the client.
)

print(StateService:GetState(Player, "PlayerData")) 
-- ^ Should print out the PlayerData due to being authorized by the server.