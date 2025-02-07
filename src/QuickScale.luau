--[=[
    @class QuickScale
    Class that handles UI scaling calculations and management.
]=]

local GuiService = game:GetService("GuiService")
local DEFAULT_SCREEN_SIZE = Vector2.new(1280, 720)
local DEFAULT_SCALE_BOUNDS = NumberRange.new(0, math.huge)
local DEFAULT_FACTOR = 1
local CurrentCamera = workspace.CurrentCamera

--[=[
    @param size Vector2 -- The size to calculate scale for
    @param params ScaleParams -- Scale parameters
    @return number -- Calculated scale value
]=]
local function calculateScale(size: Vector2, params: ScaleParams): number
	local ScreenSize = params.ScreenSize or DEFAULT_SCREEN_SIZE
	local ScaleBounds = params.ScaleBounds or DEFAULT_SCALE_BOUNDS
	local factor = params.Factor or DEFAULT_FACTOR
	local axis = math.min(size.X, size.Y)
	local reference = 1
		/ ScreenSize.Y
		* math.clamp(1 / ScreenSize.X * size.X / (1 / ScreenSize.Y * axis), 0, 1)
	return math.clamp(reference * axis, ScaleBounds.Min, ScaleBounds.Max) * factor
end

export type ScaleParams = {
	ScreenSize: Vector2,
	ScaleBounds: NumberRange,
	Factor: number,
	Location: Instance,
}

local Racoon = require(script.Parent.Racoon)
local QuickScale = {}
QuickScale.__index = QuickScale

--[=[
    @param uiScale UIScale -- The UIScale instance to manage
    @return QuickScale -- New QuickScale instance
]=]
function QuickScale.new(uiScale: UIScale)
	local self = setmetatable({}, QuickScale)

	self._textSizeConstraint = {}
	self._racoon = Racoon.new()
	self._isTracking = false
	self._uiScale = uiScale

	return self
end

--[=[
    @return ScaleParams -- Current scale parameters
]=]
function QuickScale.GetScaleParams(self: QuickScale): ScaleParams
	local uiScale = self._uiScale :: UIScale
	local location = uiScale:FindFirstChild("Location")

	return {
		ScreenSize = uiScale:GetAttribute("ScreenSize"),
		ScaleBounds = uiScale:GetAttribute("ScaleBounds"),
		Factor = uiScale:GetAttribute("Factor"),
		Location = location and location.Value or
			(uiScale:FindFirstAncestorOfClass("GuiBase2d") or uiScale.Parent)
	}
end

--[=[
    @param textSizeConstraint UITextSizeConstraint -- The constraint to add
]=]
function QuickScale.AddTextSizeConstraint(self: QuickScale, textSizeConstraint: UITextSizeConstraint): ()
	self._textSizeConstraint[textSizeConstraint] = true
	self:Update()
end

--[=[
    @param textSizeConstraint UITextSizeConstraint -- The constraint to remove
]=]
function QuickScale.RemoveTextSizeConstraint(self: QuickScale, textSizeConstraint: UITextSizeConstraint): ()
	self._textSizeConstraint[textSizeConstraint] = nil
end

--[=[
    Updates the scale and text size constraints
]=]
function QuickScale.Update(self: QuickScale): ()
	local uiScale = self._uiScale :: UIScale
	if not uiScale:IsA("UIScale") then
		return
	end

	local gui = uiScale:FindFirstAncestorWhichIsA("GuiBase2d")
	if not gui then
		return
	end
	local scaleParams = self:GetScaleParams()
	local sizeProperty = scaleParams.Location.AbsoluteSize and "AbsoluteSize" or "ViewportSize"
	local size = scaleParams.Location[sizeProperty]

	local result = calculateScale(size, scaleParams)
	uiScale.Scale = result

	for textConstraint in self._textSizeConstraint do
		local textSizeRange = textConstraint:GetAttribute("TextSizeRange")

		if typeof(textSizeRange) == "NumberRange" then
			textConstraint.MinTextSize = textSizeRange.Min * uiScale.Scale
			textConstraint.MaxTextSize = textSizeRange.Max * uiScale.Scale
		end
	end

	self._racoon:Add(scaleParams.Location:GetPropertyChangedSignal(sizeProperty):Once(function()
		self:Update()
	end))
end

--[=[
    Starts tracking UI scale changes
]=]
function QuickScale.Track(self: QuickScale): ()
	assert(not self._isTracking, `{self._uiScale} is already being Tracked.`)

	local uiScale = self._uiScale :: UIScale
	self:Update()

	self._racoon:Add(uiScale.AttributeChanged:Connect(function()
		self:Update()
	end))

	if uiScale:FindFirstChild("Location") then
		self._racoon:Add(uiScale.Location.Changed:Connect(function()
			self:Update()
		end))
	end

	self._isTracking = true
end

--[=[
    Stops tracking UI scale changes
]=]
function QuickScale.Untrack(self: QuickScale): ()
	self._racoon:Clean()
end

--[=[
    Cleans up the QuickScale instance
]=]
function QuickScale.Destroy(self: QuickScale): ()
	self:Untrack()

	table.clear(self)
	setmetatable(self, nil)
end

export type QuickScale = typeof(setmetatable({}, QuickScale))

return QuickScale:: {
	new: (uiScale: UIScale) -> QuickScale
}
