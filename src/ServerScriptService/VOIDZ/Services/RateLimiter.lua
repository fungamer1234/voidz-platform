--!strict

local Constants = require(game:GetService("ReplicatedStorage"):WaitForChild("VOIDZ"):WaitForChild("Shared"):WaitForChild("Constants"))

local RateLimiter = {}

type Bucket = { tokens: number, last: number }
local players: { [number]: { [string]: Bucket } } = {}

function RateLimiter.Clear(player: Player)
	players[player.UserId] = nil
end

function RateLimiter.Allow(player: Player, name: string): boolean
	if not player then
		return false
	end
	local limits = Constants.RATE_LIMITS[name] or Constants.RATE_LIMITS.default
	local uid = player.UserId
	players[uid] = players[uid] or {}
	local b = players[uid][name]
	local now = os.clock()
	if not b then
		b = { tokens = limits.tokens, last = now }
		players[uid][name] = b
	end
	local elapsed = now - b.last
	b.tokens = math.min(limits.tokens, b.tokens + elapsed * limits.refill)
	b.last = now
	if b.tokens < 1 then
		return false
	end
	b.tokens -= 1
	return true
end

return RateLimiter
