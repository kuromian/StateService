# Advanced State Manager

Enterprise-grade state management for Roblox with server/client architecture, automatic cleanup, callbacks, and real-time updates.

## Installation

Place the module anywhere to reference it later.\
Most preferably: ReplicatedStorage, ReplicatedFirst, ServerStoraage, ServerScriptService, Workspace

## Example

**Server:**
```luau
--!strict
local RunService = game:GetService("RunService")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StateService = require(ReplicatedStorage.Modules.StateService)

StateService:AddState(
	workspace,
	"GameStats",
	{
		PlayersOnline = 0
	},
	nil,
	{
		OnEdited = function(
			OldValue,
			NewValue
		): ()
			print("Game stats updated - PlayersOnline:", NewValue.PlayersOnline)
		end
	}, {
		ClientReadable = true
	}
)

Players.PlayerAdded:Connect(
	function(Player: Player): ()
		-- Create PRIVATE player profile
		StateService:AddState(
			Player,
			"PlayerData",
			{
				Example = "Hello World!"
			},
			nil,
			{
				OnRemoved = function(
					Value,
					ExpiredByLifespan
				): ()
					print(Player.Name .. "'s data removed:", ExpiredByLifespan and "expired" or "manual")

					print("Saving coins:", Value.coins, "Level:", Value.level)
				end,
				OnEdited = function(
					OldValue,
					NewValue
				): ()
					if OldValue.coins ~= NewValue.coins then
						print(Player.Name .. "'s coins changed from", OldValue.coins, "to", NewValue.coins)
					end

					if OldValue.level ~= NewValue.level then
						print(Player.Name .. " leveled up to", NewValue.level)
					end
				end,
				OnCalled = function(
					Caller,
					...
				): ()
					print("Player data accessed via:", Caller, "for player:", Player.Name)
				end
			},
			{
				ClientReadable = true,
				AuthorizedPlayers = {
					Player
				}
			}
		)

		-- Create PUBLIC player profile
		StateService:AddState(
			Player,
			"PublicProfile",
			{
				DisplayName = Player.DisplayName
			},
			nil,
			nil,
			{
				ClientReadable = true
			}
		)

		local GameStats = StateService:GetState(
			workspace,
			"GameStats"
		)

		if GameStats then
			(StateService :: any):EditState(
				workspace,
				"GameStats",
				{
					PlayersOnline = #Players:GetPlayers()
				}
			)
		end
	end
)

Players.PlayerRemoving:Connect(
	function(Player: Player): ()
		local GameStats = StateService:GetState(
			workspace,
			"GameStats"
		)

		if GameStats then
			(StateService :: any):EditState(
				workspace,
				"GameStats",
				{
					PlayersOnline = math.max(
						0,
						#Players:GetPlayers() - 1
					)
				}
			)
		end
	end
)
```

**Client:**
```luau
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
```

## Documentation

**[https://github.io/advanced-state-manager](https://github.io/advanced-state-manager)**