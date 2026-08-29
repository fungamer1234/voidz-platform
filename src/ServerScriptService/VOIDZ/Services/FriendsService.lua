--!strict

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VOIDZ = ReplicatedStorage:WaitForChild("VOIDZ")
local Config = require(VOIDZ.Shared.Config)
local Constants = require(VOIDZ.Shared.Constants)
local Utility = require(VOIDZ.Shared.Utility)

local DataService = require(script.Parent.DataService)
local NotificationService = require(script.Parent.NotificationService)
local AchievementService = require(script.Parent.AchievementService)

local FriendsService = {}

type Graph = {
	incoming: { [string]: number },
	outgoing: { [string]: number },
	accepted: { [string]: number },
}

local store: DataStore? = nil
local memory: { [number]: Graph } = {}

local function empty(): Graph
	return { incoming = {}, outgoing = {}, accepted = {} }
end

function FriendsService.Init()
	local ok, s = pcall(function()
		return DataStoreService:GetDataStore(Config.FriendsStoreName)
	end)
	if ok then
		store = s
	end
end

local function uidKey(n: number): string
	return tostring(n)
end

local function loadGraph(userId: number): Graph
	if memory[userId] then
		return memory[userId]
	end
	if store then
		local ok, raw = pcall(function()
			return (store :: DataStore):GetAsync("f_" .. userId)
		end)
		if ok and type(raw) == "table" then
			local g = empty()
			if type(raw.incoming) == "table" then
				g.incoming = raw.incoming
			end
			if type(raw.outgoing) == "table" then
				g.outgoing = raw.outgoing
			end
			if type(raw.accepted) == "table" then
				g.accepted = raw.accepted
			end
			memory[userId] = g
			return g
		end
	end
	memory[userId] = empty()
	return memory[userId]
end

local function saveGraph(userId: number)
	local g = memory[userId]
	if not g then
		return
	end
	if store then
		task.spawn(function()
			pcall(function()
				(store :: DataStore):SetAsync("f_" .. userId, g)
			end)
		end)
	end
end

local function countAccepted(g: Graph): number
	local n = 0
	for _ in g.accepted do
		n += 1
	end
	return n
end

local function syncStat(player: Player)
	local data = DataService.GetData(player)
	if data then
		data.stats.friends = countAccepted(loadGraph(player.UserId))
		DataService.MarkDirty(player)
	end
end

local function robloxFriends(player: Player): { any }
	local out = {}
	local ok, pages = pcall(function()
		return Players:GetFriendsAsync(player.UserId)
	end)
	if not ok or not pages then
		return out
	end
	local safety = 0
	while true do
		safety += 1
		if safety > 8 then
			break
		end
		for _, item in pages:GetCurrentPage() do
			local id = item.Id or item.id
			if type(id) == "number" then
				local online = Players:GetPlayerByUserId(id) ~= nil
				table.insert(out, {
					userId = id,
					name = item.Username or item.username or "Player",
					displayName = item.DisplayName or item.displayName or item.Username or "Player",
					online = online,
					source = "roblox",
				})
			end
		end
		if pages.IsFinished then
			break
		end
		local advOk = pcall(function()
			pages:AdvanceToNextPageAsync()
		end)
		if not advOk then
			break
		end
	end
	return out
end

local function resolveName(userId: number): (string, string)
	local p = Players:GetPlayerByUserId(userId)
	if p then
		local dn = p:GetAttribute("VOIDZ_DisplayName")
		return p.Name, if type(dn) == "string" and dn ~= "" then dn else p.DisplayName
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	if ok and type(name) == "string" then
		return name, name
	end
	return "Player", "Player"
end

function FriendsService.Get(player: Player): any
	local g = loadGraph(player.UserId)
	local function map(bucket: { [string]: number }, status: string): { any }
		local list = {}
		for sid, at in bucket do
			local id = tonumber(sid)
			if id then
				local name, dn = resolveName(id)
				table.insert(list, {
					userId = id,
					name = name,
					displayName = dn,
					at = at,
					online = Players:GetPlayerByUserId(id) ~= nil,
					status = status,
					source = "voidz",
				})
			end
		end
		return list
	end
	return {
		ok = true,
		voidz = {
			accepted = map(g.accepted, "accepted"),
			incoming = map(g.incoming, "incoming"),
			outgoing = map(g.outgoing, "outgoing"),
		},
		roblox = robloxFriends(player),
		server = (function()
			local list = {}
			for _, p in Players:GetPlayers() do
				if p ~= player then
					local dn = p:GetAttribute("VOIDZ_DisplayName")
					table.insert(list, {
						userId = p.UserId,
						name = p.Name,
						displayName = if type(dn) == "string" and dn ~= "" then dn else p.DisplayName,
						online = true,
						source = "server",
					})
				end
			end
			return list
		end)(),
	}
