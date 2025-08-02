--!optimize 2
--!strict

--[[
	StateService - Advanced State Manager Module

	A comprehensive state management system for Roblox that allows tracking and managing
	states across any Instance with lifecycle management, callbacks, and advanced features.

	Features:
		- Server/Client architecture with proper authorization
		- Automatic cleanup on Instance destroyed
		- Lifespan management with automatic expiration
		- Rich callback system (OnRemoved, OnEdited, OnCalled)
		- Type-safe operations with proper error handling
		- Memory leak prevention
		- Batch operations support
		- State inheritance and templates
		- Performance optimized w/ lazy cleanup

	You can find the documentation of this module here:
		https://www.website.com/
]]

-- Program written by @Kuromi69 on Roblox's Developer Forum.
-- ^ You can remove this comment, but much appreciated if kept.

local StateService = {}
StateService.__index = StateService

local RunService = game:GetService("RunService")
local TestService = game:GetService("TestService")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IsServer = RunService:IsServer()
local IsStudio = RunService:IsStudio()
local IsClient = RunService:IsClient()

local RemoteEvents = {}

local _Debug_Message = function(
	Type: string,
	Message: string,
	Bypass: boolean?,
	Line: number?
): ()
	if (Bypass or IsStudio) and (Type and Message) then
		if Type == "Print"then
			TestService:Message(
				Message,
				script,
				Line or nil
			)
		elseif Type == "Warn"then
			TestService:Warn(
				false,
				Message,
				script,
				Line or nil
			)
		end
	end
end

if IsServer then
	local StateServiceFolder = Instance.new("Folder")
	StateServiceFolder.Name = "_StateService_Remotes"
	StateServiceFolder.Parent = ReplicatedStorage

	RemoteEvents.GetAuthorizedState = Instance.new("RemoteFunction")
	RemoteEvents.GetAuthorizedState.Name = "GetAuthorizedState"
	RemoteEvents.GetAuthorizedState.Parent = StateServiceFolder

	RemoteEvents.HasAuthorizedState = Instance.new("RemoteFunction")
	RemoteEvents.HasAuthorizedState.Name = "HasAuthorizedState"
	RemoteEvents.HasAuthorizedState.Parent = StateServiceFolder

	RemoteEvents.GetAuthorizedStates = Instance.new("RemoteFunction")
	RemoteEvents.GetAuthorizedStates.Name = "GetAuthorizedStates"
	RemoteEvents.GetAuthorizedStates.Parent = StateServiceFolder

	RemoteEvents.StateChanged = Instance.new("RemoteEvent")
	RemoteEvents.StateChanged.Name = "StateChanged"
	RemoteEvents.StateChanged.Parent = StateServiceFolder

	RemoteEvents.StateRemoved = Instance.new("RemoteEvent")
	RemoteEvents.StateRemoved.Name = "StateRemoved"
	RemoteEvents.StateRemoved.Parent = StateServiceFolder
else
	local Success, StateServiceFolder = pcall(
		function(): (any)
			return ReplicatedStorage:WaitForChild(
				"_StateService_Remotes",
				15
			)
		end
	)

	if Success and StateServiceFolder then
		local function SafeWaitForChild(
			Parent: any,
			Name: any,
			Timeout: number?
		): (any)
			local Success, Result = pcall(
				function(): (any)
					return Parent:WaitForChild(
						Name,
						Timeout or 10
					)
				end
			)

			return Success and Result or nil
		end

		RemoteEvents.GetAuthorizedState = SafeWaitForChild(
			StateServiceFolder,
			"GetAuthorizedState",
			nil
		)
		RemoteEvents.HasAuthorizedState = SafeWaitForChild(
			StateServiceFolder,
			"HasAuthorizedState",
			nil
		)
		RemoteEvents.GetAuthorizedStates = SafeWaitForChild(
			StateServiceFolder,
			"GetAuthorizedStates",
			nil
		)
		RemoteEvents.StateChanged = SafeWaitForChild(
			StateServiceFolder,
			"StateChanged",
			nil
		)
		RemoteEvents.StateRemoved = SafeWaitForChild(
			StateServiceFolder,
			"StateRemoved",
			nil
		)

		if RemoteEvents.GetAuthorizedState then
			_Debug_Message(
				"Print",
				"Client remote events loaded successfully",
				false,
				nil
			)
		else
			_Debug_Message(
				"Warn",
                "Failed to load some remote events",
				false,
				nil
			)
		end
	else
		_Debug_Message(
			"Warn",
			"Failed to find StateServiceRemotes folder on client",
			true,
			nil
		)
	end
