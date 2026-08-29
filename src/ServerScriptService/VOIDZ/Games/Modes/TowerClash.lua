--!strict

local MapUtil = require(script.Parent.Parent.MapUtil)
local CombatUtil = require(script.Parent.Parent.CombatUtil)
local AIUtil = require(script.Parent.Parent.AIUtil)

local Mode = {
	Id = "tower_clash",
	LobbySeconds = 6,
	MatchSeconds = 150,
	Respawn = 6,
	Actions = { "spawn", "attack" },
	Objective = "Blue vs amber. Units march. First core to 0 loses.",
	Tips = { "Spawn costs income.", "You can also swing.", "Hold the lane." },
}

function Mode.Build(rt)
	local o = rt.origin
	MapUtil.part(rt.folder, {
		Name = "Lane",
		Size = Vector3.new(28, 1, 140),
		CFrame = CFrame.new(o),
		Color = Color3.fromRGB(40, 44, 52),
	})
	local blue = MapUtil.part(rt.folder, {
		Name = "CoreBlue",
		Size = Vector3.new(16, 12, 16),
		CFrame = CFrame.new(o + Vector3.new(0, 7, -60)),
		Color = Color3.fromRGB(70, 140, 255),
		Material = Enum.Material.Neon,
	})
	local amber = MapUtil.part(rt.folder, {
		Name = "CoreAmber",
		Size = Vector3.new(16, 12, 16),
		CFrame = CFrame.new(o + Vector3.new(0, 7, 60)),
		Color = Color3.fromRGB(255, 170, 50),
		Material = Enum.Material.Neon,
	})
	MapUtil.label(blue, "BLUE CORE")
	MapUtil.label(amber, "AMBER CORE")
	rt.extra.blue = blue
	rt.extra.amber = amber
	rt.extra.hp = { blue = 100, amber = 100 }
	rt.extra.units = {}
	rt.extra.income = {}
	rt.spawns = {
		CFrame.new(o + Vector3.new(-8, 4, -50)),
		CFrame.new(o + Vector3.new(8, 4, -50)),
		CFrame.new(o + Vector3.new(-8, 4, 50)),
		CFrame.new(o + Vector3.new(8, 4, 50)),
	}
	for _, cf in rt.spawns do
		MapUtil.spawnPad(rt.folder, cf, Color3.fromRGB(200, 200, 210))
	end
end

function Mode.Begin(rt)
	for i, p in rt.players do
		rt.teams[p.UserId] = if i % 2 == 1 then "blue" else "amber"
		rt.extra.income[p.UserId] = 20
		rt.scores[p.UserId] = 0
	end
	rt.announce("Teams assigned. March the lane.")
end

function Mode.Tick(rt, dt)
	rt.extra.acc = (rt.extra.acc or 0) + dt
	if rt.extra.acc >= 1 then
		rt.extra.acc = 0
		for _, p in rt.players do
			rt.extra.income[p.UserId] = (rt.extra.income[p.UserId] or 0) + 3
		end
	end
	for i = #rt.extra.units, 1, -1 do
		local u = rt.extra.units[i]
		if not u.part.Parent then
			table.remove(rt.extra.units, i)
			continue
		end
		local dest = if u.team == "blue" then rt.extra.amber.Position else rt.extra.blue.Position
		local pos = u.part.Position
		local delta = dest - pos
		if delta.Magnitude < 8 then
			if u.team == "blue" then
				rt.extra.hp.amber -= 4
			else
				rt.extra.hp.blue -= 4
			end
			u.part:Destroy()
			table.remove(rt.extra.units, i)
		else
			u.part.CFrame = CFrame.new(pos + delta.Unit * 14 * dt)
		end
	end
	rt.publicExtra.hp = rt.extra.hp
	rt.publicExtra.income = rt.extra.income
	for _, p in rt.players do
		rt.scores[p.UserId] = if rt.teams[p.UserId] == "blue" then rt.extra.hp.blue else rt.extra.hp.amber
	end
end

function Mode.OnAction(rt, player, action)
	if action == "spawn" then
		local cost = 12
		if (rt.extra.income[player.UserId] or 0) < cost then
			return { ok = false, error = "Need 12 income." }
		end
		rt.extra.income[player.UserId] -= cost
		local team = rt.teams[player.UserId] or "blue"
		local start = if team == "blue" then rt.origin + Vector3.new(0, 4, -52) else rt.origin + Vector3.new(0, 4, 52)
		local part = AIUtil.ball(rt.folder, "Unit", start, if team == "blue" then Color3.fromRGB(80, 140, 255) else Color3.fromRGB(255, 170, 50), 1.1)
		table.insert(rt.extra.units, { part = part, team = team })
		return { ok = true }
	elseif action == "attack" then
		CombatUtil.swing(player, rt.players, { range = 8, damage = 14, cooldown = 0.5, knockback = 14 })
		return { ok = true }
	end
	return { ok = false }
end

function Mode.ShouldEnd(rt)
	if rt.extra.hp.blue <= 0 or rt.extra.hp.amber <= 0 then
		return true, "core"
	end
	return false
end

function Mode.WinnerCheck(rt, player, _place)
	local team = rt.teams[player.UserId]
	if rt.extra.hp.blue <= 0 then
		return team == "amber"
	end
	if rt.extra.hp.amber <= 0 then
		return team == "blue"
	end
	return (rt.extra.hp[team] or 0) >= (rt.extra.hp[if team == "blue" then "amber" else "blue"] or 0)
end

return Mode
