--!strict
--[[
	Authoritative player persistence.
	Rules:
	- Never overwrite a loaded profile with a blank default after a failed read.
	- Session-only memory fallback when DataStores are unavailable (Studio without API).
	- Serialized saves per player; BindToClose flushes everyone.
]]

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VOIDZ = ReplicatedStorage:WaitForChild("VOIDZ")
local Config = require(VOIDZ.Shared.Config)
local Utility = require(VOIDZ.Shared.Utility)

local DataService = {}

export type Live = {
	data: any,
	loaded: boolean,
	loadFailed: boolean,
	token: string,
	dirty: boolean,
	saving: boolean,
	fallback: boolean,
	lastSave: number,
}

local live: { [number]: Live } = {}
local memoryStore: { [string]: any } = {}
local loading: { [number]: boolean } = {}
local playerStore: DataStore? = nil
local usingApi = true
local closing = false

local function defaultData(): any
	return {
		version = Config.DataVersion,
		onboarded = false,
		profile = {
			displayName = "",
			createdAt = os.time(),
			lastLogin = os.time(),
			bio = "",
			nameChangedAt = 0,
		},
		currency = {
			VoidCoins = 0,
		},
		inventory = {
			items = {},
			equipped = Utility.deepCopy(Config.DefaultEquipped),
		},
		avatar = {
			skinTone = Utility.deepCopy(Config.DefaultAvatar.skinTone),
		},
		settings = Utility.deepCopy(Config.DefaultSettings),
		favorites = {},
		likes = {},
		recentlyPlayed = {},
		stats = {
			gamesPlayed = 0,
			playClicks = 0,
			logins = 0,
			itemsOwned = 0,
			friends = 0,
			timePlayed = 0,
			distinctGames = {},
			transactions = {},
		},
		achievements = {},
		notifications = {},
		gameStats = {},
		quests = {},
		daily = { lastClaim = 0, streak = 0 },
		_session = nil,
	}
end

local function migrate(data: any): any
	if type(data) ~= "table" then
		return defaultData()
	end
	local base = defaultData()
	Utility.deepMerge(base, data)
	base.version = Config.DataVersion
	if type(base.inventory.equipped) ~= "table" then
		base.inventory.equipped = Utility.deepCopy(Config.DefaultEquipped)
	end
	-- equipped table may contain skinTone leftover — strip unknown slots later in AvatarService
	return base
end

local function initStore()
	local ok, store = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStoreName)
	end)
	if ok and store then
		playerStore = store
		usingApi = true
	else
		playerStore = nil
		usingApi = false
		warn("[VOIDZ] DataStores unavailable. Using session memory. Enable Studio API access to persist.")
	end
end

function DataService.UsingFallback(): boolean
	return not usingApi
end

function DataService.GetLive(player: Player): Live?
	return live[player.UserId]
end

function DataService.GetData(player: Player): any?
	local l = live[player.UserId]
	if l and l.loaded and not l.loadFailed then
		return l.data
	end
	return nil
end

function DataService.MarkDirty(player: Player)
	local l = live[player.UserId]
	if l and l.loaded then
		l.dirty = true
	end
end

local function keyFor(userId: number): string
	return "u_" .. tostring(userId)
end

local function readRaw(userId: number): (boolean, any, string?)
	local key = keyFor(userId)
	if not usingApi or not playerStore then
		return true, memoryStore[key], "memory"
	end
	local ok, result = Utility.pcallRetry(Config.DataRetries, Config.DataRetryBaseDelay, function()
		return playerStore:GetAsync(key)
	end)
	if not ok then
		-- Studio without API often errors here — fall back for this session, never invent a save over cloud.
		if RunService:IsStudio() then
			usingApi = false
			warn("[VOIDZ] GetAsync failed in Studio; session memory only.", result)
			return true, memoryStore[key], "memory"
		end
		return false, nil, tostring(result)
	end
	return true, result, "cloud"
end

local function writeRaw(userId: number, data: any): boolean
	local key = keyFor(userId)
	if not usingApi or not playerStore then
		memoryStore[key] = Utility.deepCopy(data)
		return true
	end
	local payload = Utility.deepCopy(data)
	local ok, err = Utility.pcallRetry(Config.DataRetries, Config.DataRetryBaseDelay, function()
		playerStore:UpdateAsync(key, function(old)
			-- Do not clobber a newer session blindly; last-write from this live session is source of truth
			-- while the player is in this server.
			return payload
		end)
	end)
	if not ok then
		warn("[VOIDZ] Save failed", userId, err)
		return false
	end
	return true
end

function DataService.Load(player: Player): (boolean, string?)
	local uid = player.UserId
	if live[uid] and live[uid].loaded then
		return true, nil
	end
	local spin = 0
	while loading[uid] do
		task.wait(0.05)
		spin += 1
		if spin > 200 then
			break
		end
		if live[uid] and live[uid].loaded then
			return true, nil
		end
	end
	if live[uid] and live[uid].loaded then
		return true, nil
	end
	loading[uid] = true
	local ok, raw, src = readRaw(uid)
	if not ok then
		live[uid] = {
			data = nil,
			loaded = false,
			loadFailed = true,
			token = "",
			dirty = false,
			saving = false,
			fallback = false,
			lastSave = 0,
		}
		loading[uid] = nil
		return false, "load"
	end
	local data
	if raw == nil then
		data = defaultData()
		data.profile.displayName = ""
	else
		data = migrate(raw)
	end
	data.profile.lastLogin = os.time()
	data.stats.logins = (data.stats.logins or 0) + 1
	data._session = {
		token = HttpService:GenerateGUID(false),
		jobId = game.JobId,
		at = os.time(),
	}
	live[uid] = {
		data = data,
		loaded = true,
		loadFailed = false,
		token = data._session.token,
		dirty = true,
		saving = false,
		fallback = src == "memory",
		lastSave = 0,
	}
	loading[uid] = nil
	return true, src
end

function DataService.Save(player: Player): boolean
	local l = live[player.UserId]
	if not l or not l.loaded or l.loadFailed then
		return false
	end
	if l.saving then
		return true
	end
	l.saving = true
	local snapshot = Utility.deepCopy(l.data)
	local ok = writeRaw(player.UserId, snapshot)
	l.saving = false
	if ok then
		l.dirty = false
		l.lastSave = os.clock()
	end
	return ok
end

function DataService.Release(player: Player)
	local l = live[player.UserId]
	if not l then
		return
	end
	if l.loaded and not l.loadFailed then
		DataService.Save(player)
	end
	live[player.UserId] = nil
end

function DataService.Init()
	initStore()
	Players.PlayerRemoving:Connect(function(player)
		DataService.Release(player)
	end)
	game:BindToClose(function()
		closing = true
		local jobs = {}
		for _, player in Players:GetPlayers() do
			table.insert(jobs, task.spawn(function()
				DataService.Release(player)
			end))
		end
		local t0 = os.clock()
		while os.clock() - t0 < (RunService:IsStudio() and 3 or 20) do
			local anyLive = false
			for _, l in live do
				if l.saving then
					anyLive = true
					break
				end
			end
			if not anyLive then
				break
			end
			task.wait(0.2)
		end
	end)
	task.spawn(function()
		while not closing do
			task.wait(Config.SaveInterval)
			for _, player in Players:GetPlayers() do
				local l = live[player.UserId]
				if l and l.dirty and l.loaded then
					DataService.Save(player)
				end
			end
		end
	end)
end

return DataService
