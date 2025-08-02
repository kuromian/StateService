### Server

``` luau linenums="1"
--!strict
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
					print(`{Player.Name}'s data removed: {ExpiredByLifespan and "expired" or "manual"}`)

					print(`Saving Example: {Value}`)

					-- Saving stuff here
				end,
				OnEdited = function(
					OldValue,
					NewValue
				): ()
					if OldValue.Example ~= NewValue.Example then
						print(`{Player.Name}'s Example changed from {OldValue.Example} to {NewValue.Example}`)
					end
				end,
				OnCalled = function(
					Caller,
					...
				): ()
					print(`Player data accessed via: {Caller}, for player: {Player.Name}`)
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

### Client

``` luau linenums="1"
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

**API Reference:** [API](/StateService/API)