end

function FriendsService.Request(player: Player, targetId: any): any
	if type(targetId) ~= "number" or targetId == player.UserId or targetId <= 0 then
		return { ok = false, error = Constants.ERRORS.INVALID }
	end
	local me = loadGraph(player.UserId)
	local them = loadGraph(targetId)
	local mk = uidKey(targetId)
	local tk = uidKey(player.UserId)
	if me.accepted[mk] then
		return { ok = false, error = "Already friends." }
	end
	if me.outgoing[mk] then
		return { ok = true, pending = true }
	end
	-- If they already requested us, auto-accept.
	if me.incoming[mk] then
		return FriendsService.Respond(player, targetId, true)
	end
	me.outgoing[mk] = os.time()
	them.incoming[tk] = os.time()
	saveGraph(player.UserId)
	saveGraph(targetId)
	local target = Players:GetPlayerByUserId(targetId)
	if target then
		NotificationService.Push(target, "Friend", "Friend request", player.DisplayName .. " wants to be friends on VOIDZ.")
	end
	return { ok = true, pending = true }
end

function FriendsService.Respond(player: Player, fromId: any, accept: any): any
	if type(fromId) ~= "number" then
		return { ok = false, error = Constants.ERRORS.INVALID }
	end
	local me = loadGraph(player.UserId)
	local them = loadGraph(fromId)
	local mk = uidKey(fromId)
	local tk = uidKey(player.UserId)
	if not me.incoming[mk] then
		return { ok = false, error = "No request from that player." }
	end
	me.incoming[mk] = nil
	them.outgoing[tk] = nil
	if accept == true then
		me.accepted[mk] = os.time()
		them.accepted[tk] = os.time()
	end
	saveGraph(player.UserId)
	saveGraph(fromId)
	syncStat(player)
	local other = Players:GetPlayerByUserId(fromId)
	if other then
		syncStat(other)
		if accept == true then
			NotificationService.Push(other, "Friend", "Request accepted", player.DisplayName .. " accepted your friend request.")
			AchievementService.Evaluate(other)
		end
	end
	if accept == true then
		AchievementService.Evaluate(player)
	end
	return FriendsService.Get(player)
end

function FriendsService.Remove(player: Player, otherId: any): any
	if type(otherId) ~= "number" then
		return { ok = false, error = Constants.ERRORS.INVALID }
	end
	local me = loadGraph(player.UserId)
	local them = loadGraph(otherId)
	local mk = uidKey(otherId)
	local tk = uidKey(player.UserId)
	me.accepted[mk] = nil
	me.incoming[mk] = nil
	me.outgoing[mk] = nil
	them.accepted[tk] = nil
	them.incoming[tk] = nil
	them.outgoing[tk] = nil
	saveGraph(player.UserId)
	saveGraph(otherId)
	syncStat(player)
	local other = Players:GetPlayerByUserId(otherId)
	if other then
		syncStat(other)
	end
	return FriendsService.Get(player)
end

function FriendsService.Search(player: Player, query: any): any
	if type(query) ~= "string" then
		return { ok = false, error = Constants.ERRORS.INVALID }
	end
	local q = string.lower(string.gsub(query, "^%s+", ""))
	q = string.gsub(q, "%s+$", "")
	if #q < 2 or #q > 24 then
		return { ok = true, results = {} }
	end
	local results = {}
	for _, p in Players:GetPlayers() do
		if p ~= player then
			local dn = p:GetAttribute("VOIDZ_DisplayName")
			local hay = string.lower(p.Name .. " " .. p.DisplayName .. " " .. (if type(dn) == "string" then dn else ""))
			if string.find(hay, q, 1, true) then
				table.insert(results, {
					userId = p.UserId,
					name = p.Name,
					displayName = if type(dn) == "string" and dn ~= "" then dn else p.DisplayName,
					online = true,
					source = "server",
				})
			end
		end
	end
	return { ok = true, results = results }
end

return FriendsService
