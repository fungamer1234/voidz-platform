--!strict

local DataStoreService = game:GetService("DataStoreService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VOIDZ = ReplicatedStorage:WaitForChild("VOIDZ")
local Config = require(VOIDZ.Shared.Config)
local Constants = require(VOIDZ.Shared.Constants)
local GameRegistry = require(VOIDZ.Shared.GameRegistry)
local Utility = require(VOIDZ.Shared.Utility)

local DataService = require(script.Parent.DataService)
local NotificationService = require(script.Parent.NotificationService)
local AchievementService = require(script.Parent.AchievementService)
local MatchService = require(script.Parent.MatchService)

local GameService = {}

local statsStore: DataStore? = nil
local statsCache: { [string]: { plays: number, likes: number, favorites: number } } = {}
local featuredOverride: { string }? = nil

local function emptyStat()
	return { plays = 0, likes = 0, favorites = 0 }
end

function GameService.Init()
	local ok, store = pcall(function()
		return DataStoreService:GetDataStore(Config.GameStatsStoreName)
	end)
	if ok then
		statsStore = store
	end
	for _, g in GameRegistry.GetAll() do
		statsCache[g.Id] = emptyStat()
		statsCache[g.Id].plays = g.SeedPopularity
	end
	if statsStore then
		task.spawn(function()
			for _, g in GameRegistry.GetAll() do
				local sOk, raw = pcall(function()
					return (statsStore :: DataStore):GetAsync("g_" .. g.Id)
				end)
				if sOk and type(raw) == "table" then
					statsCache[g.Id].plays = math.max(statsCache[g.Id].plays, tonumber(raw.plays) or 0)
					statsCache[g.Id].likes = tonumber(raw.likes) or 0
					statsCache[g.Id].favorites = tonumber(raw.favorites) or 0
				end
			end
		end)
	end
end

local function bump(id: string, field: string, delta: number)
	local s = statsCache[id]
	if not s then
		s = emptyStat()
		statsCache[id] = s
	end
	s[field] = math.max(0, (s[field] or 0) + delta)
	if statsStore then
		task.spawn(function()
			pcall(function()
				(statsStore :: DataStore):UpdateAsync("g_" .. id, function(old)
					local t = if type(old) == "table" then old else emptyStat()
					t[field] = math.max(0, (t[field] or 0) + delta)
					return t
				end)
			end)
		end)
	end
end

function GameService.GetLiveSnapshot(): any
	local out = {}
	for _, g in GameRegistry.GetAll() do
		local s = statsCache[g.Id] or emptyStat()
		out[g.Id] = {
			plays = s.plays,
			likes = s.likes,
			favorites = s.favorites,
			playable = GameRegistry.IsPlayable(g.Id),
			featured = if featuredOverride then Utility.includes(featuredOverride, g.Id) else g.Featured,
		}
	end
	out._lobbyPlayers = #Players:GetPlayers()
	return out
end

function GameService.SetFeatured(ids: { string })
	featuredOverride = ids
end

function GameService.ToggleFavorite(player: Player, gameId: any): any
	if type(gameId) ~= "string" or not GameRegistry.Get(gameId) then
		return { ok = false, error = Constants.ERRORS.NOT_FOUND }
	end
	local data = DataService.GetData(player)
	if not data then
		return { ok = false, error = Constants.ERRORS.SESSION }
	end
	data.favorites = data.favorites or {}
	local on = Utility.includes(data.favorites, gameId)
	if on then
		Utility.removeValue(data.favorites, gameId)
		bump(gameId, "favorites", -1)
	else
		table.insert(data.favorites, gameId)
		bump(gameId, "favorites", 1)
	end
	DataService.MarkDirty(player)
	return { ok = true, favorites = data.favorites, on = not on, live = GameService.GetLiveSnapshot() }
end

function GameService.ToggleLike(player: Player, gameId: any): any
	if type(gameId) ~= "string" or not GameRegistry.Get(gameId) then
		return { ok = false, error = Constants.ERRORS.NOT_FOUND }
	end
	local data = DataService.GetData(player)
	if not data then
		return { ok = false, error = Constants.ERRORS.SESSION }
	end
	data.likes = data.likes or {}
	local on = Utility.includes(data.likes, gameId)
	if on then
		Utility.removeValue(data.likes, gameId)
		bump(gameId, "likes", -1)
	else
		table.insert(data.likes, gameId)
		bump(gameId, "likes", 1)
	end
	DataService.MarkDirty(player)
	return { ok = true, likes = data.likes, on = not on, live = GameService.GetLiveSnapshot() }
end

function GameService.Play(player: Player, gameId: any): any
	if Config.MaintenanceMode then
		return { ok = false, error = Constants.ERRORS.MAINTENANCE }
	end
	if type(gameId) ~= "string" then
		return { ok = false, error = Constants.ERRORS.INVALID }
	end
	local g = GameRegistry.Get(gameId)
	if not g then
		return { ok = false, error = Constants.ERRORS.NOT_FOUND }
	end
	local data = DataService.GetData(player)
	if not data or not data.onboarded then
		return { ok = false, error = Constants.ERRORS.NOT_ONBOARDED }
	end
	data.stats.playClicks = (data.stats.playClicks or 0) + 1
	data.stats.distinctGames = data.stats.distinctGames or {}
	data.stats.distinctGames[gameId] = true
	Utility.prependUnique(data.recentlyPlayed, gameId, Config.MaxRecentlyPlayed)
	bump(gameId, "plays", 1)
	DataService.MarkDirty(player)
	AchievementService.Evaluate(player)

	if GameRegistry.IsInPlace(gameId) then
		data.stats.gamesPlayed = (data.stats.gamesPlayed or 0) + 1
		DataService.MarkDirty(player)
		return MatchService.Play(player, gameId)
	end

	if not GameRegistry.IsPlayable(gameId) or not Config.TeleportEnabled then
		NotificationService.Push(player, "Game", g.Name, "This title is listed on VOIDZ but isn't open yet. We'll notify you when it launches.")
		return { ok = false, error = Constants.ERRORS.COMING_SOON, comingSoon = true, name = g.Name }
	end

	data.stats.gamesPlayed = (data.stats.gamesPlayed or 0) + 1
	DataService.Save(player)

	local telOk, telErr = pcall(function()
		TeleportService:TeleportAsync(g.PlaceId, { player })
	end)
	if not telOk then
		warn("[VOIDZ] Teleport failed", telErr)
		return { ok = false, error = "Teleport failed. Try again in a moment." }
	end
	return { ok = true, teleporting = true }
end

return GameService