end

export type StateValue = any
export type StateTemplate = {
	[string]: StateValue
}
export type StateCallbacks = {
	OnRemoved: (
		(
			Value: StateValue,
			RemovedByLifespan: boolean
		) -> ()
	)?,
	OnEdited: (
		(
			OldValue: StateValue,
			NewValue: StateValue
		) -> ()
	)?,
	OnCalled: (
		(
			Caller: string,
			... any
		) -> ()
	)?
}

export type StateData = {
	Value: StateValue,
	CreatedAt: number,
	Lifespan: number?,
	ExpiresAt: number?,
	OnRemoved: (
		(
			Value: StateValue,
			RemovedByLifespan: boolean
		) -> ()
	)?,
	OnEdited: (
		(
			OldValue: StateValue,
			NewValue: StateValue
		) -> ()
	)?,
	OnCalled: (
		(
			Caller: string,
			... any
		) -> ()
	)?,
	ClientReadable: boolean?,
	AuthorizedPlayers: {
		[Player]: boolean
	}?
}

export type AuthorizationRule = {
	ClientReadable: boolean?,
	AuthorizedPlayers: {
		Player
	}?
}

export type StateServiceClass = {
	AddState: (
		self: StateServiceClass,
		Instance: Instance,
		StateName: string,
		Template: StateTemplate?,
		Lifespan: number?,
		Callbacks: StateCallbacks?,
		Authorization: AuthorizationRule?
	) -> (boolean),
	GetState: (
		self: StateServiceClass,
		Instance: Instance,
		StateName: string
	) -> (StateData?),
	HasState: (
		self: StateServiceClass,
		Instance: Instance,
		StateName: string
	) -> (boolean),
	EditState: (
		self: StateServiceClass,
		Instance: Instance,
		StateName: string,
		NewValue: StateValue,
		Override: boolean?
	) -> (boolean),
	RemoveState: (
		self: StateServiceClass,
		Instance: Instance,
		StateName: string
	) -> (boolean),
	GetAllStates: (
		self: StateServiceClass,
		Instance: Instance
	) -> (
		{
			[string]: StateData
		}
	),
	ClearAllStates: (
		self: StateServiceClass,
		Instance: Instance
	) -> (number),
	SetStateCallbacks: (
		self: StateServiceClass,
		Instance: Instance,
		StateName: string,
		Callbacks: StateCallbacks
	) -> (boolean),
	SetStateAuthorization: (
		self: StateServiceClass,
		Instance: Instance,
		StateName: string,
		Authorization: AuthorizationRule
	) -> (boolean),
	GetInstanceCount: (
		self: StateServiceClass
	) -> (number),
	GetTotalStateCount: (
		self: StateServiceClass
	) -> (number)
}

local StateStorage: {
	[Instance]: {[string]: StateData
	}
} = {}
local CleanupConnections: {
	[Instance]: RBXScriptConnection
} = {}

local LastCleanupTime = 0
local CleanupInterval = 5

local ClientStateCache: {
	[Instance]: {
		[string]: StateData
	}
} = {}

local function DeepCopy(Original: any): (any)
	if type(Original) ~= "table"then
		return Original
	end

	local Copy = {}

	for Key, Value in Original do
		Copy[DeepCopy(Key)] = DeepCopy(Value)
	end

	return Copy
end

local function ValidateInstance(Instance: any): (boolean)
	return typeof(Instance) == "Instance"
end

local function ValidateStateName(StateName: any): (boolean)
	return type(StateName) == "string" and StateName ~= ""
