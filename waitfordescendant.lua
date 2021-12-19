local WaitForDescendant = function(parent, obj, limit)
   local Result, Events, P, limitN = nil, {}, parent
   local function events_Cancel()
       for _, v in next, Events do
           if typeof(v) == 'RBXScriptConnection' and v.Connected == true then
               v:Disconnect()
           end
       end
   end

   if type(limit) == 'string' then
       limitN = 0 + limit:gsub('[^%d^%e%.%-]', '')
   elseif not limit or type(limit) == nil then
       limitN = 5
   elseif type(limit) == 'number' then
       limitN = limit
   end

   if typeof(P) == 'Instance' and typeof(obj) == 'string' or typeof(obj) == 'Instance' then
       local Pre = P:FindFirstChild(obj, true)
       if Pre then
           return Pre
       end

       local Timer = tick()
       local DC_Added; DC_Added = P.DescendantAdded:Connect(function(v)
           local Type = typeof(obj)
           if Type == 'string' and v.Name == obj then
               Result = v; events_Cancel(); table.clear(Events)
               return v
           elseif Type == 'Instance' and v == obj then
               Result = v; events_Cancel(); table.clear(Events)
               return v
           end
       end)
       table.insert(Events, DC_Added)

       repeat
           game:GetService('RunService').RenderStepped:wait()
       until Result or tick() - Timer > limitN

       events_Cancel(); table.clear(Events)
       return Result
   else
       if typeof(P) ~= 'Instance' then
           error("attempt to index nil with 'WaitForDescendant'", 1)
       end
       if typeof(obj) ~= 'Instance' and typeof(obj) ~= 'string' then
           error("Argument 2 missing or nil", 0)
       end
   end
end

local old
old = hookmetamethod(game,"__namecall",function(a,b,...)
   local namecall = getnamecallmethod()
   if namecall == "WaitForDescendant" then
       if typeof(a) == "Instance" then
           return WaitForDescendant(a,b,...)
       end
   end
   return old(a,b,...)
end)
