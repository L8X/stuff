local InstCons = {}
do
    local function GetParents(Obj)
        local Parent, Parents = Obj, {}
        if typeof(Obj) == "Instance" then
            repeat
                Parents[#Parents+1] = Parent
                Parent = Parent.Parent
            until not Parent
        end
        return Parents
    end

    getgenv().setrawproperty = function(Obj, Property, Value)
        assert(typeof(Obj) == "Instance", string.format("Invalid argument #1 (Instance expected, got %s)", typeof(Obj)))

        local Connections = {}
        for _,v in pairs({unpack(GetParents(Obj)), unpack(GetParents(Value))}) do
            if InstCons[v] then
                for Signal,_ in pairs(InstCons[v]) do
                    for _,Connection in pairs(getconnections(Signal)) do
                        if Connection.Enabled and Connection.Function ~= nil and Connection.State ~= nil then
                            Connections[#Connections+1] = Connection
                            Connection:Disable()
                        end
                    end
                end
            end
        end

        Obj[Property] = Value

        for _,v in pairs(Connections) do
            v:Enable()
        end
    end
end

do
    local OldNamecall
    OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
        local Args = {...}
        local Self = Args[1]
        if Self ~= nil and typeof(Self) == "Instance" then
            local success, output = pcall(function()
                return Self[getnamecallmethod()]
            end)

            if success and type(output) == "function" then
                local Result = {OldNamecall(...)}
                for _,v in pairs(Result) do
                    if typeof(v) == "RBXScriptSignal" then
                        if not InstCons[Self] then
                            InstCons[Self] = {}
                        end
                        InstCons[Self][v] = v
                    end
                end

                return unpack(Result)
            end
        end
        return OldNamecall(...)
    end))
end

local OldIndex
OldIndex = hookmetamethod(game, "__index", newcclosure(function(...)
    local Args = {...}
    local Self = Args[1]
    if Self ~= nil and typeof(Self) == "Instance" then
        local Result = {OldIndex(...)}
        for _,v in pairs(Result) do
            if typeof(v) == "RBXScriptSignal" then
                if not InstCons[Self] then
                    InstCons[Self] = {}
                end
                InstCons[Self][v] = v
            end
        end
        return unpack(Result)
    end
    return OldIndex(...)
end))

return setrawproperty
