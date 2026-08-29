--!strict

local MapUtil = require(script.Parent.Parent.MapUtil)
local AIUtil = require(script.Parent.Parent.AIUtil)

local Mode = {
	Id = "haunted_shift",
	LobbySeconds = 6,
	MatchSeconds = 150,
	Respawn = 0,
	Actions = { "hide", "revive", "sprint" },
	Objective = "Finish every terminal. Don't get caught. Then hit the exit.",
	Tips = { "Hide in lockers.", "Revive downed teammates.", "The stalker pathfinds." },
}

function Mode.Build(rt)
	local o = rt.origin
	MapUtil.arena(rt.folder, o, 90, 90, 18, Color3.fromRGB(18, 16, 22))
	rt.extra.rooms = {}
	rt.extra.tasks = {}
	rt.extra.done = {}
	rt.extra.hidden = {}
	rt.extra.down = {}
	for x = -1, 1 do
		for z = -1, 1 do
			if not (x == 0 and z == 0) then
				local pos = o + Vector3.new(x * 26, 5, z * 26)
				MapUtil.part(rt.folder, {
					Name = "Room",
					Size = Vector3.new(20, 10, 20),
					CFrame = CFrame.new(pos),
					Color = Color3.fromRGB(28, 24, 34),
					Transparency = 0.85,
					CanCollide = false,
				})
				local locker = MapUtil.part(rt.folder, {
					Name = "Locker",
					Size = Vector3.new(3, 7, 3),
					CFrame = CFrame.new(pos + Vector3.new(7, 0, 7)),
					Color = Color3.fromRGB(40, 40, 50),
					Attr = { Locker = true },
				})
				MapUtil.label(locker, "HIDE")
				local term = MapUtil.part(rt.folder, {
					Name = "Terminal",
					Size = Vector3.new(3, 4, 1),
					CFrame = CFrame.new(pos + Vector3.new(-6, -1, 0)),
					Color = Color3.fromRGB(80, 160, 255),
					Material = Enum.Material.Neon,
					Attr = { Task = true },
				})
				table.insert(rt.extra.tasks, term)
			end
		end
	end
	local exit = MapUtil.part(rt.folder, {
		Name = "Exit",
		Size = Vector3.new(10, 12, 2),
		CFrame = CFrame.new(o + Vector3.new(0, 7, -44)),
		Color = Color3.fromRGB(80, 255, 140),
		Material = Enum.Material.Neon,
		Attr = { Exit = true },
	})
	MapUtil.label(exit, "EXIT")
	rt.extra.exit = exit
	rt.spawns = MapUtil.ringSpawns(rt.folder, o, 8, 12, 2)
	local stalker = AIUtil.dummy(rt.folder, "Stalker", CFrame.new(o + Vector3.new(0, 4, 30)), Color3.fromRGB(20, 0, 0), 1.15)
	local hum = stalker:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = 15
		hum.DisplayName = "Stalker"
	end
	rt.extra.stalker = stalker
	rt.extra.nextPath = 0
end

function Mode.Begin(rt)
	rt.announce("Lights flicker. Finish the terminals.")
	rt.publicExtra.tasks = 0
	rt.publicExtra.need = #rt.extra.tasks
end

function Mode.Tick(rt, dt)
	local st = rt.extra.stalker
	if st and st.Parent and os.clock() >= rt.extra.nextPath then
		rt.extra.nextPath = os.clock() + 1.1
		local root = st.PrimaryPart
		if root then
			local ply, pos = AIUtil.nearestPlayer(root.Position, rt.players, 70)
			if ply and pos and not rt.extra.hidden[ply.UserId] then
				AIUtil.pathTo(st, pos)
				if (root.Position - pos).Magnitude < 5 then
					local hum = ply.Character and ply.Character:FindFirstChildOfClass("Humanoid")
					if hum and hum.Health > 0 then
						rt.extra.down[ply.UserId] = true
						rt.alive[ply.UserId] = false
						hum.Health = 0
						rt.announce("The stalker caught " .. ply.Name)
					end
				end
			else
				AIUtil.pathTo(st, rt.origin + Vector3.new((math.random() - 0.5) * 40, 3, (math.random() - 0.5) * 40))
			end
		end
	end
	local done = 0
	for _, t in rt.extra.tasks do
		if t:GetAttribute("Done") then
			done += 1
		end
	end
	rt.publicExtra.tasks = done
	rt.extra.doneCount = done
	if done >= #rt.extra.tasks then
		rt.extra.canExit = true
		rt.publicExtra.canExit = true
	end
	for _, p in rt.players do
		if rt.alive[p.UserId] then
			rt.scores[p.UserId] = done * 10 + (if rt.extra.canExit then 5 else 0)
			local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				for _, t in rt.extra.tasks do
					if not t:GetAttribute("Done") and (hrp.Position - t.Position).Magnitude < 6 then
						t:SetAttribute("Progress", (t:GetAttribute("Progress") or 0) + dt)
						if (t:GetAttribute("Progress") or 0) >= 2.2 then
							t:SetAttribute("Done", true)
							t.Color = Color3.fromRGB(80, 255, 140)
							rt.announce("Terminal complete")
						end
					end
				end
				if rt.extra.canExit and (hrp.Position - rt.extra.exit.Position).Magnitude < 8 then
					rt.extra.escaped = rt.extra.escaped or {}
					rt.extra.escaped[p.UserId] = true
					rt.scores[p.UserId] = (rt.scores[p.UserId] or 0) + 40
				end
			end
		end
	end
end

function Mode.OnAction(rt, player, action)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if action == "hide" then
		rt.extra.hidden[player.UserId] = not rt.extra.hidden[player.UserId]
		if hrp then
			hrp.Anchored = rt.extra.hidden[player.UserId] == true
		end
		return { ok = true, hidden = rt.extra.hidden[player.UserId] }
	elseif action == "sprint" then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = 24
			task.delay(1.5, function()
				if hum.Parent then
					hum.WalkSpeed = 16
				end
			end)
		end
		return { ok = true }
	elseif action == "revive" then
		if not hrp then
			return { ok = false }
		end
		for _, o in rt.players do
			if rt.extra.down[o.UserId] then
				local ohrp = o.Character and o.Character:FindFirstChild("HumanoidRootPart")
				if ohrp and (ohrp.Position - hrp.Position).Magnitude < 8 then
					rt.extra.down[o.UserId] = nil
					o:LoadCharacter()
					task.wait(0.2)
					rt.alive[o.UserId] = true
					rt.teleport(o, hrp.CFrame + Vector3.new(3, 0, 0))
					rt.announce(player.Name .. " revived " .. o.Name)
					return { ok = true }
				end
			end
		end
		return { ok = false, error = "No one to revive." }
	end
	return { ok = false }
end

function Mode.ShouldEnd(rt)
	local alive = 0
	for _, p in rt.players do
		if rt.alive[p.UserId] then
			alive += 1
		end
	end
	if alive == 0 then
		return true, "wiped"
	end
	if rt.extra.escaped then
		local n = 0
		for _ in rt.extra.escaped do
			n += 1
		end
		if n >= math.max(1, alive) then
			return true, "escape"
		end
	end
	return false
end

return Mode
