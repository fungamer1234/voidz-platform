--!strict
--[[
	Strips server-only fields before replicating player data to clients.
]]

local Utility = require(script.Parent.Utility)

local Sanitize = {}

function Sanitize.forClient(data: any): any
	if type(data) ~= "table" then
		return {}
	end
	local copy = Utility.deepCopy(data)
	copy._session = nil
	copy._force = nil
	return copy
end

function Sanitize.publicProfile(data: any, userId: number, robloxName: string): any
	if type(data) ~= "table" then
		return {
			userId = userId,
			robloxName = robloxName,
			displayName = robloxName,
			onboarded = false,
		}
	end
	return {
		userId = userId,
		robloxName = robloxName,
		displayName = data.profile and data.profile.displayName or robloxName,
		createdAt = data.profile and data.profile.createdAt or 0,
		bio = data.profile and data.profile.bio or "",
		currency = data.currency and data.currency.VoidCoins or 0,
		gamesPlayed = data.stats and data.stats.gamesPlayed or 0,
		favorites = data.favorites or {},
		achievements = data.achievements or {},
		avatar = {
			equipped = data.inventory and data.inventory.equipped or {},
			skinTone = data.avatar and data.avatar.skinTone or { 0.55, 0.42, 0.34 },
		},
		stats = {
			gamesPlayed = data.stats and data.stats.gamesPlayed or 0,
			logins = data.stats and data.stats.logins or 0,
			itemsOwned = data.stats and data.stats.itemsOwned or 0,
			friends = data.stats and data.stats.friends or 0,
		},
	}
end

return Sanitize