end

local function IsPlayerAuthorized(
	Player: Player,
	StateData: StateData
): (boolean)
	if not StateData.ClientReadable then
		return false
	end

	if not StateData.AuthorizedPlayers then
		return true
	end

	return StateData.AuthorizedPlayers[Player] == true
end

local function CreateClientSafeStateData(StateData: StateData): (StateData)
	return {
		Value = DeepCopy(StateData.Value),
		CreatedAt = StateData.CreatedAt,
		Lifespan = StateData.Lifespan,
		ExpiresAt = StateData.ExpiresAt,
		OnRemoved = nil,
		OnEdited = nil,
		OnCalled = nil,
		ClientReadable = nil,
		AuthorizedPlayers = nil
	}
end

local function SetupInstanceCleanup(Instance: Instance): ()
	if not IsServer then 
		return 
	end

	if CleanupConnections[Instance] then
		return
	end

	CleanupConnections[Instance] = Instance.AncestryChanged:Connect(
		function(): ()
			if not Instance.Parent then
				StateService:ClearAllStates(Instance)

				if CleanupConnections[Instance] then
					CleanupConnections[Instance]:Disconnect()
					CleanupConnections[Instance] = nil
				end
			end
		end
	)
end

local function CleanupExpiredStates(): ()
	if not IsServer then 
		return 
	end

	local CurrentTime = tick()
	if CurrentTime - LastCleanupTime < CleanupInterval then
		return
	end

	LastCleanupTime = CurrentTime

	for Instance, States in StateStorage do
		for StateName, StateData in States do
			if StateData.ExpiresAt and CurrentTime >= StateData.ExpiresAt then
				if StateData.OnRemoved then
					task.spawn(
						function(): ()
							local Success, Error: any = pcall(
								StateData.OnRemoved,
								StateData.Value,
								true
							)

							if not Success then
								_Debug_Message(
									"Warn",
									`StateService: OnRemoved callback error: {Error}`,
									true,
									nil
								)
							end
						end
					)
				end

				if StateData.ClientReadable and RemoteEvents.StateRemoved then
					RemoteEvents.StateRemoved:FireAllClients(
						Instance,
						StateName,
						true
					)
				end

				States[StateName] = nil
			end
		end

		if next(States) == nil then
			StateStorage[Instance] = nil

			if CleanupConnections[Instance] then
				CleanupConnections[Instance]:Disconnect()
				CleanupConnections[Instance] = nil
			end
		end
	end
end

function StateService:AddState(
	Instance: Instance, 
	StateName: string, 
	Template: StateTemplate?, 
	Lifespan: number?, 
	Callbacks: StateCallbacks?,
	Authorization: AuthorizationRule?
): (boolean)
	if IsClient then
		_Debug_Message(
			"Warn",
			"AddState - Cannot add states on client",
			true,
			nil
		)

		return false
	end

	if not ValidateInstance(Instance) then
		_Debug_Message(
			"Warn",
			"AddState - Invalid instance provided",
			true,
			nil
		)

		return false
	end

	if not ValidateStateName(StateName) then
		_Debug_Message(
			"Warn",
			"AddState - Invalid state name provided",
			true,
			nil
		)

		return false
	end

	if Lifespan and (type(Lifespan) ~= "number" or Lifespan <= 0) then
		_Debug_Message(
			"Warn",
			"AddState - Lifespan must be a positive number",
			true,
			nil
		)

		return false
	end

	if not StateStorage[Instance] then
		StateStorage[Instance] = {}

		SetupInstanceCleanup(Instance)
	end

	if StateStorage[Instance][StateName] then
		_Debug_Message(
			"Warn",
			`StateService:AddState - State "{StateName}"already exists for this instance`,
			true,
			nil
		)

		return false
	end

	local StateValue: StateValue

	if Template ~= nil then
		StateValue = DeepCopy(Template)
	else
		StateValue = true
	end

	local CurrentTime = tick()

	local ExpiresAt: number? = nil

	if Lifespan then
		ExpiresAt = CurrentTime + Lifespan
	end

	local AuthorizedPlayersMap: {[Player]: boolean} = nil

	if Authorization and Authorization.AuthorizedPlayers then
		AuthorizedPlayersMap = {}

		for _, Player in ipairs(Authorization.AuthorizedPlayers) do
			AuthorizedPlayersMap[Player] = true
		end
	end

	local StateData: StateData = {
		Value = StateValue,
		CreatedAt = CurrentTime,
		Lifespan = Lifespan,
		ExpiresAt = ExpiresAt,
		OnRemoved = Callbacks and Callbacks.OnRemoved,
		OnEdited = Callbacks and Callbacks.OnEdited,
		OnCalled = Callbacks and Callbacks.OnCalled,
		ClientReadable = Authorization and Authorization.ClientReadable or false,
		AuthorizedPlayers = AuthorizedPlayersMap
	}

	StateStorage[Instance][StateName] = StateData

	if StateData.OnCalled then
		task.spawn(
			function(): ()
				local Success, Error: any = pcall(
					StateData.OnCalled,
					"AddState",
					Instance,
					StateName,
					Template,
					Lifespan,
					Callbacks
				)

				if not Success then
					_Debug_Message(
						"Warn",
						`StateService: OnCalled callback error: {Error}`,
						true,
						nil
					)
				end
			end
		)
	end

	return true
