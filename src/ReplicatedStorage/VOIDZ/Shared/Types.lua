--!strict
--[[
	Luau shape documentation for VOIDZ data.
	These tables are examples used by developers; runtime validation lives in Validate.lua.
]]

local Types = {}

Types.PlayerDataExample = {
	version = 1,
	onboarded = false,
	profile = {
		displayName = "",
		createdAt = 0,
		lastLogin = 0,
		bio = "",
		nameChangedAt = 0,
	},
	currency = {
		VoidCoins = 0,
	},
	inventory = {
		items = {} :: { [string]: { qty: number, acquiredAt: number } },
		equipped = {} :: { [string]: string },
	},
	avatar = {
		skinTone = { 0.55, 0.42, 0.34 },
	},
	settings = {},
	favorites = {} :: { string },
	likes = {} :: { string },
	recentlyPlayed = {} :: { string },
	stats = {
		gamesPlayed = 0,
		playClicks = 0,
		logins = 0,
		itemsOwned = 0,
		friends = 0,
		timePlayed = 0,
		transactions = {} :: { any },
	},
	achievements = {} :: { [string]: number },
	notifications = {} :: { any },
}

Types.GameExample = {
	Id = "neon_drift",
	Name = "Neon Drift",
	Description = "",
	Category = "Racing",
	MaxPlayers = 16,
	PlaceId = 0,
	Creator = "VOIDZ Studios",
	Featured = true,
	SeedPopularity = 1200,
	Accent = Color3.fromRGB(124, 92, 255),
	Accent2 = Color3.fromRGB(46, 230, 166),
}

return Types
