--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VOIDZ = ReplicatedStorage:WaitForChild("VOIDZ")

local DataService = require(script.Parent.DataService)
local CurrencyService = require(script.Parent.CurrencyService)
local AchievementService = require(script.Parent.AchievementService)
local NotificationService = require(script.Parent.NotificationService)

local RewardService = {}

local granted: { [string]: boolean } = {}

local function gs(data: any, gameId: string): any
	data.gameStats = data.gameStats or {}
	data.gameStats[gameId] = data.gameStats[gameId]
		or { plays = 0, wins = 0, kills = 0, deaths = 0, bestScore = 0, xp = 0, brains = 0, survives = 0, races = 0 }
	return data.gameStats[gameId]
end

function RewardService.Bump(player: Player, gameId: string, field: string, amount: number)
	local data = DataService.GetData(player)
	if not data then
		return
	end
	local s = gs(data, gameId)
	s[field] = (s[field] or 0) + amount
	if field == "wins" then
		data.stats.wins = (data.stats.wins or 0) + amount
	end
	DataService.MarkDirty(player)
end

function RewardService.MatchPayout(player: Player, info: {
	matchId: string,
	gameId: string,
	score: number,
	won: boolean,
	placement: number,
	coins: number,
	xp: number,
	kills: number?,
}): { coins: number, xp: number, already: boolean }
	local key = info.matchId .. ":" .. player.UserId
	if granted[key] then
		return { coins = 0, xp = 0, already = true }
	end
	granted[key] = true
	local data = DataService.GetData(player)
	if not data then
		return { coins = 0, xp = 0, already = false }
	end
	local coins = math.clamp(math.floor(info.coins), 0, 500)
	local xp = math.clamp(math.floor(info.xp), 0, 400)
	if coins > 0 then
		CurrencyService.Add(player, coins, "match:" .. info.gameId)
	end
	local s = gs(data, info.gameId)
	s.plays += 1
	s.xp += xp
	s.bestScore = math.max(s.bestScore or 0, info.score or 0)
	if info.won then
		s.wins += 1
		data.stats.wins = (data.stats.wins or 0) + 1
		AchievementService.Unlock(player, "first_win")
		if (data.stats.wins or 0) >= 5 then
			AchievementService.Unlock(player, "champion")
		end
	end
	if info.kills then
		s.kills += info.kills
	end
	data.stats.gamesPlayed = (data.stats.gamesPlayed or 0) + 1
	DataService.MarkDirty(player)
	AchievementService.Evaluate(player)
	NotificationService.Push(
		player,
		"Reward",
		if info.won then "Match won" else "Match payout",
		tostring(coins) .. " VC  ·  " .. tostring(xp) .. " XP"
	)
	return { coins = coins, xp = xp, already = false }
end

function RewardService.GetStats(player: Player, gameId: string): any
	local data = DataService.GetData(player)
	if not data then
		return {}
	end
	return gs(data, gameId)
end

return RewardService
