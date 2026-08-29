--!strict

local Players = game:GetService("Players")
local MapUtil = require(script.Parent.Parent.MapUtil)
local AIUtil = require(script.Parent.Parent.AIUtil)

local COLORS = {
	Color3.fromRGB(255, 90, 160),
	Color3.fromRGB(120, 90, 255),
	Color3.fromRGB(80, 220, 160),
	Color3.fromRGB(255, 200, 70),
}

local Mode = {
	Id = "brain_snatch",
	LobbySeconds = 6,
	MatchSeconds = 150,
	Respawn = 4,
	Actions = { "drop", "lock" },
	Objective = "Bank Brains in your vault. Steal anyone who's carrying.",
	Tips = { "One Brain at a time.", "Lock after you bank.", "Pink Brains are worth 3." },
}

function Mode.Build(rt)
	local o = rt.origin
	MapUtil.arena(rt.folder, o, 180, 180, 18, Color3.fromRGB(24, 18, 32))
	MapUtil.light(rt.folder, o + Vector3.new(0, 20, 0), Color3.fromRGB(180, 80, 200), 60, 2)
	rt.spawns = MapUtil.ringSpawns(rt.folder, o, 16, 60, 2)
	rt.extra.plots = {}
	rt.extra.brains = {}
	rt.extra.carry = {}
	rt.extra.lockUntil = {}
	rt.extra.capacity = {}
	local n = math.max(4, #rt.players)
	for i = 1, n do
		local a = ((i - 1) / n) * math.pi * 2
		local pos = o + Vector3.new(math.cos(a) * 62, 2, math.sin(a) * 62)
		local pad = MapUtil.part(rt.folder, {
			Name = "Vault",
			Size = Vector3.new(14, 1, 14),
			CFrame = CFrame.new(pos),
			Color = COLORS[((i - 1) % #COLORS) + 1],
			Material = Enum.Material.Neon,
			Attr = { Plot = i },
		})
		MapUtil.label(pad, "VAULT " .. i)
		rt.extra.plots[i] = { pad = pad, owner = nil, stored = 0 }
	end
	for i = 1, 14 do
		local a = math.random() * math.pi * 2
		local r = 8 + math.random() * 50
		local rare = math.random() < 0.15
		local ball = AIUtil.ball(
			rt.folder,
			"Brain",
			o + Vector3.new(math.cos(a) * r, 4, math.sin(a) * r),
			if rare then Color3.fromRGB(255, 90, 200) else Color3.fromRGB(80, 255, 140),
			if rare then 1.4 else 1.05
		)
		ball:SetAttribute("Value", if rare then 3 else 1)
		AIUtil.attach(ball, {
			speed = if rare then 9 else 6,
			center = o + Vector3.new(0, 4, 0),
			radius = 55,
			state = "wander",
			repath = 0.9,
			yLock = o.Y + 4,
		})
		table.insert(rt.extra.brains, ball)
	end
end

function Mode.Begin(rt)
	for i, p in rt.players do
		local plot = rt.extra.plots[((i - 1) % #rt.extra.plots) + 1]
		if plot and not plot.owner then
			plot.owner = p.UserId
			MapUtil.label(plot.pad, p.Name)
		end
		rt.extra.capacity[p.UserId] = 8
		rt.extra.lockUntil[p.UserId] = 0
	end
	rt.announce("Brains are loose. Bank them.")
end

local function holding(rt, userId): BasePart?
	return rt.extra.carry[userId]
end

local function drop(rt, player)
	local b = rt.extra.carry[player.UserId]
	if b and b.Parent then
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		b.Anchored = true
		b.CFrame = CFrame.new((hrp and hrp.Position or rt.origin) + Vector3.new(0, 3, 0))
		AIUtil.attach(b, {
			speed = 6,
			center = rt.origin + Vector3.new(0, 4, 0),
			radius = 55,
			state = "wander",
			yLock = rt.origin.Y + 4,
		})
	end
	rt.extra.carry[player.UserId] = nil
	rt.publicExtra.carry = rt.publicExtra.carry or {}
	rt.publicExtra.carry[tostring(player.UserId)] = nil
end

function Mode.Tick(rt, dt)
	rt.extra.t = (rt.extra.t or 0) + dt
	if rt.extra.t > 45 and not rt.extra.event then
		rt.extra.event = true
		rt.announce("Chaos pulse — every Brain scatters!")
		for _, b in rt.extra.brains do
			if b.Parent and b.Anchored then
				b.CFrame = CFrame.new(rt.origin + Vector3.new((math.random() - 0.5) * 90, 4, (math.random() - 0.5) * 90))
			end
		end
	end
	for _, p in rt.players do
		if not rt.alive[p.UserId] then
			continue
		end
		local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then
			continue
		end
		local carry = holding(rt, p.UserId)
		if carry and carry.Parent then
			carry.CFrame = hrp.CFrame * CFrame.new(0, 3.2, 0)
			-- steal check
			for _, other in rt.players do
				if other ~= p and rt.alive[other.UserId] and not holding(rt, other.UserId) then
					local ohrp = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
					if ohrp and (ohrp.Position - hrp.Position).Magnitude < 4.5 then
						rt.extra.carry[p.UserId] = nil
						rt.extra.carry[other.UserId] = carry
						rt.announce(other.Name .. " snatched a Brain from " .. p.Name)
						rt.event({ kind = "steal", from = p.UserId, to = other.UserId })
						break
					end
				end
			end
		else
			for _, b in rt.extra.brains do
				if b.Parent and b.Anchored and (b.Position - hrp.Position).Magnitude < 4.2 then
					rt.extra.carry[p.UserId] = b
					break
				end
			end
		end
		local plot
		for _, pl in rt.extra.plots do
			if pl.owner == p.UserId then
				plot = pl
				break
			end
		end
		if plot and carry and (hrp.Position - plot.pad.Position).Magnitude < 9 then
			if os.clock() < (rt.extra.lockUntil[p.UserId] or 0) then
				-- locked, bounce
			else
				local val = carry:GetAttribute("Value") or 1
				plot.stored += val
				rt.scores[p.UserId] = (rt.scores[p.UserId] or 0) + val
				carry:Destroy()
				rt.extra.carry[p.UserId] = nil
				local RewardService = require(script.Parent.Parent.Parent.Services.RewardService)
				RewardService.Bump(p, "brain_snatch", "brains", val)
				local QuestService = require(script.Parent.Parent.Parent.Services.QuestService)
				QuestService.Add(p, "brains", val)
				if (rt.scores[p.UserId] or 0) >= 10 then
					local AchievementService = require(script.Parent.Parent.Parent.Services.AchievementService)
					AchievementService.Unlock(p, "brain_banker")
				end
				rt.announce(p.Name .. " banks +" .. tostring(val))
			end
		end
	end
	rt.publicExtra.scores = rt.scores
end

function Mode.OnAction(rt, player, action)
	if action == "drop" then
		drop(rt, player)
		return { ok = true }
	elseif action == "lock" then
		rt.extra.lockUntil[player.UserId] = os.clock() + 8
		rt.announce(player.Name .. " locked their vault.")
		return { ok = true }
	end
	return { ok = false }
end

function Mode.OnDied(rt, player)
	drop(rt, player)
end

function Mode.ShouldEnd(rt)
	for _, p in rt.players do
		if (rt.scores[p.UserId] or 0) >= 15 then
			return true, "cap"
		end
	end
	return false
end

function Mode.Cleanup(rt)
	rt.extra.brains = {}
end

return Mode
