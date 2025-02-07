--!optimize 2

--[=[
    @class Racoon
    Utility class for managing cleanup of various objects and connections.
]=]

local Racoon = {}
Racoon.__index = Racoon

--[=[
    @return Racoon -- New Racoon instance
]=]
function Racoon.new()
	return setmetatable({}, Racoon)
end

--[=[
    @param item Item -- Item to add for cleanup
    @return T -- The added item
]=]
function Racoon.Add<T>(self: Racoon, item: Item & T): T
	table.insert(self, item)
	return item
end

--[=[
    @param self Racoon -- The Racoon instance
]=]
function Racoon.Clean(self: Racoon)
	for _, item in self do
		local itemTyp = typeof(item)

		if itemTyp == "Instance" then
			item:Destroy()
			continue
		end

		if itemTyp == "RBXScriptConnection" then
			item:Disconnect()
			continue
		end

		if itemTyp == "thread" then
			coroutine.close(item)
			continue
		end

		if itemTyp == "function" then
			task.spawn(item)
			continue
		end

		task.spawn(item.Destroy, item)
	end
end

export type Item = Instance
| RBXScriptConnection
| thread
| {Destroy: (self: any) -> (), [any]: any}
export type Racoon = typeof(setmetatable({}, Racoon))

return Racoon:: {
	new: () -> Racoon
}
