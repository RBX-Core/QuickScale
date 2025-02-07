--[=[
    @class ObserveTag
    Module that handles tag-based instance observation and callbacks.
]=]

local CollectionService = game:GetService("CollectionService")
local Racoon = require(script.Parent.Racoon)

--[=[
    @param tag string -- The tag to observe
    @param callback function -- Callback function to run when tagged instances are found
    @return function -- Cleanup function
]=]
return function(tag: string, callback: (instance: Instance, racoon: Racoon.Racoon) -> ())
	local mainRacoon = Racoon.new()
	local racoons = {}

	for _, instance in CollectionService:GetTagged(tag) do
		racoons[instance] = Racoon.new()
		callback(instance, racoons[instance])
	end

	mainRacoon:Add(CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance)
		racoons[instance] = Racoon.new()
		callback(instance, racoons[instance])
	end))

	mainRacoon:Add(CollectionService:GetInstanceRemovedSignal(tag):Connect(function(instance)
		racoons[instance]:Clean()
		racoons[instance] = nil
	end))

	return function()
		mainRacoon:Clean()
		for _, racoon in racoons do
			racoon:Destroy()
		end

		table.clear(racoons)
		mainRacoon = nil
	end
end
