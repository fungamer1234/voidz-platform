--!strict
--[[
	VOIDZ game library. InPlace = true means Play launches a real match in this place.
	Set PlaceId later to split a title into its own Roblox place; MatchService still works
	if you parent the same Games/Modes module in that place.
]]

export type GameDef = {
	Id: string,
	Name: string,
	Description: string,
	Category: string,
	MaxPlayers: number,
	PlaceId: number,
	InPlace: boolean,
	Creator: string,
	Featured: boolean,
	SeedPopularity: number,
	Accent: { number },
	Accent2: { number },
	Tagline: string,
	Release: string,
}

local GAMES: { GameDef } = {
	{
		Id = "brain_snatch",
		Name = "Brain Snatch",
		Description = "Hunt wandering Brains, bank them in your vault, and steal whatever your rivals are carrying. Locks, rare Brains, and chaos events keep the floor moving.",
		Category = "Collection",
		MaxPlayers = 16,
		PlaceId = 0,
		InPlace = true,
		Creator = "VOIDZ Studios",
		Featured = true,
		SeedPopularity = 22100,
		Accent = { 0.95, 0.28, 0.55 },
		Accent2 = { 0.45, 0.2, 1 },
		Tagline = "Grab it. Bank it. Lose it.",
		Release = "Live",
	},
	{
		Id = "chaos_obby",
		Name = "Chaos Obby",
		Description = "A checkpoint race that rewrites the rules every round. Low gravity, ice, exploding tiles, reverse controls — finish before the timer does.",
		Category = "Obby",
		MaxPlayers = 20,
		PlaceId = 0,
		InPlace = true,
		Creator = "VOIDZ Studios",
		Featured = true,
		SeedPopularity = 19840,
		Accent = { 0.35, 0.85, 1 },
		Accent2 = { 1, 0.45, 0.2 },
		Tagline = "The course has opinions.",
		Release = "Live",
	},
	{
		Id = "last_one_alive",
		Name = "Last One Alive",
		Description = "One life. An arena that keeps changing. Meteors, floods, lightning, and worse. The last player standing takes the round.",
		Category = "Survival",
		MaxPlayers = 20,
		PlaceId = 0,
		InPlace = true,
		Creator = "VOIDZ Studios",
		Featured = true,
		SeedPopularity = 18750,
		Accent = { 1, 0.35, 0.2 },
		Accent2 = { 0.2, 0.12, 0.16 },
		Tagline = "Don't be the story.",
		Release = "Live",
	},
	{
		Id = "street_racers",
		Name = "Street Racers",
		Description = "Kart-speed circuits with checkpoints, laps, boost, and drift. Positions update live. First across after three laps wins.",
		Category = "Racing",
		MaxPlayers = 12,
		PlaceId = 0,
		InPlace = true,
		Creator = "VOIDZ Studios",
		Featured = true,
		SeedPopularity = 17400,
		Accent = { 0.2, 0.7, 1 },
		Accent2 = { 1, 0.8, 0.2 },
		Tagline = "Hold boost. Hit the apex.",
		Release = "Live",
	},
	{
		Id = "base_rush",
		Name = "Base Rush",
		Description = "Your plot prints VoidCoins. Upgrade droppers, lock the vault, buy a blade, and raid the neighbor who got greedy.",
		Category = "Tycoon",
		MaxPlayers = 8,
		PlaceId = 0,
		InPlace = true,
		Creator = "VOIDZ Studios",
		Featured = false,
		SeedPopularity = 16220,
		Accent = { 0.25, 0.9, 0.55 },
		Accent2 = { 0.9, 0.7, 0.2 },
		Tagline = "Print. Fortify. Steal.",
		Release = "Live",
	},
	{
		Id = "haunted_shift",
		Name = "Haunted Shift",
		Description = "A night shift in a building that hunts you. Finish terminals, hide, revive, and run the exit while a pathfinding stalker listens.",
		Category = "Horror",
		MaxPlayers = 10,
		PlaceId = 0,
		InPlace = true,
		Creator = "VOIDZ Studios",
		Featured = false,
		SeedPopularity = 16990,
		Accent = { 0.55, 0.08, 0.12 },
		Accent2 = { 0.15, 0.12, 0.18 },
		Tagline = "Clock out alive.",
		Release = "Live",
	},
	{
		Id = "pet_planet",
		Name = "Pet Planet",
		Description = "Buy eggs, hatch followers, and farm zones with a multiplier on your back. Pets actually idle, run, and stick to you.",
		Category = "Simulator",
		MaxPlayers = 16,
		PlaceId = 0,
		InPlace = true,
		Creator = "VOIDZ Studios",
		Featured = false,
		SeedPopularity = 20550,
		Accent = { 1, 0.5, 0.75 },
		Accent2 = { 0.45, 0.85, 1 },
		Tagline = "Hatch something clingy.",
		Release = "Live",
	},
	{
		Id = "tower_clash",
		Name = "Tower Clash",
		Description = "Two lanes, two cores. Spend income on units that march, and swing if you want the push yourself. First core to zero loses.",
		Category = "Strategy",
		MaxPlayers = 12,
		PlaceId = 0,
		InPlace = true,
		Creator = "VOIDZ Studios",
		Featured = false,
		SeedPopularity = 14110,
		Accent = { 0.95, 0.55, 0.2 },
		Accent2 = { 0.25, 0.45, 1 },
		Tagline = "Hold the core.",
		Release = "Live",
	},
	{
		Id = "grab_and_go",
		Name = "Grab & Go",
		Description = "Valuables drop around the yard. Carry them to extract before someone tags you and takes the bag. Dash when it gets rude.",
		Category = "Party",
		MaxPlayers = 16,
		PlaceId = 0,
		InPlace = true,
		Creator = "VOIDZ Studios",
		Featured = false,
		SeedPopularity = 15880,
		Accent = { 0.95, 0.8, 0.2 },
		Accent2 = { 0.2, 0.85, 0.55 },
		Tagline = "Heavy pockets, light feet.",
		Release = "Live",
	},
	{
		Id = "disaster_city",
		Name = "Disaster City",
		Description = "A small city that fails on a schedule. Earthquakes, floods, meteors, blackouts. Survive the clock. NPCs run the same streets you do.",
		Category = "Survival",
		MaxPlayers = 20,
		PlaceId = 0,
		InPlace = true,
		Creator = "VOIDZ Studios",
		Featured = false,
		SeedPopularity = 17640,
		Accent = { 0.7, 0.75, 0.85 },
		Accent2 = { 1, 0.4, 0.15 },
		Tagline = "The skyline is temporary.",
		Release = "Live",
	},
	{
		Id = "sword_arena",
		Name = "Sword Arena",
		Description = "Server-authoritative melee: range, facing, cooldown, block, knockback. Kills and deaths are tracked. Training dummies swing back.",
		Category = "Combat",
		MaxPlayers = 16,
		PlaceId = 0,
		InPlace = true,
		Creator = "VOIDZ Studios",
		Featured = true,
		SeedPopularity = 19300,
		Accent = { 0.85, 0.85, 0.92 },
		Accent2 = { 0.75, 0.15, 0.2 },
		Tagline = "Read the swing.",
		Release = "Live",
	},
	{
		Id = "hideout",
		Name = "Hideout",
		Description = "One seeker, a building full of lockers and corners, a ticking clock. Tag everyone — or stay unseen until the horn.",
		Category = "Social",
		MaxPlayers = 16,
		PlaceId = 0,
		InPlace = true,
		Creator = "VOIDZ Studios",
		Featured = false,
		SeedPopularity = 15120,
		Accent = { 0.4, 0.55, 1 },
		Accent2 = { 0.15, 0.16, 0.22 },
		Tagline = "Don't blink first.",
		Release = "Live",
	},
	{
		Id = "sky_is_falling",
		Name = "Sky Is Falling",
		Description = "Floating islands drop out of the match one by one. Jump, shove, and stay on whatever is still there. Last player who isn't falling wins.",
		Category = "Survival",
		MaxPlayers = 16,
		PlaceId = 0,
		InPlace = true,
		Creator = "VOIDZ Studios",
		Featured = false,
		SeedPopularity = 14890,
		Accent = { 0.55, 0.8, 1 },
		Accent2 = { 0.95, 0.55, 0.3 },
		Tagline = "The floor has a queue.",
		Release = "Live",
	},
	{
		Id = "build_battle",
		Name = "Build Battle",
		Description = "A theme, a grid, a timer. Place, rotate, delete. Then everyone votes — you can't vote for yourself. Winner takes the purse.",
		Category = "Social",
		MaxPlayers = 8,
		PlaceId = 0,
		InPlace = true,
		Creator = "VOIDZ Studios",
		Featured = false,
		SeedPopularity = 13250,
		Accent = { 0.55, 0.95, 0.7 },
		Accent2 = { 0.7, 0.45, 1 },
		Tagline = "Make it obvious.",
		Release = "Live",
	},
	{
		Id = "lucky_world",
		Name = "Lucky World",
		Description = "Server-rolled drops: coins, speed, pets, jackpots. Cooldowns and caps keep it a game, not a cashier. No Robux rolls.",
		Category = "Collection",
		MaxPlayers = 16,
		PlaceId = 0,
		InPlace = true,
		Creator = "VOIDZ Studios",
		Featured = false,
		SeedPopularity = 18880,
		Accent = { 1, 0.75, 0.25 },
		Accent2 = { 0.5, 0.3, 1 },
		Tagline = "Spin the honest wheel.",
		Release = "Live",
	},
}

