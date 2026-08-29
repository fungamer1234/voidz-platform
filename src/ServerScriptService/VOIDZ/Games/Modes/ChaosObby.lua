--!strict

local MapUtil = require(script.Parent.Parent.MapUtil)

local MODS = { "lowgrav", "giant", "tiny", "ice", "speed", "explode", "reverse", "moving" }

local Mode = {
	Id = "chaos_obby",
	LobbySeconds = 5,
	MatchSeconds = 120,
	Respawn = 2,
	Actions = {},
	Objective = "Hit every checkpoint. First finish wins.",
	Tips = { "Checkpoints save your run.", "Modifiers last the whole round." },
}

function Mode.Build(rt)
	local o = rt.origin
	MapUtil.part(rt.folder, {
		Name = "Void",
		Size = Vector3.new(40, 2, 40),
		CFrame = CFrame.new(o),
		Color = Color3.fromRGB(20, 22, 40),
	})
	rt.spawns = { CFrame.new(o + Vector3.new(0, 6, 0)) }
	MapUtil.spawnPad(rt.folder, rt.spawns[1], Color3.fromRGB(80, 200, 255))
	rt.extra.checkpoints = {}
	rt.extra.progress = {}
	rt.extra.finished = {}
	rt.extra.moving = {}
	local z = 12
	for i = 1, 18 do
		local x = math.sin(i * 0.7) * 10
		local y = 1 + (i % 4) * 2
		local size = Vector3.new(8 - (i % 3), 1.2, 7)
		local cf = CFrame.new(o + Vector3.new(x, y, z))
		local plat = MapUtil.part(rt.folder, {
			Name = "Plat" .. i,
			Size = size,
			CFrame = cf,
			Color = Color3.fromHSV(i / 18, 0.55, 0.85),
			Material = Enum.Material.SmoothPlastic,
		})
		if i % 3 == 0 then
			local cp = MapUtil.part(rt.folder, {
				Name = "CP",
				Size = Vector3.new(2, 6, 2),
				CFrame = cf + Vector3.new(0, 4, 0),
				Color = Color3.fromRGB(80, 255, 160),
				Material = Enum.Material.Neon,
				CanCollide = false,
				Attr = { Checkpoint = i },
			})
			table.insert(rt.extra.checkpoints, { i = i, part = cp, cf = cf + Vector3.new(0, 4, 0) })
		end
		if i % 5 == 0 then
			table.insert(rt.extra.moving, { part = plat, base = cf, amp = 6 })
		end
		z += 11
	end
	local finish = MapUtil.part(rt.folder, {
		Name = "Finish",
		Size = Vector3.new(16, 1.4, 16),
		CFrame = CFrame.new(o + Vector3.new(0, 8, z + 4)),
		Color = Color3.fromRGB(255, 220, 80),
		Material = Enum.Material.Neon,
		Attr = { Finish = true },
	})
	MapUtil.label(finish, "FINISH")
	rt.extra.finish = finish
	rt.extra.lastZ = z
	MapUtil.killBrick(rt.folder, CFrame.new(o + Vector3.new(0, -6, z / 2)), Vector3.new(80, 2, z + 40), "Fall")
end

local function applyMod(rt, player)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hum then
		return
	end
	local m = rt.extra.mod
	hum.WalkSpeed = 16
	hum.JumpHeight = 7.2
	if m == "speed" then
		hum.WalkSpeed = 28
	elseif m == "giant" then
		hum.HipHeight = 4
		hum.WalkSpeed = 20
	elseif m == "tiny" then
		hum.HipHeight = 0.4
		hum.WalkSpeed = 12
		hum.JumpHeight = 12
	elseif m == "lowgrav" then
		hum.JumpHeight = 18
		if hrp then
			local att = hrp:FindFirstChild("VOIDZ_Grav") :: VectorForce?
			if not att then
				local a = Instance.new("Attachment")
				a.Name = "VOIDZ_Att"
				a.Parent = hrp
				local vf = Instance.new("VectorForce")
				vf.Name = "VOIDZ_Grav"
				vf.Force = Vector3.new(0, 1100, 0)
				vf.Attachment0 = a
				vf.RelativeTo = Enum.ActuatorRelativeTo.World
				vf.Parent = hrp
			end
		end
	end
	if m == "ice" and rt.folder then
		for _, d in rt.folder:GetDescendants() do
			if d:IsA("BasePart") and d.Name:find("Plat") then
				d.CustomPhysicalProperties = PhysicalProperties.new(0.3, 0.02, 0.1, 1, 1)
			end
		end
	end
	player:SetAttribute("VOIDZ_Reverse", m == "reverse")
end

function Mode.Begin(rt)
	rt.extra.mod = MODS[math.random(1, #MODS)]
	rt.announce("Modifier: " .. rt.extra.mod)
	rt.publicExtra.modifier = rt.extra.mod
	for _, p in rt.players do
		rt.extra.progress[p.UserId] = 0
		applyMod(rt, p)
	end
end

function Mode.OnCharacter(rt, player, char)
	task.wait(0.05)
	applyMod(rt, player)
	local prog = rt.extra.progress[player.UserId] or 0
	for _, cp in rt.extra.checkpoints do
		if cp.i <= prog then
			-- last reached
		end
	end
end

function Mode.Tick(rt, dt)
	rt.extra.clock = (rt.extra.clock or 0) + dt
	for _, mv in rt.extra.moving do
		local t = math.sin(rt.extra.clock * 1.3) * mv.amp
		mv.part.CFrame = mv.base * CFrame.new(t, 0, 0)
	end
	if rt.extra.mod == "explode" and rt.extra.clock > 8 then
		for _, d in rt.folder:GetChildren() do
			if d.Name:find("Plat") and math.random() < 0.02 then
				d.BrickColor = BrickColor.new("Really red")
				task.delay(0.8, function()
					if d.Parent then
						d:Destroy()
					end
				end)
			end
		end
	end
	for _, p in rt.players do
		if rt.extra.finished[p.UserId] then
			continue
		end
		local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then
			continue
		end
		for _, cp in rt.extra.checkpoints do
			if (hrp.Position - cp.part.Position).Magnitude < 5 then
				if (rt.extra.progress[p.UserId] or 0) < cp.i then
					rt.extra.progress[p.UserId] = cp.i
					rt.scores[p.UserId] = cp.i
				end
			end
		end
		if (hrp.Position - rt.extra.finish.Position).Magnitude < 8 then
			rt.extra.finished[p.UserId] = true
			local place = 0
			for _ in rt.extra.finished do
				place += 1
			end
			rt.scores[p.UserId] = 100 - place * 8
			rt.announce(p.Name .. " finished (#" .. place .. ")")
			if place == 1 then
				local AchievementService = require(script.Parent.Parent.Parent.Services.AchievementService)
				AchievementService.Unlock(p, "speed_demon")
			end
		end
	end
	rt.publicExtra.progress = rt.extra.progress
end

function Mode.ShouldEnd(rt)
	local n = 0
	for _ in rt.extra.finished do
		n += 1
	end
	return n >= math.max(1, #rt.players) , "finish"
end

function Mode.OnWin(rt, player)
	local QuestService = require(script.Parent.Parent.Parent.Services.QuestService)
	QuestService.Add(player, "races", 1)
end

return Mode