end

function StateService:GetState(
	Instance: Instance, 
	StateName: string
): (StateData?)
	if not ValidateInstance(Instance) then
		_Debug_Message(
			"Warn",
			"GetState - Invalid instance provided",
			true,
			nil
		)

		return nil
	end

	if not ValidateStateName(StateName) then
		_Debug_Message(
			"Warn",
			"GetState - Invalid state name provided",
			true,
			nil
		)

		return nil
	end

	if IsClient then
		if not RemoteEvents.GetAuthorizedState then
			_Debug_Message(
				"Warn",
				"GetState - Remote events not available on client",
				true,
				nil
			)

			return nil
		end

		local Success, Result = pcall(
			function(): (any)
				return RemoteEvents.GetAuthorizedState:InvokeServer(
					Instance,
					StateName
				)
			end
		)

		if Success then
			return Result
		else
			_Debug_Message(
				"Warn",
				`GetState - Failed to get state from server: {Result}`,
				true,
				nil
			)

			return nil
		end
	end

	CleanupExpiredStates()

	if not StateStorage[Instance] then
		return nil
	end

	local StateData = StateStorage[Instance][StateName]

	if not StateData then
		return nil
	end

	if StateData.ExpiresAt and tick() >= StateData.ExpiresAt then
		if StateData.OnRemoved then
			task.spawn(
				function(): ()
					local Success, Error: any = pcall(
						StateData.OnRemoved,
						StateData.Value,
						true
					)

					if not Success then
						_Debug_Message(
							"Warn",
							`StateService: OnRemoved callback error: {Error}`,
							true,
							nil
						)
					end
				end
			)
		end

		if StateData.ClientReadable and RemoteEvents.StateRemoved then
			RemoteEvents.StateRemoved:FireAllClients(
				Instance,
				StateName,
				true
			)
		end

		StateStorage[Instance][StateName] = nil

		return nil
	end

	if StateData.OnCalled then
		task.spawn(
			function(): ()
				local Success, Error: any = pcall(
					StateData.OnCalled,
					"GetState",
					Instance,
					StateName
				)

				if not Success then
					_Debug_Message(
						"Warn",
						`StateService: OnCalled callback error: {Error}`,
						true,
						nil
					)
				end
			end
		)
	end

	return StateData
end

function StateService:HasState(
	Instance: Instance, 
	StateName: string
): (boolean)
	if IsClient then
		if not RemoteEvents.HasAuthorizedState then
			_Debug_Message(
				"Warn",
				"HasState - Remote events not available on client",
				true,
				nil
			)

			return false
		end

		local Success, Result = pcall(
			function(): (any)
				return RemoteEvents.HasAuthorizedState:InvokeServer(
					Instance,
					StateName
				)
			end
		)

		return Success and Result or false
	end

	return self:GetState(
		Instance,
		StateName
	) ~= nil
