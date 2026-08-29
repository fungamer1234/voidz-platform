--!strict

local MapUtil = require(script.Parent.Parent.MapUtil)

local Mode = {
	Id = "grab_and_go",
	LobbySeconds = 5,
	MatchSeconds = 130,
	Respawn = 4,
	Actions = { "grab", "dash", "extract" },
	Objective = "Grab loot, extract it. Getting tagged drops the bag.",
	Tips = { "Extract pads glow gold.", "Dash has a cooldown." },
}

function Mode.Build(rt)
	local o = rt.origin
	MapUtil.arena(rt.folder, o, 130, 130, 14, Color3.fromRGB(32, 36, 30))
	rt.spawns = MapUtil.ringSpawns(rt.folder, o, 12, 50, 2)
	rt.extra.loot = {}
	rt.extra.carry = {}
	rt.extra.dash = {}
	for i = 1, 10 do
		local p = MapUtil.part(rt.folder, {
			Name = "Loot",
			Size = Vector3.new(2.4, 2.4, 2.4),
			CFrame = CFrame.new(o + Vector3.new((math.random() - 0.5) * 90, 3, (math.random() - 0.5) * 90)),
			Color = Color3.fromRGB(255, 210, 70),
			Material = Enum.Material.Neon,
			CanCollide = false,
			Attr = { Value = if math.random() < 0.2 then 5 else 2 },
		})
		table.insert(rt.extra.loot, p)
	end
	rt.extra.extracts = {}
	for i = 1, 4 do
		local a = ((i - 1) / 4) * math.pi * 2
		local pad = MapUtil.part(rt.folder, {
			Name = "Extract",
			Size = Vector3.new(12, 1, 12),
			CFrame = CFrame.new(o + Vector3.new(math.cos(a) * 52, 2, math.sin(a) * 52)),
			Color = Color3.fromRGB(255, 180, 40),
			Material = Enum.Material.Neon,
		})
		MapUtil.label(pad, "EXTRACT")
		table.insert(rt.extra.extracts, pad)
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
		local bag = rt.extra.carry[p.UserId]
		if bag and bag.Parent then
			bag.CFrame = hrp.CFrame * CFrame.new(0, 3, -1)
			for _, o in rt.players do
				if o ~= p and rt.alive[o.UserId] and not rt.extra.carry[o.UserId] then
					local ohrp = o.Character and o.Character:FindFirstChild("HumanoidRootPart")
					if ohrp and (ohrp.Position - hrp.Position).Magnitude < 4.2 then
						rt.extra.carry[p.UserId] = nil
						rt.extra.carry[o.UserId] = bag
						rt.announce(o.Name .. " tagged the bag")
					end
				end
			end
			for _, pad in rt.extra.extracts do
				if (hrp.Position - pad.Position).Magnitude < 8 then
					local val = bag:GetAttribute("Value") or 2
					rt.scores[p.UserId] = (rt.scores[p.UserId] or 0) + val
					bag:Destroy()
					rt.extra.carry[p.UserId] = nil
					rt.announce(p.Name .. " extracted +" .. val)
				end
			end
		end
	end
end

function Mode.OnAction(rt, player, action)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return { ok = false }
	end
	if action == "grab" then
		if rt.extra.carry[player.UserId] then
			return { ok = false, error = "Already carrying." }
		end
		for _, loot in rt.extra.loot do
			if loot.Parent and (loot.Position - hrp.Position).Magnitude < 6 then
				rt.extra.carry[player.UserId] = loot
				return { ok = true }
			end
		end
		return { ok = false, error = "Nothing in range." }
	elseif action == "dash" then
		if os.clock() < (rt.extra.dash[player.UserId] or 0) then
			return { ok = false, error = "Dash cooling down." }
		end
		rt.extra.dash[player.UserId] = os.clock() + 3
		hrp.AssemblyLinearVelocity = hrp.CFrame.LookVector * 60 + Vector3.new(0, 8, 0)
		return { ok = true }
	elseif action == "extract" then
		return { ok = true }
	end
	return { ok = false }
end

function Mode.OnDied(rt, player)
	local bag = rt.extra.carry[player.UserId]
	if bag and bag.Parent then
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		bag.CFrame = CFrame.new((hrp and hrp.Position or rt.origin) + Vector3.new(0, 3, 0))
	end
	rt.extra.carry[player.UserId] = nil
end

return Mode
