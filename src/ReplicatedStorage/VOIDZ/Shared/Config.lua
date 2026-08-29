--!strict
--[[
	VOIDZ platform configuration.
	Edit this module to brand, tune economy, register developers, and plug in PlaceIds.
	Never put secrets here. Developer power is still validated server-side against UserIds.
]]

local Config = {}

Config.Version = "1.1.0"
Config.Build = 110
Config.Name = "VOIDZ"
Config.Tagline = "A universe of games."
Config.StudioName = "VOIDZ Studios"
Config.CurrencyName = "VoidCoins"
Config.CurrencySymbol = "VC"

Config.DataStoreName = "VOIDZ_Player_v1"
Config.NameStoreName = "VOIDZ_DisplayNames_v1"
Config.GameStatsStoreName = "VOIDZ_GameStats_v1"
Config.FriendsStoreName = "VOIDZ_Friends_v1"
Config.MetaStoreName = "VOIDZ_Meta_v1"
Config.DataVersion = 1

-- Add your Roblox userId(s). Empty in live servers = no admins.
-- In Roblox Studio play-solo, the local player is treated as a developer for testing.
Config.DeveloperUserIds = {
	-- 123456789,
} :: { number }

Config.MaintenanceMode = false
Config.MaintenanceMessage = "VOIDZ is undergoing maintenance. Please try again shortly."
Config.DebugMode = false

Config.StarterCurrency = 250
Config.MaxCurrency = 1000000000
Config.MaxGrantPerCall = 100000
Config.DisplayNameMin = 3
Config.DisplayNameMax = 16
Config.DisplayNameChangeCooldown = 60
Config.MaxNotifications = 50
Config.MaxRecentlyPlayed = 12
Config.MaxTransactionLog = 25
Config.InventoryMaxUnique = 200

Config.SessionLockSeconds = 90
Config.SaveInterval = 90
Config.DataRetries = 5
Config.DataRetryBaseDelay = 0.4

Config.ReservedNames = {
	admin = true,
	administrator = true,
	mod = true,
	moderator = true,
	system = true,
	voidz = true,
	official = true,
	roblox = true,
	support = true,
	owner = true,
	staff = true,
	dev = true,
	developer = true,
	null = true,
	undefined = true,
}

Config.StarterItems = {
	"skin_void",
	"hair_short",
	"face_neutral",
	"shirt_core",
	"pants_core",
	"hat_none",
	"acc_none",
	"back_none",
	"fx_none",
}

Config.DefaultEquipped = {
	skin = "skin_void",
	hair = "hair_short",
	face = "face_neutral",
	shirt = "shirt_core",
	pants = "pants_core",
	hat = "hat_none",
	accessory = "acc_none",
	back = "back_none",
	effect = "fx_none",
}

Config.DefaultAvatar = {
	skin = "skin_void",
	hair = "hair_short",
	face = "face_neutral",
	shirt = "shirt_core",
	pants = "pants_core",
	hat = "hat_none",
	accessory = "acc_none",
	back = "back_none",
	effect = "fx_none",
	skinTone = { 0.55, 0.42, 0.34 },
}

Config.Sounds = {
	Click = "rbxasset://sounds/switch.mp3",
	Hover = "rbxasset://sounds/electronicpingshort.wav",
	Open = "rbxasset://sounds/action_get_up.mp3",
	Close = "rbxasset://sounds/action_jump.mp3",
	Success = "rbxasset://sounds/action_get_up.mp3",
	Error = "rbxasset://sounds/action_jump.mp3",
	Reward = "rbxasset://sounds/impact_water.mp3",
	Notification = "rbxasset://sounds/electronicpingshort.wav",
	Boot = "rbxasset://sounds/switch.mp3",
	Music = "", -- set a licensed rbxassetid:// here when you have one
}

Config.Products = {
	-- Example: { productId = 0, coins = 500, label = "Stack of VoidCoins" }
} :: { { productId: number, coins: number, label: string } }

Config.TeleportEnabled = true

Config.DefaultSettings = {
	uiScale = 1,
	reduceMotion = false,
	notificationsEnabled = true,
	masterVolume = 0.85,
	musicVolume = 0.45,
	uiVolume = 0.7,
	gameVolume = 0.8,
	effects = true,
	particles = true,
	performanceMode = false,
	cameraShake = false,
	shiftLock = false,
	highContrast = false,
	largeText = false,
	colorblindFriendly = false,
}

Config.Categories = {
	"Adventure",
	"Obby",
	"Simulator",
	"Racing",
	"Combat",
	"Horror",
	"Roleplay",
	"Tycoon",
	"Survival",
	"Social",
	"Collection",
	"Party",
	"Strategy",
}

Config.MatchOrigin = { 0, 320, 4800 }
Config.DailyReward = 50
Config.DailyStreakBonus = 15
Config.QuestRewardCap = 400

return table.freeze(Config)
