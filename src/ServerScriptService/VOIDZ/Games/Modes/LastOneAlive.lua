--!strict

local MapUtil = require(script.Parent.Parent.MapUtil)

local EVENTS = { "meteors", "flood", "lightning", "lava", "quake" }

local Mode = {
	Id = "last_one_alive",
	LobbySeconds = 5,
	MatchSeconds = 100,
	Respawn = 0,
	Actions = { "sprint" },
	Objective = "Survive the disasters. Last one alive wins.",
	Tips = { "Watch the sky.", "High ground helps — until it doesn't." },
}

function Mode.Build(rt)
	local o = rt.origin
	MapUtil.arena(rt.folder, o, 120, 120, 16, Color3.fromRGB(36, 34, 40))
	for i = 1, 12 do
		MapUtil.part(rt.folder, {
			Name = "Cover",
			Size = Vector3.new(6, 8, 6),
			CFrame = CFrame.new(o + Vector3.new((math.random() - 0.5) * 90, 5, (math.random() - 0.5) * 90)),
			Color = Color3.fromRGB(50, 48, 60),
		})
	end
	rt.spawns = MapUtil.ringSpawns(rt.folder, o, 16, 40, 2)
	rt.extra.hazard = MapUtil.folder("Hazards", rt.folder)
end

function Mode.Begin(rt)
	rt.extra.next = os.clock() + 6
	rt.extra.round = 0
	for _, p in rt.players do
		rt.scores[p.UserId] = 0
	end
end

local function clearHaz(rt)
	rt.extra.hazard:ClearAllChildren()
end

local function meteors(rt)
	for i = 1, 10 do
		local p = MapUtil.part(rt.extra.hazard, {
			Name = "Meteor",
			Size = Vector3.new(5, 5, 5),
			CFrame = CFrame.new(rt.origin + Vector3.new((math.random() - 0.5) * 100, 40 + math.random() * 20, (math.random() - 0.5) * 100)),
			Color = Color3.fromRGB(255, 120, 40),
			Material = Enum.Material.Neon,
			Anchored = false,
			Attr = { Kill = true },
		})
		p:ApplyImpulse(Vector3.new(0, -80, 0))
		task.delay(4, function()
			if p.Parent then
				p:Destroy()
			end
		end)
	end
end

local function flood(rt)
	local w = MapUtil.part(rt.extra.hazard, {
		Name = "Flood",
		Size = Vector3.new(118, 1, 118),
		CFrame = CFrame.new(rt.origin + Vector3.new(0, 1, 0)),
		Color = Color3.fromRGB(40, 90, 180),
		Material = Enum.Material.Glass,
		Transparency = 0.35,
		Attr = { Kill = true },
	})
	task.spawn(function()
		for i = 1, 10 do
			task.wait(0.35)
			if w.Parent then
				w.Size = Vector3.new(118, 1 + i * 1.1, 118)
				w.CFrame = CFrame.new(rt.origin + Vector3.new(0, w.Size.Y / 2, 0))
			end
		end
		task.wait(3)
		if w.Parent then
			w:Destroy()
		end
	end)
end

local function lightning(rt)
	for i = 1, 6 do
		task.delay(i * 0.4, function()
			if rt.phase ~= "Playing" then
				return
			end
			local t = rt.players[math.random(1, #rt.players)]
			local hrp = t and t.Character and t.Character:FindFirstChild("HumanoidRootPart")
			local pos = if hrp then hrp.Position else rt.origin
			local bolt = MapUtil.part(rt.extra.hazard, {
				Name = "Bolt",
				Size = Vector3.new(2, 40, 2),
				CFrame = CFrame.new(pos + Vector3.new(0, 20, 0)),
				Color = Color3.fromRGB(200, 220, 255),
				Material = Enum.Material.Neon,
				CanCollide = false,
				Attr = { Kill = true },
			})
			task.delay(0.35, function()
				if bolt.Parent then
					bolt:Destroy()
				end
			end)
		end)
	end
end

local function lava(rt)
	local l = MapUtil.killBrick(rt.extra.hazard, CFrame.new(rt.origin + Vector3.new(0, 0.4, 0)), Vector3.new(80, 1, 80), "Lava")
	l.Color = Color3.fromRGB(255, 80, 20)
	task.delay(6, function()
		if l.Parent then
			l:Destroy()
		end
	end)
end

local function quake(rt)
	for _, d in rt.folder:GetChildren() do
		if d.Name == "Cover" and math.random() < 0.4 then
			d.Anchored = false
		end
	end
end

function Mode.Tick(rt, dt)
	for _, p in rt.players do
		if rt.alive[p.UserId] then
			rt.scores[p.UserId] = (rt.scores[p.UserId] or 0) + dt
		end
	end
	if os.clock() >= (rt.extra.next or 0) then
		clearHaz(rt)
		rt.extra.round += 1
		local e = EVENTS[((rt.extra.round - 1) % #EVENTS) + 1]
		rt.announce(string.upper(e) .. " incoming")
		rt.publicExtra.disaster = e
		if e == "meteors" then
			meteors(rt)
		elseif e == "flood" then
			flood(rt)
		elseif e == "lightning" then
			lightning(rt)
		elseif e == "lava" then
			lava(rt)
		else
			quake(rt)
		end
		rt.extra.next = os.clock() + 14
	end
end

function Mode.OnAction(rt, player, action)
	if action == "sprint" then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = 26
			task.delay(1.6, function()
				if hum.Parent then
					hum.WalkSpeed = 16
				end
			end)
		end
		return { ok = true }
	end
	return { ok = false }
end

function Mode.ShouldEnd(rt)
	local n = 0
	local last
	for _, p in rt.players do
		if rt.alive[p.UserId] then
			n += 1
			last = p
		end
	end
	if n <= 1 and #rt.players > 0 then
		if last then
			local AchievementService = require(script.Parent.Parent.Parent.Services.AchievementService)
			AchievementService.Unlock(last, "survivor")
			local QuestService = require(script.Parent.Parent.Parent.Services.QuestService)
			QuestService.Add(last, "survives", 1)
		end
		return true, "last"
	end
	return false
end

return Mode
