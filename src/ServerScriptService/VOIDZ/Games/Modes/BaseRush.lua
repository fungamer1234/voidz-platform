--!strict

local MapUtil = require(script.Parent.Parent.MapUtil)
local CombatUtil = require(script.Parent.Parent.CombatUtil)

local Mode = {
	Id = "base_rush",
	LobbySeconds = 5,
	MatchSeconds = 160,
	Respawn = 5,
	Actions = { "upgrade", "attack", "lock" },
	Objective = "Print coins, upgrade, raid. Highest vault at the horn wins.",
	Tips = { "Upgrade your dropper.", "Attack only works in range.", "Lock burns income." },
}

function Mode.Build(rt)
	local o = rt.origin
	MapUtil.arena(rt.folder, o, 160, 160, 14, Color3.fromRGB(30, 36, 32))
	rt.extra.plots = {}
	local n = math.max(4, #rt.players)
	rt.spawns = {}
	for i = 1, n do
		local a = ((i - 1) / n) * math.pi * 2
		local pos = o + Vector3.new(math.cos(a) * 50, 2, math.sin(a) * 50)
		local pad = MapUtil.part(rt.folder, {
			Name = "Plot",
			Size = Vector3.new(22, 1, 22),
			CFrame = CFrame.new(pos),
			Color = Color3.fromHSV(i / n, 0.5, 0.7),
		})
		MapUtil.label(pad, "BASE " .. i)
		local drop = MapUtil.part(rt.folder, {
			Name = "Dropper",
			Size = Vector3.new(4, 8, 4),
			CFrame = CFrame.new(pos + Vector3.new(6, 5, 6)),
			Color = Color3.fromRGB(80, 200, 120),
			Material = Enum.Material.Neon,
		})
		table.insert(rt.spawns, CFrame.new(pos + Vector3.new(0, 4, 0)))
		rt.extra.plots[i] = { pad = pad, drop = drop, owner = nil, rate = 2, vault = 0, lock = 0, lvl = 1 }
	end
end

function Mode.Begin(rt)
	for i, p in rt.players do
		local plot = rt.extra.plots[((i - 1) % #rt.extra.plots) + 1]
		plot.owner = p.UserId
		MapUtil.label(plot.pad, p.Name)
		rt.scores[p.UserId] = 0
	end
end

local function plotOf(rt, userId)
	for _, pl in rt.extra.plots do
		if pl.owner == userId then
			return pl
		end
	end
	return nil
end

function Mode.Tick(rt, dt)
	rt.extra.acc = (rt.extra.acc or 0) + dt
	if rt.extra.acc >= 1 then
		rt.extra.acc = 0
		for _, pl in rt.extra.plots do
			if pl.owner and os.clock() >= (pl.lock or 0) then
				pl.vault += pl.rate
				rt.scores[pl.owner] = pl.vault
			end
		end
		rt.publicExtra.vaults = {}
		for _, pl in rt.extra.plots do
			if pl.owner then
				rt.publicExtra.vaults[tostring(pl.owner)] = { vault = math.floor(pl.vault), lvl = pl.lvl }
			end
		end
	end
end

function Mode.OnAction(rt, player, action, payload)
	local plot = plotOf(rt, player.UserId)
	if action == "upgrade" then
		if not plot then
			return { ok = false }
		end
		local cost = 15 * plot.lvl
		if plot.vault < cost then
			return { ok = false, error = "Need " .. cost .. " in the vault." }
		end
		plot.vault -= cost
		plot.lvl += 1
		plot.rate = 2 + plot.lvl
		rt.announce(player.Name .. " dropper lv " .. plot.lvl)
		return { ok = true }
	elseif action == "lock" then
		if not plot then
			return { ok = false }
		end
		plot.lock = os.clock() + 10
		rt.announce(player.Name .. " locked.")
		return { ok = true }
	elseif action == "attack" then
		local targets = {}
		for _, p in rt.players do
			table.insert(targets, p)
		end
		local ok, hit = CombatUtil.swing(player, targets, { range = 8, damage = 18, cooldown = 0.55, knockback = 22 })
		if ok and hit then
			local victimPlot = plotOf(rt, hit.UserId)
			if victimPlot and victimPlot.vault > 0 then
				local steal = math.min(8, math.floor(victimPlot.vault * 0.12) + 2)
				if os.clock() < (victimPlot.lock or 0) then
					steal = math.floor(steal * 0.25)
				end
				victimPlot.vault -= steal
				if plot then
					plot.vault += steal
				end
				rt.announce(player.Name .. " raided " .. steal)
			end
			rt.kills[player.UserId] = rt.kills[player.UserId]
			local hum = CombatUtil.humanoid(hit)
			if hum and hum.Health <= 0 then
				rt.kills[player.UserId] = (rt.kills[player.UserId] or 0) + 1
			end
		end
		return { ok = ok }
	end
	return { ok = false }
end

return Mode
