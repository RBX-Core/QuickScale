--[=[
    Client script that handles UI scaling functionality.
    Provides automatic scaling of UI elements based on screen size and configuration.
]=]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local ObserveTag = require(script.ObserveTag)
local QuickScale = require(script.QuickScale)
local Racoon = require(script.Racoon)
local Glow = require(script.Glow)

--[=[
    @param tag string -- The tag to observe
    @param uiScale Instance -- The UIScale instance to handle
    @return function -- Cleanup function
]=]
ObserveTag("QuickScaleElement", function(uiScale, racoon)
	if not uiScale:IsDescendantOf(Players) then
		return
	end
	
	Glow.Assert(uiScale:IsA("UIScale"), `{Glow.FormatValue(uiScale)} is not a UIScale.`)
	local quickScale = QuickScale.new(uiScale)

	local parent = uiScale.Parent
	local racoon = Racoon.new()
	quickScale:Track()
	
	for _, descendant in parent:GetDescendants() do
		if descendant:IsA("UITextSizeConstraint") then
			quickScale:AddTextSizeConstraint(descendant)
		end
	end

	racoon:Add(function()
		racoon:Clean()
		quickScale:Destroy()
	end)
end)

if plugin then
	return
end

--> You can always delete the print but it would still be nice to leave it!
warn("📦 This game uses QuickScale to allow its interfaces to be scaled correctly !")
