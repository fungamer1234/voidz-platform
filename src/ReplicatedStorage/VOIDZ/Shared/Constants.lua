--!strict

local Constants = {}

Constants.PAGES = {
	Home = "Home",
	Discover = "Discover",
	Avatar = "Avatar",
	Inventory = "Inventory",
	Friends = "Friends",
	Profile = "Profile",
	Settings = "Settings",
	Game = "Game",
	Search = "Search",
	Notifications = "Notifications",
}

Constants.NAV_ORDER = {
	"Home",
	"Discover",
	"Avatar",
	"Inventory",
	"Friends",
	"Profile",
	"Settings",
}

Constants.NAV_LABELS = {
	Home = "Home",
	Discover = "Discover",
	Avatar = "Avatar",
	Inventory = "Inventory",
	Friends = "Friends",
	Profile = "Profile",
	Settings = "Settings",
}

Constants.NAV_GLYPHS = {
	Home = "◆",
	Discover = "▣",
	Avatar = "◈",
	Inventory = "▤",
	Friends = "◎",
	Profile = "◉",
	Settings = "◍",
}

Constants.NOTIFICATION_TYPES = {
	Reward = "Reward",
	Friend = "Friend",
	Achievement = "Achievement",
	System = "System",
	Game = "Game",
	Currency = "Currency",
	Welcome = "Welcome",
}

Constants.SLOTS = {
	"skin",
	"hair",
	"face",
	"shirt",
	"pants",
	"hat",
	"accessory",
	"back",
	"effect",
}

Constants.SLOT_LABELS = {
	skin = "Skin",
	hair = "Hair",
	face = "Face",
	shirt = "Shirt",
	pants = "Pants",
	hat = "Hat",
	accessory = "Accessory",
	back = "Back",
	effect = "Effect",
}

Constants.RATE_LIMITS = {
	default = { tokens = 8, refill = 4 },
	PlayGame = { tokens = 3, refill = 1 },
	CompleteOnboarding = { tokens = 2, refill = 0.2 },
	SetDisplayName = { tokens = 3, refill = 0.5 },
	PurchaseItem = { tokens = 6, refill = 2 },
	FriendRequest = { tokens = 5, refill = 1 },
	SearchPlayers = { tokens = 6, refill = 2 },
	AdminCommand = { tokens = 10, refill = 4 },
	ToggleLike = { tokens = 8, refill = 4 },
	ToggleFavorite = { tokens = 8, refill = 4 },
	MatchAction = { tokens = 20, refill = 14 },
	LeaveMatch = { tokens = 6, refill = 2 },
	PlayAgain = { tokens = 4, refill = 1 },
	PartyInvite = { tokens = 6, refill = 2 },
	ClaimDaily = { tokens = 2, refill = 0.2 },
}

Constants.ERRORS = {
	RATE_LIMIT = "Please wait a moment and try again.",
	INVALID = "That request was invalid.",
	NOT_OWNED = "You don't own that item.",
	CANNOT_AFFORD = "Not enough VoidCoins.",
	NAME_TAKEN = "That name is already taken.",
	NAME_RESERVED = "That name is reserved.",
	NAME_INVALID = "Use 3-16 letters, numbers, or underscores.",
	NOT_ONBOARDED = "Finish setup first.",
	ALREADY_ONBOARDED = "Your profile already exists.",
	COMING_SOON = "This game is coming soon.",
	MAINTENANCE = "VOIDZ is in maintenance.",
	LOAD_FAILED = "Couldn't load your profile. Please retry.",
	SAVE_FAILED = "Couldn't save right now. We'll keep trying.",
	NOT_DEV = "You don't have permission to do that.",
	NOT_FOUND = "Not found.",
	ALREADY_OWNED = "You already own this.",
	SESSION = "Your session is not ready yet.",
	IN_MATCH = "You're already in a match.",
	MATCH_FULL = "That match is full.",
	DAILY_CLAIMED = "You already claimed today's drop.",
}

return table.freeze(Constants)
