--!strict

local MapUtil = require(script.Parent.Parent.MapUtil)

local Mode = {
	Id = "hideout",
	LobbySeconds = 6,
	MatchSeconds = 100,
	Respawn = 0,
	Actions = { "hide", "tag" },
	Objective = "One seeker. Hide or hunt. Timer favors hiders.",
	Tips = { "Lockers conceal you from tag range.", "Seeker is random." },
}

function Mode.Build(rt)
	local o = rt.origin
	MapUtil.arena(rt.folder, o, 80, 80, 16, Color3.fromRGB(22, 24, 34))
	rt.extra.lockers = {}
	for x = -2, 2 do
		for z = -2, 2 do
			local pos = o + Vector3.new(x * 14, 4, z * 14)
			MapUtil.part(rt.folder, {
				Name = "Wall",
				Size = Vector3.new(2, 8, 10),
				CFrame = CFrame.new(pos) * CFrame.Angles(0, (x + z) * 0.3, 0),
				Color = Color3.fromRGB(40, 42, 58),
			})
			local lk = MapUtil.part(rt.folder, {
				Name = "Locker",
				Size = Vector3.new(3, 7, 3),
				CFrame = CFrame.new(pos + Vector3.new(4, 0, 4)),
				Color = Color3.fromRGB(50, 55, 70),
				Attr = { Locker = true },
			})
			table.insert(rt.extra.lockers, lk)
		end
	end
	rt.spawns = MapUtil.ringSpawns(rt.folder, o, 12, 28, 2)
	rt.extra.hidden = {}
end

function Mode.Begin(rt)
	local seeker = rt.players[math.random(1, #rt.players)]
	rt.extra.seeker = seeker.UserId
	rt.teams[seeker.UserId] = "seeker"
	for _, p in rt.players do
		if p ~= seeker then
			rt.teams[p.UserId] = "hider"
		end
		rt.scores[p.UserId] = 0
	end
	rt.announce(seeker.Name .. " is the seeker. 8 seconds to hide.")
	rt.publicExtra.seeker = seeker.UserId
	local hum = seeker.Character and seeker.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = 0
		task.delay(8, function()
			if hum.Parent then
				hum.WalkSpeed = 20
			end
			rt.announce("Hunting starts.")
		end)
	end
end

function Mode.Tick(rt, dt)
	for _, p in rt.players do
		if rt.teams[p.UserId] == "hider" and rt.alive[p.UserId] then
			rt.scores[p.UserId] = (rt.scores[p.UserId] or 0) + dt
		end
	end
	rt.publicExtra.hidden = rt.extra.hidden
end

function Mode.OnAction(rt, player, action)
	if action == "hide" then
		if rt.teams[player.UserId] == "seeker" then
			return { ok = false }
		end
		rt.extra.hidden[player.UserId] = not rt.extra.hidden[player.UserId]
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.Anchored = rt.extra.hidden[player.UserId] == true
			if player.Character then
				for _, d in player.Character:GetDescendants() do
					if d:IsA("BasePart") then
						d.Transparency = if rt.extra.hidden[player.UserId] then 0.65 else 0
					end
				end
			end
		end
		return { ok = true, hidden = rt.extra.hidden[player.UserId] }
	elseif action == "tag" then
		if rt.teams[player.UserId] ~= "seeker" then
			return { ok = false }
		end
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then
			return { ok = false }
		end
		for _, o in rt.players do
			if rt.teams[o.UserId] == "hider" and rt.alive[o.UserId] and not rt.extra.hidden[o.UserId] then
				local ohrp = o.Character and o.Character:FindFirstChild("HumanoidRootPart")
				if ohrp and (ohrp.Position - hrp.Position).Magnitude < 6 then
					rt.alive[o.UserId] = false
					local hum = o.Character:FindFirstChildOfClass("Humanoid")
					if hum then
						hum.Health = 0
					end
					rt.scores[player.UserId] = (rt.scores[player.UserId] or 0) + 15
					rt.announce("Tagged " .. o.Name)
					return { ok = true }
				end
			end
		end
		return { ok = false, error = "No hider in range." }
	end
	return { ok = false }
end

function Mode.ShouldEnd(rt)
	local hiders = 0
	for _, p in rt.players do
		if rt.teams[p.UserId] == "hider" and rt.alive[p.UserId] then
			hiders += 1
		end
	end
	if hiders == 0 then
		return true, "alltagged"
	end
	return false
end

function Mode.WinnerCheck(rt, player, _i)
	local hidersLeft = 0
	for _, p in rt.players do
		if rt.teams[p.UserId] == "hider" and rt.alive[p.UserId] then
			hidersLeft += 1
		end
	end
	if hidersLeft == 0 then
		return rt.teams[player.UserId] == "seeker"
	end
	if rt.teams[player.UserId] == "hider" and rt.alive[player.UserId] then
		local AchievementService = require(script.Parent.Parent.Parent.Services.AchievementService)
		AchievementService.Unlock(player, "untouchable")
		return true
	end
	return false
end

return Mode