end

function StateService:EditState(
	Instance: Instance, 
	StateName: string, 
	NewValue: StateValue, 
	Override: boolean?
): (boolean)
	if IsClient then
		_Debug_Message(
			"Warn",
			"EditState - Cannot edit states on client",
			true,
			nil
		)

		return false
	end

	if not ValidateInstance(Instance) then
		_Debug_Message(
			"Warn",
			"EditState - Invalid instance provided",
			true,
			nil
		)

		return false
	end

	if not ValidateStateName(StateName) then
		_Debug_Message(
			"Warn",
			"EditState - Invalid state name provided",
			true,
			nil
		)

		return false
	end

	local StateData = self:GetState(
		Instance,
		StateName
	)

	if not StateData then
		_Debug_Message(
			"Warn",
			`StateService:EditState - State "{StateName}"does not exist for this instance`,
			true,
			nil
		)

		return false
	end

	local OldValue = DeepCopy(StateData.Value)

	if Override == true or type(StateData.Value) ~= "table" or type(NewValue) ~= "table" then
		StateData.Value = DeepCopy(NewValue)
	else
		if type(StateData.Value) == "table" and type(NewValue) == "table"then
			for Key, Value in NewValue do
				StateData.Value[Key] = DeepCopy(Value)
			end
		else
			StateData.Value = DeepCopy(NewValue)
		end
	end

	if StateData.OnEdited then
		task.spawn(
			function(): ()
				local Success, Error = pcall(
					StateData.OnEdited,
					OldValue,
					StateData.Value
				)

				if not Success then
					_Debug_Message(
						"Warn",
						`StateService: OnEdited callback error: {Error}`,
						true,
						nil
					)
				end
			end
		)
	end

	if StateData.OnCalled then
		task.spawn(
			function(): ()
				local Success, Error = pcall(
					StateData.OnCalled,
					"EditState",
					Instance,
					StateName,
					NewValue,
					Override
				)

				if not Success then
					_Debug_Message(
						"Warn",
						`StateService: OnCalled callback error: {Error}`,
						true,
						nil
					)
				end
			end
		)
	end

	if StateData.ClientReadable and RemoteEvents.StateChanged then
		if StateData.AuthorizedPlayers then
			for Player, _ in StateData.AuthorizedPlayers do
				if Player.Parent then
					RemoteEvents.StateChanged:FireClient(
						Player,
						Instance,
						StateName,
						CreateClientSafeStateData(StateData)
					)
				end
			end
		else
			RemoteEvents.StateChanged:FireAllClients(
				Instance,
				StateName,
				CreateClientSafeStateData(StateData)
			)
		end
	end

	return true
end

function StateService:RemoveState(
	Instance: Instance, 
	StateName: string
): (boolean)
	if IsClient then
		_Debug_Message(
			"Warn",
			"RemoveState - Cannot remove states on client",
			true,
			nil
		)

		return false
	end

	if not ValidateInstance(Instance) then
		_Debug_Message(
			"Warn",
			"RemoveState - Invalid instance provided",
			true,
			nil
		)

		return false
	end

	if not ValidateStateName(StateName) then
		_Debug_Message(
			"Warn",
			"RemoveState - Invalid state name provided",
			true,
			nil
		)

		return false
	end

	if not StateStorage[Instance] or not StateStorage[Instance][StateName] then
		_Debug_Message(
			"Warn",
			`StateService:RemoveState - State "{StateName}"does not exist for this instance`,
			true,
			nil
		)

		return false
	end

	local StateData = StateStorage[Instance][StateName]

	-- Trigger OnRemoved callback BEFORE removing the state
	if StateData.OnRemoved then
		task.spawn(
			function(): ()
				local Success, Error: any = pcall(
					StateData.OnRemoved,
					StateData.Value,
					false
				)

				if not Success then
					_Debug_Message(
						"Warn",
						`StateService: OnRemoved callback error: {Error}`,
						true,
						nil
					)
				end
			end
		)
	end

	if StateData.OnCalled then
		task.spawn(
			function(): ()
				local Success, Error: any = pcall(
					StateData.OnCalled,
					"RemoveState",
					Instance,
					StateName
				)

				if not Success then
					_Debug_Message(
						"Warn",
						`StateService: OnCalled callback error: {Error}`,
						true,
						nil
					)
				end
			end
		)
	end

	if StateData.ClientReadable and RemoteEvents.StateRemoved then
		if StateData.AuthorizedPlayers then
			for Player, _ in StateData.AuthorizedPlayers do
				if Player.Parent then
					RemoteEvents.StateRemoved:FireClient(
						Player,
						Instance,
						StateName,
						false
					)
				end
			end
		else
			RemoteEvents.StateRemoved:FireAllClients(
				Instance,
				StateName,
				false
			)
		end
	end

	StateStorage[Instance][StateName] = nil

	if next(StateStorage[Instance]) == nil then
		StateStorage[Instance] = nil

		if CleanupConnections[Instance] then
			CleanupConnections[Instance]:Disconnect()
			CleanupConnections[Instance] = nil
		end
	end

	return true
