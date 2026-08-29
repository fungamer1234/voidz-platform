--!strict
--[[
	Throttled AI: wander / chase / flee / patrol.
	Pathfinding is queued and never run every frame.
]]

local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")

local AIUtil = {}

local PATH_BUDGET = 2
local pathInFlight = 0
local agents: { any } = {}

local function hrpOf(model: Model): BasePart?
	return model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") :: BasePart?
end

function AIUtil.dummy(parent: Instance, name: string, at: CFrame, color: Color3, scale: number?): Model
	scale = scale or 1
	local m = Instance.new("Model")
	m.Name = name
	local function limb(nm: string, size: Vector3, cf: CFrame, col: Color3): Part
		local p = Instance.new("Part")
		p.Name = nm
		p.Size = size * scale
		p.CFrame = cf
		p.Color = col
		p.Anchored = false
		p.CanCollide = nm == "Torso" or nm == "HumanoidRootPart"
		p.Material = Enum.Material.SmoothPlastic
		p.Parent = m
		return p
	end
	local root = limb("HumanoidRootPart", Vector3.new(2, 2, 1), at, color)
	root.Transparency = 1
	local torso = limb("Torso", Vector3.new(2, 2, 1), at, color)
	local head = limb("Head", Vector3.new(1.2, 1.2, 1.2), at * CFrame.new(0, 1.5, 0), color:Lerp(Color3.new(1, 1, 1), 0.2))
	limb("LArm", Vector3.new(1, 2, 1), at * CFrame.new(-1.5, 0, 0), color)
	limb("RArm", Vector3.new(1, 2, 1), at * CFrame.new(1.5, 0, 0), color)
	limb("LLeg", Vector3.new(1, 2, 1), at * CFrame.new(-0.5, -2, 0), color:Lerp(Color3.new(0, 0, 0), 0.2))
	limb("RLeg", Vector3.new(1, 2, 1), at * CFrame.new(0.5, -2, 0), color:Lerp(Color3.new(0, 0, 0), 0.2))
	local hum = Instance.new("Humanoid")
	hum.WalkSpeed = 12
	hum.MaxHealth = 100
	hum.Health = 100
	hum.Parent = m
	m.PrimaryPart = root
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = torso
	weld.Parent = root
	for _, p in m:GetChildren() do
		if p:IsA("BasePart") and p ~= root and p ~= torso then
			local w = Instance.new("WeldConstraint")
			w.Part0 = torso
			w.Part1 = p
			w.Parent = torso
		end
	end
	m.Parent = parent
	return m
end

function AIUtil.ball(parent: Instance, name: string, at: Vector3, color: Color3, radius: number): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(radius * 2, radius * 2, radius * 2)
	p.Color = color
	p.Material = Enum.Material.Neon
	p.Anchored = true
	p.CanCollide = false
	p.CFrame = CFrame.new(at)
	p.Parent = parent
	return p
end

export type AgentOpts = {
	speed: number,
	center: Vector3,
	radius: number,
	state: string,
	repath: number?,
	detect: number?,
	getTarget: (() -> Vector3?)?,
	onTouch: ((BasePart) -> ())?,
	yLock: number?,
}

function AIUtil.attach(part: BasePart, opts: AgentOpts): any
	local agent = {
		part = part,
		opts = opts,
		state = opts.state or "wander",
		goal = opts.center,
		nextPath = 0,
		alive = true,
	}
	table.insert(agents, agent)
	return agent
end

function AIUtil.stop(agent: any)
	agent.alive = false
end

function AIUtil.clear()
	table.clear(agents)
end

local function wanderGoal(opts: AgentOpts): Vector3
	local a = math.random() * math.pi * 2
	local r = math.random() * opts.radius
	local y = opts.yLock or opts.center.Y
	return Vector3.new(opts.center.X + math.cos(a) * r, y, opts.center.Z + math.sin(a) * r)
end

local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.08 then
		return
	end
	local step = acc
	acc = 0
	local now = os.clock()
	for i = #agents, 1, -1 do
		local ag = agents[i]
		if not ag.alive or not ag.part or not ag.part.Parent then
			table.remove(agents, i)
			continue
		end
		local opts: AgentOpts = ag.opts
		if ag.state == "chase" and opts.getTarget then
			local t = opts.getTarget()
			if t then
				ag.goal = t
			else
				ag.state = "wander"
			end
		elseif ag.state == "flee" and opts.getTarget then
			local t = opts.getTarget()
			if t then
				local pos = ag.part.Position
				ag.goal = pos + (pos - t).Unit * 18
			else
				ag.state = "wander"
			end
		elseif now >= ag.nextPath then
			ag.goal = wanderGoal(opts)
			ag.nextPath = now + (opts.repath or 1.2) + math.random() * 0.4
		end
		local pos = ag.part.Position
		local dest = ag.goal
		if opts.yLock then
			dest = Vector3.new(dest.X, opts.yLock, dest.Z)
		end
		local delta = dest - pos
		local dist = delta.Magnitude
		if dist > 0.4 then
			local move = math.min(dist, opts.speed * step)
			local nxt = pos + delta.Unit * move
			if ag.part.Anchored then
				ag.part.CFrame = CFrame.new(nxt, nxt + delta.Unit)
			else
				local hum = ag.part.Parent and ag.part.Parent:FindFirstChildOfClass("Humanoid")
				if hum then
					hum:MoveTo(dest)
				end
			end
		end
	end
end)

function AIUtil.pathTo(model: Model, dest: Vector3, onDone: ((boolean) -> ())?)
	if pathInFlight >= PATH_BUDGET then
		if onDone then
			onDone(false)
		end
		return
	end
	local root = hrpOf(model)
	if not root then
		if onDone then
			onDone(false)
		end
		return
	end
	pathInFlight += 1
	task.spawn(function()
		local path = PathfindingService:CreatePath({
			AgentRadius = 2,
			AgentHeight = 5,
			AgentCanJump = true,
		})
		local ok = pcall(function()
			path:ComputeAsync(root.Position, dest)
		end)
		pathInFlight -= 1
		if not ok or path.Status ~= Enum.PathStatus.Success then
			if onDone then
				onDone(false)
			end
			return
		end
		local hum = model:FindFirstChildOfClass("Humanoid")
		if not hum then
			if onDone then
				onDone(false)
			end
			return
		end
		for _, wp in path:GetWaypoints() do
			if not model.Parent then
				break
			end
			hum:MoveTo(wp.Position)
			if wp.Action == Enum.PathWaypointAction.Jump then
				hum.Jump = true
			end
			hum.MoveToFinished:Wait()
		end
		if onDone then
			onDone(true)
		end
	end)
end

function AIUtil.nearestPlayer(from: Vector3, players: { Player }, maxDist: number): (Player?, Vector3?)
	local best: Player? = nil
	local bestPos: Vector3? = nil
	local bestD = maxDist
	for _, p in players do
		local char = p.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 then
			local d = (hrp.Position - from).Magnitude
			if d < bestD then
				bestD = d
				best = p
				bestPos = hrp.Position
			end
		end
	end
	return best, bestPos
end

return AIUtil
