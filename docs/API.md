!!! warning
    Parameter limitations apply to StateData.Value and client synchronization
!!! error
    DO NOT YIELD in callback functions (OnEdited, OnRemoved, OnCalled). Yielding will cause state desync.
!!! notice
    StateService will yield on require() if RemoteEvents aren't immediately available on client.

## Common Types

**Instance**
```lua
Instance: Instance
```

**StateName**
```lua
StateName: string
```

**StateTemplate**
```lua
StateTemplate: any
```

**StateCallbacks**
```lua
StateCallbacks: {
    OnRemoved: ((Value: any, RemovedByLifespan: boolean) -> ())?,
    OnEdited: ((OldValue: any, NewValue: any) -> ())?,
    OnCalled: ((Caller: string, ...any) -> ())?
}
```

**AuthorizationRule**
```lua
AuthorizationRule: {
    ClientReadable: boolean?,
    AuthorizedPlayers: {Player}?
}
```

**StateValue**
```lua
StateValue: any
```

## Guarantees
When client connects, all authorized states are immediately accessible via GetState().

## StateService (Server)

### StateService:AddState
```lua
StateService:AddState(
    Instance: Instance,
    StateName: string,
    Template: any?,
    Lifespan: number?,
    Callbacks: StateCallbacks?,
    Authorization: AuthorizationRule?
) -> boolean
```

### StateService:EditState
```lua
StateService:EditState(
    Instance: Instance,
    StateName: string,
    NewValue: any,
    Override: boolean?
) -> boolean
```

### StateService:RemoveState
```lua
StateService:RemoveState(
    Instance: Instance,
    StateName: string
) -> boolean
```

## StateService (Client)

### StateService:GetState
```lua
StateService:GetState(
    Instance: Instance,
    StateName: string
) -> StateData?
```

### StateService:HasState
```lua
StateService:HasState(
    Instance: Instance,
    StateName: string
) -> boolean
```

### StateService:GetAllStates
```lua
StateService:GetAllStates(
    Instance: Instance
) -> {[string]: StateData}
```

## StateData Structure

### StateData.Value
```lua
print(StateData.Value.Health) -- Access state data
print(StateData.CreatedAt) -- Timestamp when created
print(StateData.ExpiresAt) -- When it expires (if has lifespan)
```

## Real-Time Updates (Client)

### State Changed Events
```lua
if StateService.RemoteEvents and StateService.RemoteEvents.StateChanged then
    StateService.RemoteEvents.StateChanged.OnClientEvent:Connect(
        function(Instance: Instance, StateName: string, NewStateData: StateData)
            print("State updated:", StateName)
            print("New value:", NewStateData.Value)
        end
    )
end
```

### State Removed Events
```lua
if StateService.RemoteEvents and StateService.RemoteEvents.StateRemoved then
    StateService.RemoteEvents.StateRemoved.OnClientEvent:Connect(
        function(Instance: Instance, StateName: string, ExpiredByLifespan: boolean)
            print("State removed:", StateName, "Expired:", ExpiredByLifespan)
        end
    )
end
```

## Advanced Server Methods

### StateService:SetStateCallbacks
```lua
StateService:SetStateCallbacks(
    Instance: Instance,
    StateName: string,
    Callbacks: StateCallbacks
) -> boolean
```

### StateService:SetStateAuthorization
```lua
StateService:SetStateAuthorization(
    Instance: Instance,
    StateName: string,
    Authorization: AuthorizationRule
) -> boolean
```

### StateService:ClearAllStates
```lua
StateService:ClearAllStates(
    Instance: Instance
) -> number
```

## Utility Methods

### StateService:GetInstanceCount
```lua
StateService:GetInstanceCount() -> number -- Server only
```

### StateService:GetTotalStateCount
```lua
StateService:GetTotalStateCount() -> number -- Server only
```

---