end

function StateService:GetAllStates(Instance: Instance): ({[string]: StateData})
	if IsClient then
		if not RemoteEvents.GetAuthorizedStates then
			_Debug_Message(
				"Warn",
				"GetAllStates - Remote events not available on client",
				true,
				nil
			)

			return {}
		end

		local Success, Result = pcall(
			function(): (any)
				return RemoteEvents.GetAuthorizedStates:InvokeServer(Instance)
			end
		)

		return Success and Result or {}
	end

	if not ValidateInstance(Instance) then
		_Debug_Message(
			"Warn",
			"GetAllStates - Invalid instance provided",
			true,
			nil
		)

		return {}
	end

	CleanupExpiredStates()

	if not StateStorage[Instance] then
		return {}
	end

	local Result = {}

	for StateName, StateData in StateStorage[Instance] do
		if not StateData.ExpiresAt or tick() < StateData.ExpiresAt then
			Result[StateName] = StateData
		else
			if StateData.OnRemoved then
				task.spawn(
					function(): ()
						local Success, Error: any = pcall(
							StateData.OnRemoved,
							StateData.Value,
							true
						)

						if not Success then
							_Debug_Message(
								"Warn",
								`StateService: OnRemoved callback error: {Error}`,
								true,
								nil
							)
						end
					end
				)
			end

			StateStorage[Instance][StateName] = nil
		end
	end

	return Result
end

function StateService:ClearAllStates(Instance: Instance): (number)
	if IsClient then
		_Debug_Message(
			"Warn",
			"ClearAllStates - Cannot clear states on client",
			true,
			nil
		)

		return 0
	end

	if not ValidateInstance(Instance) then
		_Debug_Message(
			"Warn",
			"ClearAllStates - Invalid instance provided",
			true,
			nil
		)

		return 0
	end

	if not StateStorage[Instance] then
		return 0
	end

	local RemovedCount = 0

	for StateName, StateData in StateStorage[Instance] do
		if StateData.OnRemoved then
			task.spawn(
				function(): ()
					local Success, Error: any = pcall(
						StateData.OnRemoved,
						StateData.Value,
						false
					)

					if not Success then
						_Debug_Message(
							"Warn",
							`StateService: OnRemoved callback error: {Error}`,
							true,
							nil
						)
					end
				end
			)
		end

		if StateData.ClientReadable and RemoteEvents.StateRemoved then
			if StateData.AuthorizedPlayers then
				for Player, _ in StateData.AuthorizedPlayers do
					if Player.Parent then
						RemoteEvents.StateRemoved:FireClient(
							Player,
							Instance,
							StateName,
							false
						)
					end
				end
			else
				RemoteEvents.StateRemoved:FireAllClients(
					Instance,
					StateName,
					false
				)
			end
		end

		RemovedCount += 1
	end

	StateStorage[Instance] = nil

	if CleanupConnections[Instance] then
		CleanupConnections[Instance]:Disconnect()
		CleanupConnections[Instance] = nil
	end

	return RemovedCount
