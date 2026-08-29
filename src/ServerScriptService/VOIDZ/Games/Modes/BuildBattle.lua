--!strict

local MapUtil = require(script.Parent.Parent.MapUtil)

local THEMES = { "Haunted House", "Spaceship", "Fast Food", "Secret Base", "Dragon", "Rain Stall", "Lighthouse" }
local PALETTE = {
	Color3.fromRGB(220, 80, 80),
	Color3.fromRGB(80, 180, 90),
	Color3.fromRGB(70, 120, 220),
	Color3.fromRGB(240, 200, 70),
	Color3.fromRGB(160, 90, 220),
	Color3.fromRGB(230, 230, 235),
	Color3.fromRGB(40, 42, 48),
	Color3.fromRGB(180, 110, 60),
}

local Mode = {
	Id = "build_battle",
	LobbySeconds = 5,
	MatchSeconds = 95,
	Respawn = 4,
	Actions = { "place", "delete", "rotate", "vote" },
	Objective = "Build the theme. Then vote — not for yourself.",
	Tips = { "Grid snaps.", "Max 80 blocks.", "Voting starts automatically." },
}

function Mode.Build(rt)
	local o = rt.origin
	rt.extra.plots = {}
	rt.spawns = {}
	local n = math.max(2, #rt.players)
	for i = 1, n do
		local pos = o + Vector3.new((i - (n + 1) / 2) * 36, 1, 0)
		local pad = MapUtil.part(rt.folder, {
			Name = "Plot",
			Size = Vector3.new(28, 1, 28),
			CFrame = CFrame.new(pos),
			Color = Color3.fromRGB(50, 54, 64),
		})
		MapUtil.label(pad, "PLOT " .. i)
		table.insert(rt.spawns, CFrame.new(pos + Vector3.new(0, 5, 0)))
		rt.extra.plots[i] = { pad = pad, owner = nil, blocks = {}, origin = pos }
	end
	rt.extra.votes = {}
	rt.extra.voting = false
end

function Mode.Begin(rt)
	rt.extra.theme = THEMES[math.random(1, #THEMES)]
	rt.announce("Theme: " .. rt.extra.theme)
	rt.publicExtra.theme = rt.extra.theme
	rt.publicExtra.phase = "build"
	for i, p in rt.players do
		local plot = rt.extra.plots[((i - 1) % #rt.extra.plots) + 1]
		plot.owner = p.UserId
		MapUtil.label(plot.pad, p.Name)
		rt.scores[p.UserId] = 0
	end
	rt.extra.buildUntil = os.clock() + 55
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
	if not rt.extra.voting and os.clock() >= (rt.extra.buildUntil or 0) then
		rt.extra.voting = true
		rt.announce("Build over — vote for a plot.")
		rt.publicExtra.phase = "vote"
	end
end

function Mode.OnAction(rt, player, action, payload)
	payload = if type(payload) == "table" then payload else {}
	if action == "vote" then
		if not rt.extra.voting then
			return { ok = false, error = "Still building." }
		end
		local target = tonumber(payload.userId)
		if not target or target == player.UserId then
			return { ok = false, error = "Vote for someone else." }
		end
		rt.extra.votes[player.UserId] = target
		rt.scores[target] = (rt.scores[target] or 0) + 1
		return { ok = true }
	end
	if rt.extra.voting then
		return { ok = false, error = "Building is closed." }
	end
	local plot = plotOf(rt, player.UserId)
	if not plot then
		return { ok = false }
	end
	if action == "place" then
		if #plot.blocks >= 80 then
			return { ok = false, error = "Block cap." }
		end
		local gx = math.clamp(math.floor(tonumber(payload.x) or 0), -6, 6)
		local gy = math.clamp(math.floor(tonumber(payload.y) or 0), 0, 8)
		local gz = math.clamp(math.floor(tonumber(payload.z) or 0), -6, 6)
		local colorI = math.clamp(math.floor(tonumber(payload.color) or 1), 1, #PALETTE)
		local key = gx .. "," .. gy .. "," .. gz
		if plot.blocks[key] then
			return { ok = false, error = "Occupied." }
		end
		local part = MapUtil.part(rt.folder, {
			Name = "Block",
			Size = Vector3.new(2, 2, 2),
			CFrame = CFrame.new(plot.origin + Vector3.new(gx * 2, 2 + gy * 2, gz * 2)),
			Color = PALETTE[colorI],
		})
		plot.blocks[key] = part
		rt.scores[player.UserId] = (rt.scores[player.UserId] or 0)
		return { ok = true }
	elseif action == "delete" then
		local gx = math.floor(tonumber(payload.x) or 0)
		local gy = math.floor(tonumber(payload.y) or 0)
		local gz = math.floor(tonumber(payload.z) or 0)
		local key = gx .. "," .. gy .. "," .. gz
		local b = plot.blocks[key]
		if b then
			b:Destroy()
			plot.blocks[key] = nil
		end
		return { ok = true }
	elseif action == "rotate" then
		return { ok = true }
	end
	return { ok = false }
end

function Mode.ShouldEnd(rt)
	if not rt.extra.voting then
		return false
	end
	local voters = 0
	for _ in rt.extra.votes do
		voters += 1
	end
	return voters >= math.max(1, #rt.players - 0) and os.clock() > (rt.extra.buildUntil + 18), "vote"
end

return Mode
