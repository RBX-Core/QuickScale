--[=[
    @class Glow
    A utility module for formatted debugging output and assertions.
    Provides methods for pretty-printing, warnings, errors, and checkpoints.
]=]

local TestService = game:GetService("TestService")

local VALID_CHARACTERS = "abcdefghijklmnopqrstuvwxyz1234567890_"
local DECORATION = `• {string.rep("—", 25)} •`

--[=[
    @param instance Instance -- The instance to parse
    @return string -- String representation of instance path
]=]
local function parseInstance(instance: Instance): string
	if instance == game then
		return "game"
	end

	local path = instance
	local result = ""

	repeat 
		local name = path.Name
		local loweredName = name:lower()
		local fullName = `.{name}`

		for i=1, #name do
			if not VALID_CHARACTERS:match(loweredName:sub(i, i)) then
				fullName = `["{name}"]`
				break
			end
		end

		result = `{fullName}{result}`
		path = path.Parent
	until path == game

	return `game{result}`
end

local Glow = {}
export type Glow = typeof(Glow)

--[=[
    @param text string -- Text to decorate
    @return string -- Decorated text with centered dashes
]=]
function Glow.FormatDecoration(text: string): string
	local textLength = #text
	local leftDashes = math.floor((25 - textLength - 2) / 2)
	local rightDashes = 25 - textLength - leftDashes - 2

	return `• {string.rep("—", leftDashes)} {text} {string.rep("—", rightDashes)} •`
end

--[=[
    @param lines string -- Debug trace lines to format
    @return string -- Formatted debug trace
]=]
function Glow.FormatDebugTrace(lines: string): string
	local result: string = ""

	for _, line in lines:split("\n") do
		local modulePath, lineNum, funcName = 
			line:match("^(.+):(%d+)%s*(.*)$")

		result ..= "\n"

		if not (modulePath and lineNum) then
			result ..= line
			continue
		end

		local formattedFunc = ""
		if funcName and funcName ~= "" then
			local name = funcName:match("function%s+([^%s]+)") 
				or funcName:match("function%s+'([^']+)'")
			if name then
				formattedFunc = `: function '{name}'`
			end
		end

		result ..= `→ game.{modulePath} (line {lineNum}){formattedFunc}`
	end

	return result:sub(2)
end

--[=[
    @param tbl {[any]: any} -- Table to format
    @param indent number? -- Indentation level
    @return string -- Formatted table representation
]=]
function Glow.FormatTable(tbl: { [any]: any }, indent: number?): string
	local result: { string } = {}
	local indent = indent or 0

	for key, value in tbl do
		local stringifiedKey = typeof(key) == "string" 
			and `"{tostring(key)}"` 
			or tostring(key)

		table.insert(result, `\t{("	"):rep(indent)}[{stringifiedKey}] = {Glow.FormatValue(value, indent + 1)}`)
	end

	return "{\n" .. table.concat(result, ",\n") .. `\n{("	"):rep(indent)}}`
end

--[=[
    @param value any -- Value to format
    @param ... any -- Additional parameters for nested formatting
    @return string -- Formatted value representation
]=]
function Glow.FormatValue(value: any, ...): string
	local valueType = type(value)

	if valueType == "string" then
		return `"{value}"`
	elseif valueType == "number" then
		return tostring(value)
	elseif valueType == "boolean" then
		return tostring(value)
	elseif valueType == "table" then
		return Glow.FormatTable(value, ...)
	elseif typeof(value) == "Instance" then
		return parseInstance(value)
	end

	return typeof(value)
end

--[=[
    @param type string -- Message type (e.g., "PRINT", "WARNING")
    @param messageParts {string} -- Array of message parts to format
    @return string -- Formatted message with decoration and stack trace
]=]
function Glow.FormatMessage(type: string, messageParts: { string }): string
	local concatenatedMessage = table.concat(messageParts, "\n• ")
	local stackTrace = debug.traceback(concatenatedMessage)

	local lines = {}
	for line in stackTrace:gmatch("([^\n]+)") do
		table.insert(lines, line)
	end

	local scriptLine = table.concat(lines, "\n", 3 + #concatenatedMessage:split("\n"))

	local prefix = `\n\n{Glow.FormatDecoration(type)}\n\n`
	local suffix = `{Glow.FormatDebugTrace(scriptLine)}\n\n{DECORATION}\n\n`

	return `{prefix}• {concatenatedMessage}\n{#messageParts < 2 and "" or "\n"}\n{suffix}`
end

--[=[
    @param ... any -- Values to print
]=]
function Glow.Print(...: any)
	local messageParts: { string } = {}

	for _, message in {...} do
		table.insert(messageParts, Glow.FormatValue(message))
	end

	print(Glow.FormatMessage("PRINT", messageParts))
end

--[=[
    @param ... any -- Values to warn about
]=]
function Glow.Warn(...: any)
	local messageParts: { string } = {}

	for _, message in {...} do
		table.insert(messageParts, Glow.FormatValue(message))
	end

	TestService:Warn(false, Glow.FormatMessage("WARNING", messageParts))
end

--[=[
    @param ... any -- Values to error with
    @return nil -- Always yields the current thread
]=]
function Glow.Error(...: any)
	local messageParts: { string } = {}

	for _, message in {...} do
		table.insert(messageParts, Glow.FormatValue(message))
	end

	TestService:Error(Glow.FormatMessage("ERROR", messageParts))
	return coroutine.yield()
end

--[=[
    @param condition boolean -- Condition to assert
    @param ... any -- Values to display if assertion fails
    @return nil -- Yields the current thread if assertion fails
]=]
function Glow.Assert(condition: boolean, ...)
	if condition then
		return
	end

	local messageParts: { string } = {}

	for _, message in {...} do
		table.insert(messageParts, Glow.FormatValue(message))
	end

	print(Glow.FormatMessage("ASSERTION", messageParts))

	TestService:Error(Glow.FormatMessage(
		"ASSERTION", messageParts
		))

	return coroutine.yield()
end

--[=[
    @param checkpointName any -- Name or value to use as checkpoint identifier
]=]
function Glow.Checkpoint(checkpointName: any)
	TestService:Message(Glow.FormatMessage("CHECKPOINT", {
		Glow.FormatValue(checkpointName)
	}))
end

return Glow
