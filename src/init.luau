--!strict

--[=[
    @class QuickScale
    Class that handles UI scaling calculations and management.
]=]

--[[
	MIT License

	Copyright ©️ 2025 Pcoi94

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
]]

export type ScaleParams = {
	ScreenSize: Vector2,
	ScaleBounds: NumberRange,
	Factor: number,
	Location: GuiBase2d,
}

if script:GetAttribute("Credits") then
	print("This game uses QuickScale to automatically scale its interfaces")
end

local StarterGui = game:GetService("StarterGui")

local ObserveTag = require(script.ObserveTag)
local Maid = require(script.Maid)

local DEFAULT_SCREEN_SIZE = Vector2.new(1280, 720)
local DEFAULT_SCALE_BOUNDS = NumberRange.new(0, math.huge)
local DEFAULT_FACTOR = 1

local currentCamera = workspace.CurrentCamera

--[[
	<strong>Calculates the scale value based on given parameters.</strong>
	<code>@param size Vector2</code>: The size to calculate scale for
	<code>@param params ScaleParams</code>: Scale parameters
	<code>@return number</code>: Calculated scale value
]]
local function calculateScale(size: Vector2, params: ScaleParams): number
	local screenSize = params.ScreenSize or DEFAULT_SCREEN_SIZE
	local scaleBounds = params.ScaleBounds or DEFAULT_SCALE_BOUNDS
	local factor = params.Factor or DEFAULT_FACTOR
	local axis = math.min(size.X, size.Y)
	local reference = 1 / screenSize.Y * math.clamp(1 / screenSize.X * size.X / (1 / screenSize.Y * axis), 0, 1)

	return math.clamp(reference * axis, scaleBounds.Min, scaleBounds.Max) * factor
end

local QuickScale = {}
QuickScale.__index = QuickScale

--[[
	<strong>Initializes QuickScale tracking for a specified tag.</strong>
	<code>@param tag string?</code>: The tag to observe for UI scaling
	<code>@param locationValue Instance?</code>: The location instance for UI elements
]]
function QuickScale.Init(tag: string?, locationValue)
	return ObserveTag(tag or "QuickScaleElement", function(uiScale, maid)
		local location = uiScale:FindFirstChild("Location")
		if not location then
			warn(`Missing ObjectValue 'Location' in {uiScale:GetFullName()}`)
			return
		end

		if not location:IsA("ObjectValue") then
			warn(location:GetFullName(), "is not an ObjectValue")
			return
		end

		local quickScale = QuickScale.new(uiScale :: UIScale)
		quickScale:Track()

		if locationValue and location.Value and not location.Value:IsDescendantOf(StarterGui) then
			location.Value = locationValue
		end

		for _, descendant in (uiScale.Parent :: Instance):GetDescendants() do
			if descendant:IsA("UITextSizeConstraint") then
				quickScale:AddTextSizeConstraint(descendant)
			end
		end

		maid:Add(function()
			quickScale:Destroy()
		end)
	end, function(instance)
		if not instance:IsA("UIScale") then
			warn(instance:GetFullName(), "is not a UIScale")
			return false
		end

		return not instance:IsDescendantOf(StarterGui)
	end)
end

--[[
	<strong>Creates a new QuickScale instance.</strong>
	<code>@param uiScale UIScale</code>: The UIScale instance to manage
	<code>@return QuickScale</code>: New QuickScale instance
]]
function QuickScale.new(uiScale: UIScale): QuickScale
	return setmetatable({
		_uiScale = uiScale,
		_maid = Maid.new(),
		_isTracking = false,
		_textSizeConstraint = {},
	}, QuickScale)
end

--[[
	<strong>Returns the current scale parameters.</strong>
	<code>@return ScaleParams</code>: Current scale parameters
]]
function QuickScale.GetScaleParams(self: QuickScale): ScaleParams
	local location = self._uiScale:FindFirstChild("Location")

	return {
		ScreenSize = self._uiScale:GetAttribute("ScreenSize") :: Vector2,
		ScaleBounds = self._uiScale:GetAttribute("ScaleBounds") :: NumberRange,
		Factor = self._uiScale:GetAttribute("Factor") :: number,
		Location = (location and (location:: any).Value or
			(self._uiScale:FindFirstChildOfClass("GuiBase") or self._uiScale.Parent)) :: GuiBase2d
	}
end

--[[
	<strong>Adds a text size constraint.</strong>
	<code>@param textSizeConstraint UITextSizeConstraint</code>: The constraint to add
]]
function QuickScale.AddTextSizeConstraint(self: QuickScale, textSizeConstraint: UITextSizeConstraint): ()
	self._textSizeConstraint[textSizeConstraint] = true
	self:Update()
end

--[[
	<strong>Removes a text size constraint.</strong>
	<code>@param textSizeConstraint UITextSizeConstraint</code>: The constraint to remove
]]
function QuickScale.RemoveTextSizeConstraint(self: QuickScale, textSizeConstraint: UITextSizeConstraint): ()
	self._textSizeConstraint[textSizeConstraint] = nil
end

--[[
	<strong>Updates the UI scale and text size constraints.</strong>
]]
function QuickScale.Update(self: QuickScale): ()
	local scaleParams = self:GetScaleParams()
	local result = calculateScale(scaleParams.Location.AbsoluteSize, scaleParams)
	self._uiScale.Scale = result

	for constraint in self._textSizeConstraint do
		local sizeBounds = constraint:GetAttribute("TextSizeBounds")
		if typeof(sizeBounds) == "NumberRange" then
			constraint.MinTextSize = sizeBounds.Min * result
			constraint.MaxTextSize = sizeBounds.Max * result
		end
	end

	self._maid:Add(scaleParams.Location:GetPropertyChangedSignal("AbsoluteSize"):Once(function()
		self:Update()
	end))
end

--[=[
   <strong>Starts tracking UI scale changes</strong>
]=]
function QuickScale.Track(self: QuickScale): ()
	if self._isTracking then
		warn(self._uiScale:GetFullName(),"is already being tracked")
		return
	end

	self:Update()

	self._maid:Add(self._uiScale.AttributeChanged:Connect(function()
		self:Update()
	end))

	self._maid:Add(self._uiScale:GetPropertyChangedSignal("Parent"):Connect(function()
		self:Update()
	end))

	local location = self._uiScale:FindFirstChild("Location")
	if location then
		self._maid:Add(location.Changed:Connect(function()
			self:Update()
		end))
	end

	self._isTracking = true
end

--[=[
   <strong>Stop tracking UI scale changes</strong>
]=]
function QuickScale.UnTrack(self: QuickScale): ()
	self._maid:DoCleaning()
end

--[=[
    <strong>Cleans up the QuickScale instance</strong>
]=]
function QuickScale.Destroy(self: QuickScale): ()
	self:UnTrack()
	
	table.clear(self:: any)
	setmetatable(self:: any, nil)
end

export type QuickScale = typeof(setmetatable({} :: {
	_uiScale: UIScale,
	_maid: Maid.Maid,
	_isTracking: boolean,
	_textSizeConstraint: {[UITextSizeConstraint]: boolean},
}, QuickScale))

return QuickScale
