--!strict
--[[
	One concurrent match per server. Players who Play the same title during
	Lobby/Countdown join it (plus party members in this server).
	When PlaceId is set later, GameService still teleports; this host stays
	for in-place titles and dedicated-place copies of the same modules.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VOIDZ = ReplicatedStorage:WaitForChild("VOIDZ")
local Config = require(VOIDZ.Shared.Config)
local Constants = require(VOIDZ.Shared.Constants)
local GameRegistry = require(VOIDZ.Shared.GameRegistry)
local Utility = require(VOIDZ.Shared.Utility)

local DataService = require(script.Parent.DataService)
local RemoteService = require(script.Parent.RemoteService)
local PartyService = require(script.Parent.PartyService)
local RewardService = require(script.Parent.RewardService)
local QuestService = require(script.Parent.QuestService)
local LeaderboardService = require(script.Parent.LeaderboardService)
local AchievementService = require(script.Parent.AchievementService)
local MapUtil = require(script.Parent.Parent.Games.MapUtil)
local AIUtil = require(script.Parent.Parent.Games.AIUtil)
local CombatUtil = require(script.Parent.Parent.Games.CombatUtil)

local MatchService = {}

local modes: { [string]: any } = {}
local active: any = nil
local inMatch: { [number]: boolean } = {}
local heartbeat: RBXScriptConnection? = nil

local LOBBY_SPAWN = CFrame.new(0, 6, 8)

local function loadModes()
	local folder = script.Parent.Parent:FindFirstChild("Games")
	if not folder then
		return
	end
	local modeFolder = folder:FindFirstChild("Modes")
	if not modeFolder then
		return
	end
	for _, child in modeFolder:GetChildren() do
		if child:IsA("ModuleScript") then
			local ok, mod = pcall(require, child)
			if ok and type(mod) == "table" and type(mod.Id) == "string" then
				modes[mod.Id] = mod
			else
				warn("[VOIDZ] Bad mode", child.Name, mod)
			end
		end
	end
end

local function fireState(rt: any, player: Player?)
	local plist = {}
	for _, p in rt.players do
		if p.Parent then
			table.insert(plist, {
				userId = p.UserId,
				name = p.Name,
				score = rt.scores[p.UserId] or 0,
				alive = rt.alive[p.UserId] == true,
				team = rt.teams[p.UserId],
			})
		end
	end
	local payload = {
		matchId = rt.matchId,
		gameId = rt.gameId,
		name = rt.def.Name,
		phase = rt.phase,
		endsAt = rt.endsAt,
		serverNow = os.time(),
		objective = rt.objective,
		players = plist,
		actions = rt.mode.Actions or {},
		tips = rt.mode.Tips or {},
		extra = rt.publicExtra or {},
		accent = rt.def.Accent,
		accent2 = rt.def.Accent2,
	}
	if player then
		RemoteService.Fire("MatchState", player, payload)
	else
		for _, p in rt.players do
			if p.Parent then
				RemoteService.Fire("MatchState", p, payload)
			end
		end
	end
end

local function event(rt: any, payload: any)
	for _, p in rt.players do
		if p.Parent then
			RemoteService.Fire("MatchEvent", p, payload)
		end
	end
end

local function announce(rt: any, text: string)
	rt.objective = text
	event(rt, { kind = "sys", text = text })
	fireState(rt)
end

local function getSpawn(rt: any, i: number): CFrame
	local sp = rt.spawns
	if type(sp) == "table" and #sp > 0 then
		return sp[((i - 1) % #sp) + 1]
	end
	return CFrame.new(rt.origin + Vector3.new(0, 8, 0))
end

local function teleport(player: Player, cf: CFrame)
	local char = player.Character
	if not char then
		char = player.CharacterAdded:Wait()
	end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.CFrame = cf
	end
end

local function setLeaderstats(player: Player, score: number)
	local ls = player:FindFirstChild("leaderstats")
	if not ls then
		ls = Instance.new("Folder")
		ls.Name = "leaderstats"
		ls.Parent = player
	end
	local sc = ls:FindFirstChild("Score")
	if not sc then
		sc = Instance.new("IntValue")
		sc.Name = "Score"
		sc.Parent = ls
	end
	(sc :: IntValue).Value = score
end

local function restoreLobby(player: Player)
	inMatch[player.UserId] = nil
	player:SetAttribute("VOIDZ_Block", false)
	player:SetAttribute("VOIDZ_InMatch", false)
	teleport(player, LOBBY_SPAWN)
	RemoteService.Fire("MatchState", player, { phase = "Idle", gameId = "" })
end

local function lobbySpawn(on: boolean)
	local world = workspace:FindFirstChild("VOIDZ_World")
	local sp = world and world:FindFirstChild("VOIDZ_Spawn")
	if sp and sp:IsA("SpawnLocation") then
		sp.Enabled = on
		sp.Neutral = on
	end
end

local function cleanupMatch(rt: any)
	lobbySpawn(true)
	if heartbeat then
		heartbeat:Disconnect()
		heartbeat = nil
	end
	for _, c in rt.connections do
		pcall(function()
			c:Disconnect()
		end)
	end
	if rt.mode.Cleanup then
		pcall(rt.mode.Cleanup, rt)
	end
	AIUtil.clear()
	CombatUtil.clear()
	if rt.folder then
		rt.folder:Destroy()
	end
	active = nil
end

local function finish(rt: any, reason: string)
	if rt.phase == "Results" or rt.phase == "Idle" then
		return
	end
	rt.phase = "Results"
	rt.endsAt = os.time() + 12
	local rows = {}
	for _, p in rt.players do
		if p.Parent then
			table.insert(rows, { player = p, score = rt.scores[p.UserId] or 0, alive = rt.alive[p.UserId] == true })
		end
	end
	table.sort(rows, function(a, b)
		if a.score == b.score then
			return a.alive and not b.alive
		end
		return a.score > b.score
	end)
	local winner = rows[1]
	rt.publicExtra = rt.publicExtra or {}
	rt.publicExtra.reason = reason
	rt.publicExtra.results = {}
	for i, row in rows do
		local won = i == 1 and (row.score > 0 or row.alive or #rows == 1)
		if rt.mode.WinnerCheck then
			won = rt.mode.WinnerCheck(rt, row.player, i)
		end
		local coins = 12 + math.floor((row.score or 0) * 0.4) + (if won then 40 else 0) + math.max(0, 16 - i * 3)
		local xp = 10 + math.floor((row.score or 0) * 0.25) + (if won then 25 else 0)
		local pay = RewardService.MatchPayout(row.player, {
			matchId = rt.matchId,
			gameId = rt.gameId,
			score = row.score,
			won = won,
			placement = i,
			coins = coins,
			xp = xp,
			kills = rt.kills[row.player.UserId],
		})
		QuestService.Add(row.player, "plays", 1)
		if won then
			QuestService.Add(row.player, "wins", 1)
		end
		if rt.mode.OnWin and won then
			pcall(rt.mode.OnWin, rt, row.player)
		end
		local st = RewardService.GetStats(row.player, rt.gameId)
		LeaderboardService.Submit(rt.gameId, row.player.UserId, "wins", st.wins or 0)
		LeaderboardService.Submit(rt.gameId, row.player.UserId, "score", st.bestScore or row.score)
		table.insert(rt.publicExtra.results, {
			userId = row.player.UserId,
			name = row.player.Name,
			score = row.score,
			placement = i,
			won = won,
			coins = pay.coins,
			xp = pay.xp,
		})
		setLeaderstats(row.player, row.score)
	end
	announce(rt, if winner then (winner.player.Name .. " takes it.") else "Round over.")
	fireState(rt)
	task.delay(12, function()
		if active ~= rt then
			return
		end
		local copy = table.clone(rt.players)
		local replay = rt.replay
		local gid = rt.gameId
		cleanupMatch(rt)
		for _, p in copy do
			if p.Parent then
				restoreLobby(p)
			end
		end
		if type(replay) == "table" then
			task.wait(0.45)
			for uid in replay do
				local p = Players:GetPlayerByUserId(uid)
				if p then
					MatchService.Play(p, gid)
				end
			end
		end
	end)
end

local function hookCharacter(rt: any, player: Player, char: Model)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	if rt.mode.OnCharacter then
		pcall(rt.mode.OnCharacter, rt, player, char)
	end
	table.insert(
		rt.connections,
		hum.Died:Connect(function()
			rt.alive[player.UserId] = false
			local last = char:GetAttribute("VOIDZ_LastHitter")
			if type(last) == "number" then
				rt.kills[last] = (rt.kills[last] or 0) + 1
				rt.scores[last] = (rt.scores[last] or 0) + 5
			end
			if rt.mode.OnDied then
				pcall(rt.mode.OnDied, rt, player)
			end
			event(rt, { kind = "death", userId = player.UserId })
			fireState(rt)
			local respawn = rt.mode.Respawn or 0
			if respawn > 0 and rt.phase == "Playing" then
				task.delay(respawn, function()
					if active ~= rt or rt.phase ~= "Playing" or not player.Parent then
						return
					end
					player:LoadCharacter()
					task.wait(0.15)
					rt.alive[player.UserId] = true
					local idx = table.find(rt.players, player) or 1
					teleport(player, getSpawn(rt, idx))
					fireState(rt)
				end)
			end
		end)
	)
	for _, part in char:GetDescendants() do
		if part:IsA("BasePart") then
			table.insert(
				rt.connections,
				part.Touched:Connect(function(hit)
					if hit and hit:GetAttribute("Kill") then
						if hum.Health > 0 and rt.phase == "Playing" then
							hum.Health = 0
						end
					end
				end)
			)
		end
	end
end

local function addPlayer(rt: any, player: Player)
	if inMatch[player.UserId] then
		return
	end
	if table.find(rt.players, player) then
		return
	end
	if #rt.players >= (rt.def.MaxPlayers or 16) then
		return
	end
	table.insert(rt.players, player)
	rt.alive[player.UserId] = true
	rt.scores[player.UserId] = 0
	rt.kills[player.UserId] = 0
	inMatch[player.UserId] = true
	player:SetAttribute("VOIDZ_InMatch", true)
	setLeaderstats(player, 0)
	table.insert(
		rt.connections,
		player.CharacterAdded:Connect(function(char)
			task.wait(0.1)
			hookCharacter(rt, player, char)
			if rt.phase == "Playing" or rt.phase == "Countdown" or rt.phase == "Lobby" then
				local idx = table.find(rt.players, player) or 1
				teleport(player, getSpawn(rt, idx))
			end
		end)
	)
	if player.Character then
		hookCharacter(rt, player, player.Character)
	end
end

local function runMatch(rt: any)
	rt.phase = "Loading"
	rt.endsAt = os.time() + 3
	rt.objective = "Loading map..."
	lobbySpawn(false)
	fireState(rt)
	task.wait(0.15)
	local folder = Instance.new("Folder")
	folder.Name = "VOIDZ_Match"
	folder.Parent = workspace
	rt.folder = folder
	rt.origin = MapUtil.ORIGIN
	local okBuild, errBuild = pcall(function()
		rt.mode.Build(rt)
	end)
	if not okBuild then
		warn("[VOIDZ] Build failed", rt.gameId, errBuild)
		announce(rt, "Map failed to load.")
		finish(rt, "error")
		return
	end
	if type(rt.spawns) ~= "table" or #rt.spawns == 0 then
		rt.spawns = MapUtil.ringSpawns(folder, rt.origin, math.max(8, #rt.players), 28, 2)
	end
	rt.phase = "Lobby"
	rt.endsAt = os.time() + (rt.mode.LobbySeconds or 6)
	rt.objective = "Get ready"
	for i, p in rt.players do
		if not p.Character then
			p:LoadCharacter()
			task.wait(0.2)
		end
		teleport(p, getSpawn(rt, i))
	end
	fireState(rt)
	event(rt, { kind = "sys", text = "Lobby — match starts shortly." })
	while active == rt and os.time() < rt.endsAt do
		task.wait(0.4)
		fireState(rt)
	end
	if active ~= rt then
		return
	end
	rt.phase = "Countdown"
	rt.endsAt = os.time() + 3
	announce(rt, "3")
	task.wait(1)
	if active ~= rt then
		return
	end
	announce(rt, "2")
	task.wait(1)
	if active ~= rt then
		return
	end
	announce(rt, "1")
	task.wait(1)
	if active ~= rt then
		return
	end
	rt.phase = "Playing"
	rt.startedAt = os.clock()
	rt.endsAt = os.time() + (rt.mode.MatchSeconds or 120)
	rt.objective = rt.mode.Objective or "Play"
	if rt.mode.Begin then
		pcall(rt.mode.Begin, rt)
	end
	announce(rt, rt.mode.Objective or "Go")
	local acc = 0
	heartbeat = RunService.Heartbeat:Connect(function(dt)
		if active ~= rt or rt.phase ~= "Playing" then
			return
		end
		acc += dt
		if rt.mode.Tick then
			pcall(rt.mode.Tick, rt, dt)
		end
		if acc >= 1 then
			acc = 0
			fireState(rt)
			if os.time() >= rt.endsAt then
				finish(rt, "time")
				return
			end
			if rt.mode.ShouldEnd then
				local over, why = rt.mode.ShouldEnd(rt)
				if over then
					finish(rt, why or "complete")
				end
			end
		end
	end)
end

function MatchService.Init()
	loadModes()
	Players.PlayerRemoving:Connect(function(player)
		inMatch[player.UserId] = nil
		if not active then
			return
		end
		local idx = table.find(active.players, player)
		if idx then
			table.remove(active.players, idx)
			active.alive[player.UserId] = nil
			if #active.players == 0 then
				cleanupMatch(active)
			else
				fireState(active)
			end
		end
	end)
end

function MatchService.IsBusy(): boolean
	return active ~= nil
end

function MatchService.Play(player: Player, gameId: string): any
	local def = GameRegistry.Get(gameId)
	if not def then
		return { ok = false, error = Constants.ERRORS.NOT_FOUND }
	end
	if not GameRegistry.IsInPlace(gameId) then
		return { ok = false, error = Constants.ERRORS.COMING_SOON, comingSoon = true, name = def.Name }
	end
	local mode = modes[gameId]
	if not mode then
		return { ok = false, error = "Game module missing." }
	end
	if inMatch[player.UserId] and active and active.gameId == gameId then
		fireState(active, player)
		return { ok = true, inPlace = true, already = true }
	end
	if inMatch[player.UserId] then
		return { ok = false, error = Constants.ERRORS.IN_MATCH }
	end
	if active then
		if active.gameId == gameId and (active.phase == "Lobby" or active.phase == "Countdown" or active.phase == "Loading") then
			addPlayer(active, player)
			for _, mate in PartyService.Members(player) do
				if mate ~= player then
					addPlayer(active, mate)
				end
			end
			fireState(active)
			return { ok = true, inPlace = true, joined = true }
		end
		return { ok = false, error = "A match is already running in this server. Finish or leave, then queue again." }
	end
	local rt = {
		matchId = HttpService:GenerateGUID(false),
		gameId = gameId,
		def = def,
		mode = mode,
		phase = "Loading",
		players = {},
		alive = {},
		scores = {},
		kills = {},
		teams = {},
		connections = {},
		extra = {},
		publicExtra = {},
		objective = "Loading...",
		endsAt = os.time() + 4,
		origin = MapUtil.ORIGIN,
		announce = function(text)
			announce(rt, text)
		end,
		event = function(payload)
			event(rt, payload)
		end,
		push = function()
			fireState(rt)
		end,
		teleport = teleport,
		getSpawn = function(i)
			return getSpawn(rt, i)
		end,
	}
	active = rt
	addPlayer(rt, player)
	for _, mate in PartyService.Members(player) do
		if mate ~= player then
			addPlayer(rt, mate)
		end
	end
	task.spawn(runMatch, rt)
	return { ok = true, inPlace = true, matchId = rt.matchId }
end

function MatchService.Leave(player: Player): any
	if not active or not inMatch[player.UserId] then
		restoreLobby(player)
		return { ok = true }
	end
	local idx = table.find(active.players, player)
	if idx then
		table.remove(active.players, idx)
	end
	active.alive[player.UserId] = nil
	restoreLobby(player)
	if #active.players == 0 then
		cleanupMatch(active)
	else
		fireState(active)
	end
	return { ok = true }
end

function MatchService.Action(player: Player, action: any, payload: any): any
	if type(action) ~= "string" then
		return { ok = false, error = Constants.ERRORS.INVALID }
	end
	if not active or not inMatch[player.UserId] then
		return { ok = false, error = "Not in a match." }
	end
	if active.phase ~= "Playing" and action ~= "vote" and action ~= "ready" then
		return { ok = false, error = "Match isn't live." }
	end
	if not active.alive[player.UserId] and action ~= "vote" then
		return { ok = false, error = "You're out." }
	end
	if active.mode.OnAction then
		local ok, res = pcall(active.mode.OnAction, active, player, action, payload)
		if not ok then
			warn("[VOIDZ] OnAction", res)
			return { ok = false, error = "action" }
		end
		return res or { ok = true }
	end
	return { ok = false, error = "No action." }
end

function MatchService.PlayAgain(player: Player): any
	if active and active.phase == "Results" then
		active.replay = active.replay or {}
		active.replay[player.UserId] = true
		return { ok = true, inPlace = true, waiting = true }
	end
	if not active then
		return { ok = false, error = "No match to replay." }
	end
	local gameId = active.gameId
	MatchService.Leave(player)
	return MatchService.Play(player, gameId)
end

function MatchService.ModesLoaded(): number
	local n = 0
	for _ in modes do
		n += 1
	end
	return n
end

return MatchService
