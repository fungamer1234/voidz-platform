--!strict

local Utility = {}

function Utility.deepCopy<T>(src: T): T
	if type(src) ~= "table" then
		return src
	end
	local t = src :: any
	local out = table.clone(t)
	for k, v in out do
		if type(v) == "table" then
			out[k] = Utility.deepCopy(v)
		end
	end
	return out :: T
end

function Utility.deepMerge(dst: { [any]: any }, src: { [any]: any }): { [any]: any }
	for k, v in src do
		if type(v) == "table" and type(dst[k]) == "table" then
			Utility.deepMerge(dst[k], v)
		elseif dst[k] == nil then
			dst[k] = if type(v) == "table" then Utility.deepCopy(v) else v
		end
	end
	return dst
end

function Utility.formatNumber(n: number): string
	n = math.floor(n + 0.0)
	if n < 0 then
		return "-" .. Utility.formatNumber(-n)
	end
	if n >= 1000000000 then
		return string.format("%.1fB", n / 1000000000)
	end
	if n >= 1000000 then
		return string.format("%.1fM", n / 1000000)
	end
	if n >= 10000 then
		return string.format("%.1fK", n / 1000)
	end
	local s = tostring(n)
	local k
	while true do
		s, k = string.gsub(s, "^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then
			break
		end
	end
	return s
end

function Utility.formatDate(unix: number): string
	if type(unix) ~= "number" or unix <= 0 then
		return "—"
	end
	local t = os.date("!*t", unix) :: any
	return string.format("%04d-%02d-%02d", t.year, t.month, t.day)
end

function Utility.clamp(n: number, a: number, b: number): number
	if n < a then
		return a
	end
	if n > b then
		return b
	end
	return n
end

function Utility.lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

function Utility.debounce(seconds: number): (string, { [string]: number }) -> boolean
	local last: { [string]: number } = {}
	return function(key: string, map: { [string]: number }?)
		local now = os.clock()
		local bucket = map or last
		if (bucket[key] or 0) + seconds > now then
			return false
		end
		bucket[key] = now
		return true
	end
end

function Utility.safeUnit(c: { number }?): Color3
	local r = 1
	local g = 1
	local b = 1
	if type(c) == "table" then
		r = Utility.clamp(tonumber(c[1]) or 1, 0, 1)
		g = Utility.clamp(tonumber(c[2]) or 1, 0, 1)
		b = Utility.clamp(tonumber(c[3]) or 1, 0, 1)
	end
	return Color3.new(r, g, b)
end

function Utility.colorSeq(a: Color3, b: Color3): ColorSequence
	return ColorSequence.new(a, b)
end

function Utility.find<T>(list: { T }, pred: (T) -> boolean): T?
	for _, v in list do
		if pred(v) then
			return v
		end
	end
	return nil
end

function Utility.includes(list: { any }, value: any): boolean
	for _, v in list do
		if v == value then
			return true
		end
	end
	return false
end

function Utility.removeValue(list: { any }, value: any)
	for i = #list, 1, -1 do
		if list[i] == value then
			table.remove(list, i)
		end
	end
end

function Utility.prependUnique(list: { string }, value: string, max: number)
	Utility.removeValue(list, value)
	table.insert(list, 1, value)
	while #list > max do
		table.remove(list)
	end
end

function Utility.playerOk(player: Player?): boolean
	return player ~= nil and player.Parent ~= nil
end

function Utility.capitalize(s: string): string
	if s == "" then
		return s
	end
	return string.upper(string.sub(s, 1, 1)) .. string.sub(s, 2)
end

function Utility.elapsed(unix: number): string
	local d = math.max(0, os.time() - unix)
	if d < 60 then
		return "just now"
	end
	if d < 3600 then
		return string.format("%dm ago", math.floor(d / 60))
	end
	if d < 86400 then
		return string.format("%dh ago", math.floor(d / 3600))
	end
	return string.format("%dd ago", math.floor(d / 86400))
end

function Utility.withRetry(tries: number, baseDelay: number, fn: () -> (boolean, any)): (boolean, any)
	local lastErr
	for i = 1, tries do
		local ok, a, b = pcall(fn)
		if ok then
			if a == true or (a ~= false and b == nil and a ~= nil) then
				-- fn may return (ok, result) or just result
			end
			return true, a
		end
		lastErr = a
		task.wait(baseDelay * (2 ^ (i - 1)))
	end
	return false, lastErr
end

function Utility.pcallRetry(tries: number, baseDelay: number, fn: () -> any): (boolean, any)
	local lastErr
	for i = 1, tries do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastErr = result
		if i < tries then
			task.wait(baseDelay * (2 ^ (i - 1)))
		end
	end
	return false, lastErr
end

return Utility
