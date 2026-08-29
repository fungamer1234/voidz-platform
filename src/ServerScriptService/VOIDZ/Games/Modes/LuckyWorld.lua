--!strict

local MapUtil = require(script.Parent.Parent.MapUtil)
local AIUtil = require(script.Parent.Parent.AIUtil)

local Mode = {
	Id = "lucky_world",
	LobbySeconds = 5,
	MatchSeconds = 120,
	Respawn = 3,
	Actions = { "roll" },
	Objective = "Server-rolled drops. Highest pile at the horn wins.",
	Tips = { "2.2s cooldown.", "No Robux. Caps on jackpots." },
}

function Mode.Build(rt)
	local o = rt.origin
	MapUtil.arena(rt.folder, o, 110, 110, 12, Color3.fromRGB(36, 28, 50))
	rt.spawns = MapUtil.ringSpawns(rt.folder, o, 12, 28, 2)
	local wheel = MapUtil.part(rt.folder, {
		Name = "Wheel",
		Size = Vector3.new(14, 2, 14),
		CFrame = CFrame.new(o + Vector3.new(0, 2, 0)),
		Color = Color3.fromRGB(255, 190, 60),
		Material = Enum.Material.Neon,
		Shape = Enum.PartType.Cylinder,
	})
	wheel.Orientation = Vector3.new(0, 0, 90)
	MapUtil.label(wheel, "ROLL")
	rt.extra.wheel = wheel
	rt.extra.next = {}
	rt.extra.pets = {}
end

function Mode.Begin(rt)
	for _, p in rt.players do
		rt.scores[p.UserId] = 0
	end
	rt.announce("Honest wheel. No cashier.")
end

function Mode.Tick(rt, dt)
	if rt.extra.wheel then
		rt.extra.wheel.CFrame = rt.extra.wheel.CFrame * CFrame.Angles(dt * 0.6, 0, 0)
	end
	for uid, pet in rt.extra.pets do
		local p = nil
		for _, pl in rt.players do
			if pl.UserId == uid then
				p = pl
				break
			end
		end
		local hrp = p and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if hrp and pet and pet.Parent then
			pet.CFrame = pet.CFrame:Lerp(hrp.CFrame * CFrame.new(2.5, 1.5, 2), 0.2)
		end
	end
end

function Mode.OnAction(rt, player, action)
	if action ~= "roll" then
		return { ok = false }
	end
	if os.clock() < (rt.extra.next[player.UserId] or 0) then
		return { ok = false, error = "Wheel is spinning down." }
	end
	rt.extra.next[player.UserId] = os.clock() + 2.2
	local r = math.random()
	local result
	if r < 0.62 then
		local n = math.random(4, 12)
		rt.scores[player.UserId] = (rt.scores[player.UserId] or 0) + n
		result = "+" .. n .. " luck coins"
	elseif r < 0.82 then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = 28
			task.delay(6, function()
				if hum.Parent then
					hum.WalkSpeed = 16
				end
			end)
		end
		rt.scores[player.UserId] = (rt.scores[player.UserId] or 0) + 6
		result = "speed burst"
	elseif r < 0.94 then
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local pet = AIUtil.ball(rt.folder, "LuckPet", (hrp and hrp.Position or rt.origin) + Vector3.new(2, 2, 2), Color3.fromRGB(255, 140, 240), 0.8)
		if rt.extra.pets[player.UserId] then
			rt.extra.pets[player.UserId]:Destroy()
		end
		rt.extra.pets[player.UserId] = pet
		rt.scores[player.UserId] = (rt.scores[player.UserId] or 0) + 10
		result = "companion"
	else
		local n = math.random(20, 40)
		rt.scores[player.UserId] = (rt.scores[player.UserId] or 0) + n
		result = "jackpot +" .. n
		rt.announce(player.Name .. " hit a jackpot")
	end
	rt.event({ kind = "roll", userId = player.UserId, result = result })
	return { ok = true, result = result, score = rt.scores[player.UserId] }
end

return Mode
