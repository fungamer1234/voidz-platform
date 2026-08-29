--!strict

local MapUtil = require(script.Parent.Parent.MapUtil)

local Mode = {
	Id = "street_racers",
	LobbySeconds = 6,
	MatchSeconds = 150,
	Respawn = 3,
	Actions = { "boost", "drift" },
	Objective = "3 laps. Boost on straights, drift the corners.",
	Tips = { "Checkpoints must be hit in order.", "Boost has a cooldown." },
}

function Mode.Build(rt)
	local o = rt.origin
	local cps = {}
	local radius = 48
	for i = 1, 12 do
		local a = ((i - 1) / 12) * math.pi * 2
		local pos = o + Vector3.new(math.cos(a) * radius, 1, math.sin(a) * radius)
		local nxtA = (i / 12) * math.pi * 2
		local nxt = o + Vector3.new(math.cos(nxtA) * radius, 1, math.sin(nxtA) * radius)
		local mid = (pos + nxt) / 2
		local look = CFrame.lookAt(mid, nxt)
		MapUtil.part(rt.folder, {
			Name = "Road",
			Size = Vector3.new(14, 1, (nxt - pos).Magnitude + 2),
			CFrame = look,
			Color = Color3.fromRGB(30, 32, 40),
			Material = Enum.Material.Asphalt,
		})
		local gate = MapUtil.part(rt.folder, {
			Name = "CP",
			Size = Vector3.new(16, 10, 1),
			CFrame = CFrame.new(pos + Vector3.new(0, 6, 0)),
			Color = Color3.fromRGB(80, 180, 255),
			Material = Enum.Material.Neon,
			Transparency = 0.55,
			CanCollide = false,
			Attr = { CP = i },
		})
		table.insert(cps, { i = i, part = gate, pos = pos })
	end
	MapUtil.part(rt.folder, {
		Name = "Infield",
		Size = Vector3.new(50, 1, 50),
		CFrame = CFrame.new(o),
		Color = Color3.fromRGB(28, 70, 36),
	})
	rt.extra.cps = cps
	rt.spawns = {}
	for i = 1, 8 do
		local a = -0.2 + i * 0.05
		local pos = o + Vector3.new(math.cos(a) * radius, 4, math.sin(a) * radius)
		table.insert(rt.spawns, CFrame.new(pos, o))
		MapUtil.spawnPad(rt.folder, CFrame.new(pos), Color3.fromRGB(255, 200, 60))
	end
	rt.extra.next = {}
	rt.extra.laps = {}
	rt.extra.boostUntil = {}
	rt.extra.kart = {}
end

local function weldKart(player)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp or char:FindFirstChild("Kart") then
		return
	end
	local k = Instance.new("Part")
	k.Name = "Kart"
	k.Size = Vector3.new(5, 0.6, 7)
	k.Color = Color3.fromHSV((player.UserId % 10) / 10, 0.7, 0.95)
	k.CanCollide = false
	k.Massless = true
	k.CFrame = hrp.CFrame * CFrame.new(0, -2, 0)
	k.Parent = char
	local w = Instance.new("WeldConstraint")
	w.Part0 = hrp
	w.Part1 = k
	w.Parent = k
end

function Mode.OnCharacter(rt, player, char)
	task.wait(0.05)
	weldKart(player)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = 28
		hum.JumpHeight = 0
	end
end

function Mode.Begin(rt)
	for _, p in rt.players do
		rt.extra.next[p.UserId] = 1
		rt.extra.laps[p.UserId] = 0
		weldKart(p)
		local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = 28
			hum.JumpHeight = 0
		end
	end
end

function Mode.Tick(rt, dt)
	for _, p in rt.players do
		if not rt.alive[p.UserId] then
			continue
		end
		local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then
			continue
		end
		local need = rt.extra.next[p.UserId] or 1
		local cp = rt.extra.cps[need]
		if cp and (hrp.Position - cp.pos).Magnitude < 12 then
			local nxt = need + 1
			if nxt > #rt.extra.cps then
				rt.extra.laps[p.UserId] = (rt.extra.laps[p.UserId] or 0) + 1
				nxt = 1
				rt.announce(p.Name .. " lap " .. rt.extra.laps[p.UserId])
			end
			rt.extra.next[p.UserId] = nxt
			rt.scores[p.UserId] = (rt.extra.laps[p.UserId] or 0) * 12 + (need)
		end
		if os.clock() < (rt.extra.boostUntil[p.UserId] or 0) then
			local hum = p.Character:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.WalkSpeed = 42
			end
		end
	end
	rt.publicExtra.laps = rt.extra.laps
	rt.publicExtra.next = rt.extra.next
end

function Mode.OnAction(rt, player, action)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not hum then
		return { ok = false }
	end
	if action == "boost" then
		if os.clock() < (rt.extra.boostUntil[player.UserId] or 0) - 1.2 then
			return { ok = false, error = "Boost cooling down." }
		end
		rt.extra.boostUntil[player.UserId] = os.clock() + 1.4
		hum.WalkSpeed = 42
		task.delay(1.4, function()
			if hum.Parent then
				hum.WalkSpeed = 28
			end
		end)
		return { ok = true }
	elseif action == "drift" then
		hum.WalkSpeed = 22
		task.delay(0.8, function()
			if hum.Parent then
				hum.WalkSpeed = 28
			end
		end)
		return { ok = true }
	end
	return { ok = false }
end

function Mode.ShouldEnd(rt)
	for _, p in rt.players do
		if (rt.extra.laps[p.UserId] or 0) >= 3 then
			local AchievementService = require(script.Parent.Parent.Parent.Services.AchievementService)
			AchievementService.Unlock(p, "speed_demon")
			local QuestService = require(script.Parent.Parent.Parent.Services.QuestService)
			QuestService.Add(p, "races", 1)
			return true, "laps"
		end
	end
	return false
end

return Mode
