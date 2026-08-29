--!strict

local MapUtil = require(script.Parent.Parent.MapUtil)
local AIUtil = require(script.Parent.Parent.AIUtil)

local DISASTERS = { "quake", "tsunami", "meteor", "blackout", "tornado" }

local Mode = {
	Id = "disaster_city",
	LobbySeconds = 5,
	MatchSeconds = 140,
	Respawn = 6,
	Actions = { "sprint" },
	Objective = "Stay alive through the city's bad ideas.",
	Tips = { "NPCs run toward safety.", "High ground vs flood. Indoors vs meteors." },
}

function Mode.Build(rt)
	local o = rt.origin
	MapUtil.arena(rt.folder, o, 160, 160, 16, Color3.fromRGB(42, 44, 48))
	rt.extra.buildings = {}
	for x = -2, 2 do
		for z = -2, 2 do
			if math.abs(x) + math.abs(z) > 0 then
				local h = 8 + math.random(4, 18)
				local b = MapUtil.part(rt.folder, {
					Name = "Bldg",
					Size = Vector3.new(12, h, 12),
					CFrame = CFrame.new(o + Vector3.new(x * 26, h / 2, z * 26)),
					Color = Color3.fromRGB(50 + math.random(20), 52, 60),
				})
				table.insert(rt.extra.buildings, b)
			end
		end
	end
	rt.spawns = MapUtil.ringSpawns(rt.folder, o, 12, 20, 2)
	rt.extra.npcs = {}
	for i = 1, 8 do
		local n = AIUtil.dummy(
			rt.folder,
			"Citizen",
			CFrame.new(o + Vector3.new((math.random() - 0.5) * 80, 4, (math.random() - 0.5) * 80)),
			Color3.fromRGB(180, 160, 140),
			0.9
		)
		table.insert(rt.extra.npcs, n)
	end
	rt.extra.safe = o + Vector3.new(0, 4, 0)
	rt.extra.haz = MapUtil.folder("Haz", rt.folder)
end

function Mode.Begin(rt)
	rt.extra.next = os.clock() + 8
	rt.extra.idx = 0
end

function Mode.Tick(rt, dt)
	for _, p in rt.players do
		if rt.alive[p.UserId] then
			rt.scores[p.UserId] = (rt.scores[p.UserId] or 0) + dt
		end
	end
	if os.clock() >= (rt.extra.next or 0) then
		rt.extra.idx += 1
		local d = DISASTERS[((rt.extra.idx - 1) % #DISASTERS) + 1]
		rt.announce("CITY ALERT: " .. d)
		rt.publicExtra.disaster = d
		rt.extra.haz:ClearAllChildren()
		if d == "meteor" then
			for i = 1, 8 do
				local m = MapUtil.part(rt.extra.haz, {
					Name = "M",
					Size = Vector3.new(6, 6, 6),
					CFrame = CFrame.new(rt.origin + Vector3.new((math.random() - 0.5) * 120, 50, (math.random() - 0.5) * 120)),
					Color = Color3.fromRGB(255, 100, 40),
					Material = Enum.Material.Neon,
					Anchored = false,
					Attr = { Kill = true },
				})
				task.delay(5, function()
					if m.Parent then
						m:Destroy()
					end
				end)
			end
		elseif d == "tsunami" then
			local w = MapUtil.part(rt.extra.haz, {
				Name = "Wave",
				Size = Vector3.new(150, 2, 20),
				CFrame = CFrame.new(rt.origin + Vector3.new(0, 2, -70)),
				Color = Color3.fromRGB(40, 90, 180),
				Transparency = 0.3,
				Attr = { Kill = true },
			})
			task.spawn(function()
				for i = 1, 24 do
					task.wait(0.12)
					if w.Parent then
						w.CFrame = w.CFrame + Vector3.new(0, 0, 6)
					end
				end
				if w.Parent then
					w:Destroy()
				end
			end)
		elseif d == "quake" then
			for _, b in rt.extra.buildings do
				if math.random() < 0.25 then
					b.Anchored = false
				end
			end
		elseif d == "tornado" then
			local t = MapUtil.part(rt.extra.haz, {
				Name = "Tornado",
				Size = Vector3.new(10, 30, 10),
				CFrame = CFrame.new(rt.origin + Vector3.new(0, 16, 0)),
				Color = Color3.fromRGB(160, 160, 180),
				Transparency = 0.4,
				CanCollide = false,
				Attr = { Kill = true },
			})
			rt.extra.tornado = t
		end
		rt.extra.safe = rt.origin + Vector3.new((math.random() - 0.5) * 40, 4, (math.random() - 0.5) * 40)
		for _, n in rt.extra.npcs do
			if n.Parent then
				AIUtil.pathTo(n, rt.extra.safe)
			end
		end
		rt.extra.next = os.clock() + 16
	end
	if rt.extra.tornado and rt.extra.tornado.Parent then
		rt.extra.tornado.CFrame = rt.extra.tornado.CFrame * CFrame.Angles(0, dt * 3, 0) + Vector3.new(math.sin(os.clock()) * 0.4, 0, math.cos(os.clock()) * 0.4)
	end
end

function Mode.OnAction(rt, player, action)
	if action == "sprint" then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = 26
			task.delay(1.5, function()
				if hum.Parent then
					hum.WalkSpeed = 16
				end
			end)
		end
		return { ok = true }
	end
	return { ok = false }
end

function Mode.OnWin(rt, player)
	local AchievementService = require(script.Parent.Parent.Parent.Services.AchievementService)
	AchievementService.Unlock(player, "survivor")
	local QuestService = require(script.Parent.Parent.Parent.Services.QuestService)
	QuestService.Add(player, "survives", 1)
end

return Mode
