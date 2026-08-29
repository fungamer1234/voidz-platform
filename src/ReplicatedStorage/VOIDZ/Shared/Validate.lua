--!strict

local Config = require(script.Parent.Config)
local Constants = require(script.Parent.Constants)

local Validate = {}

local NAME_PATTERN = "^[%a%d_]+$"

function Validate.displayName(raw: any): (boolean, string, string)
	if type(raw) ~= "string" then
		return false, "", Config.ReservedNames and Constants.ERRORS.NAME_INVALID or Constants.ERRORS.NAME_INVALID
	end
	local name = string.gsub(raw, "^%s+", "")
	name = string.gsub(name, "%s+$", "")
	if #name < Config.DisplayNameMin or #name > Config.DisplayNameMax then
		return false, name, Constants.ERRORS.NAME_INVALID
	end
	if not string.match(name, NAME_PATTERN) then
		return false, name, Constants.ERRORS.NAME_INVALID
	end
	if Config.ReservedNames[string.lower(name)] then
		return false, name, Constants.ERRORS.NAME_RESERVED
	end
	return true, name, ""
end

function Validate.positiveInt(n: any, maxN: number?): (boolean, number)
	if type(n) ~= "number" or n ~= n or n == math.huge or n == -math.huge then
		return false, 0
	end
	if n <= 0 or n ~= math.floor(n) then
		return false, 0
	end
	if maxN and n > maxN then
		return false, 0
	end
	return true, n
end

function Validate.nonEmptyString(s: any, maxLen: number): (boolean, string)
	if type(s) ~= "string" then
		return false, ""
	end
	if s == "" or #s > maxLen then
		return false, ""
	end
	return true, s
end

function Validate.slot(slot: any): boolean
	if type(slot) ~= "string" then
		return false
	end
	for _, s in Constants.SLOTS do
		if s == slot then
			return true
		end
	end
	return false
end

function Validate.skinTone(tone: any): { number }
	if type(tone) ~= "table" then
		return { 0.55, 0.42, 0.34 }
	end
	local function c(i: number, d: number): number
		local v = tonumber(tone[i])
		if not v then
			return d
		end
		return math.clamp(v, 0, 1)
	end
	return { c(1, 0.55), c(2, 0.42), c(3, 0.34) }
end

function Validate.settingsPatch(patch: any): { [string]: any }
	local out: { [string]: any } = {}
	if type(patch) ~= "table" then
		return out
	end
	local defaults = Config.DefaultSettings
	for key, def in defaults do
		if patch[key] ~= nil then
			local v = patch[key]
			local dt = type(def)
			if dt == "boolean" and type(v) == "boolean" then
				out[key] = v
			elseif dt == "number" and type(v) == "number" and v == v then
				if key == "uiScale" then
					out[key] = math.clamp(v, 0.75, 1.35)
				elseif string.find(key, "Volume", 1, true) then
					out[key] = math.clamp(v, 0, 1)
				else
					out[key] = math.clamp(v, 0, 1)
				end
			end
		end
	end
	return out
end

function Validate.reason(s: any): string
	if type(s) ~= "string" then
		return "unknown"
	end
	if #s > 48 then
		return string.sub(s, 1, 48)
	end
	return s
end

return Validate