local byId: { [string]: GameDef } = {}
for _, g in GAMES do
	if byId[g.Id] then
		error("[VOIDZ] Duplicate game id: " .. g.Id)
	end
	byId[g.Id] = g
end

local GameRegistry = {}

function GameRegistry.GetAll(): { GameDef }
	return GAMES
end

function GameRegistry.Get(id: string): GameDef?
	return byId[id]
end

function GameRegistry.GetFeatured(): { GameDef }
	local out = {}
	for _, g in GAMES do
		if g.Featured then
			table.insert(out, g)
		end
	end
	return out
end

function GameRegistry.GetByCategory(category: string): { GameDef }
	local out = {}
	for _, g in GAMES do
		if g.Category == category then
			table.insert(out, g)
		end
	end
	return out
end

function GameRegistry.Search(query: string): { GameDef }
	local q = string.lower(query or "")
	q = string.gsub(q, "^%s+", "")
	q = string.gsub(q, "%s+$", "")
	if q == "" then
		return GAMES
	end
	local out = {}
	for _, g in GAMES do
		local hay = string.lower(g.Name .. " " .. g.Category .. " " .. g.Creator .. " " .. g.Tagline .. " " .. g.Description)
		if string.find(hay, q, 1, true) then
			table.insert(out, g)
		end
	end
	return out
end

function GameRegistry.IsPlayable(id: string): boolean
	local g = byId[id]
	if not g then
		return false
	end
	if g.InPlace then
		return true
	end
	return type(g.PlaceId) == "number" and g.PlaceId > 0
end

function GameRegistry.IsInPlace(id: string): boolean
	local g = byId[id]
	return g ~= nil and g.InPlace == true
end

function GameRegistry.AccentColor(g: GameDef): Color3
	return Color3.new(g.Accent[1], g.Accent[2], g.Accent[3])
end

function GameRegistry.Accent2Color(g: GameDef): Color3
	return Color3.new(g.Accent2[1], g.Accent2[2], g.Accent2[3])
end

function GameRegistry.Mark(g: GameDef): string
	local n = string.gsub(g.Name, "[^%a]", "")
	return string.upper(string.sub(n, 1, 2))
end

return GameRegistry
