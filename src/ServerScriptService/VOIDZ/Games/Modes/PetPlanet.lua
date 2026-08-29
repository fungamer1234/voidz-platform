--!strict

local MapUtil = require(script.Parent.Parent.MapUtil)
local AIUtil = require(script.Parent.Parent.AIUtil)

local EGGS = {
	{ name = "Common Egg", cost = 10, color = Color3.fromRGB(180, 180, 190) },
	{ name = "Rare Egg", cost = 35, color = Color3.fromRGB(80, 160, 255) },
	{ name = "Epic Egg", cost = 80, color = Color3.fromRGB(180, 90, 255) },
}

local Mode = {
	Id = "pet_planet",
	LobbySeconds = 5,
	MatchSeconds = 140,
	Respawn = 3,
	Actions = { "buy", "equip" },
	Objective = "Farm coins, hatch pets, equip a multiplier.",
	Tips = { "Stand on coin pads.", "Eggs are server-priced.", "Pets follow you." },
}

function Mode.Build(rt)
	local o = rt.origin
	MapUtil.arena(rt.folder, o, 140, 140, 12, Color3.fromRGB(40, 70, 50))
	rt.spawns = MapUtil.ringSpawns(rt.folder, o, 12, 30, 2)
	rt.extra.pads = {}
	for i = 1, 8 do
		local a = (i / 8) * math.pi * 2
		local pad = MapUtil.part(rt.folder, {
			Name = "CoinPad",
			Size = Vector3.new(10, 1, 10),
			CFrame = CFrame.new(o + Vector3.new(math.cos(a) * 40, 2, math.sin(a) * 40)),
			Color = Color3.fromRGB(255, 210, 70),
			Material = Enum.Material.Neon,
		})
		MapUtil.label(pad, "COINS")
		table.insert(rt.extra.pads, pad)
	end
	rt.extra.shop = {}
	for i, egg in EGGS do
		local p = MapUtil.part(rt.folder, {
			Name = "Egg",
			Size = Vector3.new(5, 6, 5),
			CFrame = CFrame.new(o + Vector3.new((i - 2) * 10, 5, -50)),
			Color = egg.color,
			Material = Enum.Material.SmoothPlastic,
			Attr = { Egg = i },
		})
		MapUtil.label(p, egg.name .. "\n" .. egg.cost)
		rt.extra.shop[i] = p
	end
	rt.extra.coins = {}
	rt.extra.pets = {}
	rt.extra.mult = {}
end

function Mode.Begin(rt)
	for _, p in rt.players do
		rt.extra.coins[p.UserId] = 15
		rt.extra.mult[p.UserId] = 1
		rt.scores[p.UserId] = 15
	end
end

function Mode.Tick(rt, dt)
	rt.extra.acc = (rt.extra.acc or 0) + dt
	if rt.extra.acc >= 0.6 then
		rt.extra.acc = 0
		for _, p in rt.players do
			if not rt.alive[p.UserId] then
				continue
			end
			local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if not hrp then
				continue
			end
			for _, pad in rt.extra.pads do
				if (hrp.Position - pad.Position).Magnitude < 8 then
					local add = 1 * (rt.extra.mult[p.UserId] or 1)
					rt.extra.coins[p.UserId] += add
					rt.scores[p.UserId] = rt.extra.coins[p.UserId]
				end
			end
			local pet = rt.extra.pets[p.UserId]
			if pet and pet.Parent then
				pet.CFrame = pet.CFrame:Lerp(hrp.CFrame * CFrame.new(3, 1, 2), 0.18)
			end
		end
		rt.publicExtra.coins = rt.extra.coins
	end
end

function Mode.OnAction(rt, player, action, payload)
	if action == "buy" then
		local idx = tonumber(payload and payload.egg) or 1
		local egg = EGGS[idx]
		if not egg then
			return { ok = false }
		end
		if (rt.extra.coins[player.UserId] or 0) < egg.cost then
			return { ok = false, error = "Need " .. egg.cost }
		end
		rt.extra.coins[player.UserId] -= egg.cost
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local pet = AIUtil.ball(rt.folder, "Pet", (hrp and hrp.Position or rt.origin) + Vector3.new(2, 2, 2), egg.color, 0.9)
		if rt.extra.pets[player.UserId] then
			rt.extra.pets[player.UserId]:Destroy()
		end
		rt.extra.pets[player.UserId] = pet
		rt.extra.mult[player.UserId] = idx
		rt.announce(player.Name .. " hatched " .. egg.name)
		return { ok = true }
	elseif action == "equip" then
		return { ok = true, mult = rt.extra.mult[player.UserId] }
	end
	return { ok = false }
end

function Mode.Cleanup(rt)
	for _, pet in rt.extra.pets do
		if pet then
			pet:Destroy()
		end
	end
end

return Mode
