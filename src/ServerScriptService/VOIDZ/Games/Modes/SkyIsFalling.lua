--!strict

local MapUtil = require(script.Parent.Parent.MapUtil)
local CombatUtil = require(script.Parent.Parent.CombatUtil)

local Mode = {
	Id = "sky_is_falling",
	LobbySeconds = 5,
	MatchSeconds = 110,
	Respawn = 0,
	Actions = { "shove" },
	Objective = "Islands drop. Stay on whatever is left.",
	Tips = { "Jump early.", "Shove is short-range." },
}

function Mode.Build(rt)
	local o = rt.origin
	rt.extra.islands = {}
	rt.spawns = {}
	for i = 1, 9 do
		local row = math.floor((i - 1) / 3)
		local col = (i - 1) % 3
		local pos = o + Vector3.new((col - 1) * 28, 1, (row - 1) * 28)
		local isl = MapUtil.part(rt.folder, {
			Name = "Island",
			Size = Vector3.new(22, 3, 22),
			CFrame = CFrame.new(pos),
			Color = Color3.fromHSV(i / 9, 0.4, 0.8),
			Material = Enum.Material.Slate,
		})
		table.insert(rt.extra.islands, isl)
		table.insert(rt.spawns, CFrame.new(pos + Vector3.new(0, 5, 0)))
		MapUtil.spawnPad(rt.folder, CFrame.new(pos + Vector3.new(0, 2, 0)), Color3.fromRGB(120, 200, 255))
	end
	MapUtil.killBrick(rt.folder, CFrame.new(o + Vector3.new(0, -30, 0)), Vector3.new(200, 4, 200), "Void")
	rt.extra.nextDrop = 0
end

function Mode.Begin(rt)
	rt.extra.nextDrop = os.clock() + 10
	rt.announce("The sky has a queue.")
end

function Mode.Tick(rt, dt)
	for _, p in rt.players do
		if rt.alive[p.UserId] then
			rt.scores[p.UserId] = (rt.scores[p.UserId] or 0) + dt
		end
	end
	if os.clock() >= rt.extra.nextDrop and #rt.extra.islands > 1 then
		local idx = math.random(1, #rt.extra.islands)
		local isl = table.remove(rt.extra.islands, idx)
		if isl then
			isl.Anchored = false
			isl.Material = Enum.Material.Neon
			rt.announce("An island dropped.")
		end
		rt.extra.nextDrop = os.clock() + 9
		rt.publicExtra.left = #rt.extra.islands
	end
end

function Mode.OnAction(rt, player, action)
	if action == "shove" then
		local ok, hit = CombatUtil.swing(player, rt.players, { range = 6, damage = 0, cooldown = 1.1, knockback = 42 })
		return { ok = ok, hit = hit and hit.Name }
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
	if n <= 1 then
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
