local CollectionService = game:GetService("CollectionService")
local Maid = require(script.Parent.Maid)

return function(
	tag: string,
	callback: (instance: Instance, maid: Maid.Maid) -> (),
	predicate: ((instance: Instance) -> boolean)?
): Maid.Maid
	local instances = {}
	local topMaid = Maid.new()

	local function onInstanceAdded(instance: Instance)
		if predicate and not predicate(instance) then
			return
		end
		
		instances[instance] = Maid.new()
		callback(instance, instances[instance])
	end
	
	for _, instance in CollectionService:GetTagged(tag) do
		task.spawn(onInstanceAdded, instance)
	end
	
	topMaid:Add(CollectionService:GetInstanceAddedSignal(tag):Connect(onInstanceAdded))
	topMaid:Add(CollectionService:GetInstanceRemovedSignal(tag):Connect(function(instance)
		local maid = instances[instance]
		if not maid then
			return
		end
		
		maid:Destroy()
		instances[instance] = nil
	end))
	
	return topMaid
end
