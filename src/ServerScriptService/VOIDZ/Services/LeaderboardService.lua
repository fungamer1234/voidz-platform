--!strict

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VOIDZ = ReplicatedStorage:WaitForChild("VOIDZ")
local GameRegistry = require(VOIDZ.Shared.GameRegistry)

local LeaderboardService = {}

local memory: { [string]: { [number]: number } } = {}
local stores: { [string]: OrderedDataStore } = {}

local function store(gameId: string, field: string): OrderedDataStore?
	local key = gameId .. "_" .. field
	if stores[key] then
		return stores[key]
	end
	local ok, s = pcall(function()
		return DataStoreService:GetOrderedDataStore("VOIDZ_LB_" .. key)
	end)
	if ok then
		stores[key] = s
		return s
	end
	return nil
end

function LeaderboardService.Submit(gameId: string, userId: number, field: string, value: number)
	value = math.floor(math.max(0, value))
	local k = gameId .. "_" .. field
	memory[k] = memory[k] or {}
	memory[k][userId] = math.max(memory[k][userId] or 0, value)
	local ds = store(gameId, field)
	if ds then
		task.spawn(function()
			pcall(function()
				ds:SetAsync(tostring(userId), memory[k][userId])
			end)
		end)
	end
end

function LeaderboardService.Top(gameId: string, field: string, count: number): { any }
	count = math.clamp(count or 10, 1, 25)
	local ds = store(gameId, field)
	if ds and not RunService:IsStudio() then
		local ok, pages = pcall(function()
			return ds:GetSortedAsync(false, count)
		end)
		if ok and pages then
			local out = {}
			for _, e in pages:GetCurrentPage() do
				local uid = tonumber(e.key)
				local name = "Player"
				if uid then
					local pl = Players:GetPlayerByUserId(uid)
					if pl then
						name = pl.Name
					else
						pcall(function()
							name = Players:GetNameFromUserIdAsync(uid)
						end)
					end
				end
				table.insert(out, { userId = uid, name = name, value = e.value })
			end
			return out
		end
	end
	local k = gameId .. "_" .. field
	local rows = {}
	for uid, val in memory[k] or {} do
		local pl = Players:GetPlayerByUserId(uid)
		table.insert(rows, { userId = uid, name = if pl then pl.Name else "Player", value = val })
	end
	table.sort(rows, function(a, b)
		return a.value > b.value
	end)
	while #rows > count do
		table.remove(rows)
	end
	return rows
end

function LeaderboardService.Snapshot(gameId: string): any
	if not GameRegistry.Get(gameId) then
		return { ok = false }
	end
	return {
		ok = true,
		gameId = gameId,
		wins = LeaderboardService.Top(gameId, "wins", 10),
		score = LeaderboardService.Top(gameId, "score", 10),
	}
end

return LeaderboardService