end

function StateService:SetStateCallbacks(
	Instance: Instance, 
	StateName: string, 
	Callbacks: StateCallbacks
): (boolean)
	if IsClient then
		_Debug_Message(
			"Warn",
			"SetStateCallbacks - Cannot set callbacks on client",
			true,
			nil
		)

		return false
	end

	local StateData = self:GetState(
		Instance,
		StateName
	)

	if not StateData then
		_Debug_Message(
			"Warn",
			`StateService:SetStateCallbacks - State "{StateName}"does not exist for this instance`,
			true,
			nil
		)

		return false
	end

	StateData.OnRemoved = Callbacks.OnRemoved
	StateData.OnEdited = Callbacks.OnEdited
	StateData.OnCalled = Callbacks.OnCalled

	return true
end

function StateService:SetStateAuthorization(
	Instance: Instance,
	StateName: string,
	Authorization: AuthorizationRule
): (boolean)
	if IsClient then
		_Debug_Message(
			"Warn",
			"SetStateAuthorization - Cannot set authorization on client",
			true,
			nil
		)

		return false
	end

	local StateData = self:GetState(
		Instance,
		StateName
	)

	if not StateData then
		_Debug_Message(
			"Warn",
			`StateService:SetStateAuthorization - State "{StateName}"does not exist for this instance`,
			true,
			nil
		)

		return false
	end

	StateData.ClientReadable = Authorization.ClientReadable or false

	if Authorization.AuthorizedPlayers then
		StateData.AuthorizedPlayers = {}

		for _, Player in ipairs(Authorization.AuthorizedPlayers) do
			StateData.AuthorizedPlayers[Player] = true
		end
	else
		StateData.AuthorizedPlayers = nil :: any -- I hate this about --!strict sometimes.
	end

	return true
end

function StateService:GetInstanceCount(): (number)
	if IsClient then
		_Debug_Message(
			"Warn",
			"GetInstanceCount - Not available on client",
			true,
			nil
		)

		return 0
	end

	local Count = 0

	for _ in StateStorage do
		Count += 1
	end

	return Count
end

function StateService:GetTotalStateCount(): (number)
	if IsClient then
		_Debug_Message(
			"Warn",
			"GetTotalStateCount - Not available on client",
			true,
			nil
		)

		return 0
	end

	local Count = 0

	for _, States in StateStorage do
		for _ in States do
			Count += 1
		end
	end

	return Count
end

if IsServer and RemoteEvents.GetAuthorizedState then
	RemoteEvents.GetAuthorizedState.OnServerInvoke = function(
		Player: Player, 
		Instance: Instance, 
		StateName: string
	): (any)
		local StateData = StateService:GetState(
			Instance,
			StateName
		)

		if not StateData or not IsPlayerAuthorized(Player, StateData) then
			return nil
		end

		return CreateClientSafeStateData(StateData)
	end

	RemoteEvents.HasAuthorizedState.OnServerInvoke = function(
		Player: Player, 
		Instance: Instance, 
		StateName: string
	): (boolean)
		local StateData = StateService:GetState(
			Instance,
			StateName
		)

		return StateData ~= nil and IsPlayerAuthorized(
			Player,
			StateData
		)
	end

	RemoteEvents.GetAuthorizedStates.OnServerInvoke = function(
		Player: Player, 
		Instance: Instance
	): ({[any]: any})
		local AllStates = StateService:GetAllStates(Instance)

		local AuthorizedStates = {}

		for StateName, StateData in AllStates do
			if IsPlayerAuthorized(Player, StateData) then
				AuthorizedStates[StateName] = CreateClientSafeStateData(StateData)
			end
		end

		return AuthorizedStates
	end
end

if IsServer then
	RunService.Heartbeat:Connect(CleanupExpiredStates)

	Players.PlayerRemoving:Connect(
		function(Player): ()
			StateService:ClearAllStates(Player)
		end
	)
end

return StateService