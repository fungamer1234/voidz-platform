--!strict

local CollectionService = game:GetService("CollectionService")

local MapUtil = {}

MapUtil.ORIGIN = Vector3.new(0, 320, 4800)

function MapUtil.part(parent: Instance, props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = props.Anchored ~= false
	p.CanCollide = props.CanCollide ~= false
	p.CastShadow = props.CastShadow ~= false
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.Color = props.Color or Color3.fromRGB(40, 44, 58)
	p.Size = props.Size or Vector3.new(4, 1, 4)
	p.CFrame = props.CFrame or CFrame.new()
	p.Name = props.Name or "Part"
	p.Transparency = props.Transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if props.Shape then
		p.Shape = props.Shape
	end
	if props.Attr then
		for k, v in props.Attr do
			p:SetAttribute(k, v)
		end
	end
	if props.Tag then
		CollectionService:AddTag(p, props.Tag)
	end
	p.Parent = parent
	return p
end

function MapUtil.spawnPad(parent: Instance, cf: CFrame, color: Color3?): SpawnLocation
	local s = Instance.new("SpawnLocation")
	s.Name = "MatchSpawn"
	s.Size = Vector3.new(6, 1, 6)
	s.CFrame = cf
	s.Anchored = true
	s.Duration = 0
	s.Neutral = true
	s.Material = Enum.Material.Neon
	s.Color = color or Color3.fromRGB(124, 92, 255)
	s.TopSurface = Enum.SurfaceType.Smooth
	s.Parent = parent
	return s
end

function MapUtil.label(adornee: BasePart, text: string, face: Enum.NormalId?)
	local sg = Instance.new("SurfaceGui")
	sg.Face = face or Enum.NormalId.Top
	sg.PixelsPerStud = 20
	sg.Parent = adornee
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.GothamBold
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	t.Text = text
	t.Parent = sg
	return t
end

function MapUtil.light(parent: Instance, pos: Vector3, color: Color3, range: number, bright: number?)
	local a = MapUtil.part(parent, {
		Name = "Light",
		Size = Vector3.new(0.4, 0.4, 0.4),
		CFrame = CFrame.new(pos),
		Transparency = 1,
		CanCollide = false,
		CastShadow = false,
	})
	local pl = Instance.new("PointLight")
	pl.Color = color
	pl.Range = range
	pl.Brightness = bright or 1.4
	pl.Parent = a
	return a
end

function MapUtil.killBrick(parent: Instance, cf: CFrame, size: Vector3, name: string?): Part
	local p = MapUtil.part(parent, {
		Name = name or "Kill",
		Size = size,
		CFrame = cf,
		Color = Color3.fromRGB(180, 40, 50),
		Material = Enum.Material.Neon,
		Attr = { Kill = true },
		Tag = "VOIDZ_Kill",
	})
	return p
end

function MapUtil.arena(parent: Instance, origin: Vector3, width: number, depth: number, wallH: number, floorColor: Color3?): { floor: Part, walls: { Part } }
	local floor = MapUtil.part(parent, {
		Name = "Floor",
		Size = Vector3.new(width, 3, depth),
		CFrame = CFrame.new(origin),
		Color = floorColor or Color3.fromRGB(28, 32, 44),
		Material = Enum.Material.Slate,
	})
	local walls = {}
	local t = 3
	local specs = {
		{ Vector3.new(width, wallH, t), origin + Vector3.new(0, wallH / 2, depth / 2) },
		{ Vector3.new(width, wallH, t), origin + Vector3.new(0, wallH / 2, -depth / 2) },
		{ Vector3.new(t, wallH, depth), origin + Vector3.new(width / 2, wallH / 2, 0) },
		{ Vector3.new(t, wallH, depth), origin + Vector3.new(-width / 2, wallH / 2, 0) },
	}
	for i, sp in specs do
		walls[i] = MapUtil.part(parent, {
			Name = "Wall",
			Size = sp[1],
			CFrame = CFrame.new(sp[2]),
			Color = Color3.fromRGB(18, 20, 30),
		})
	end
	return { floor = floor, walls = walls }
end

function MapUtil.ringSpawns(parent: Instance, origin: Vector3, n: number, radius: number, y: number): { CFrame }
	local list = {}
	for i = 1, n do
		local a = ((i - 1) / n) * math.pi * 2
		local pos = origin + Vector3.new(math.cos(a) * radius, y, math.sin(a) * radius)
		local cf = CFrame.new(pos, origin + Vector3.new(0, y, 0))
		MapUtil.spawnPad(parent, cf, Color3.fromHSV(i / n, 0.6, 0.9))
		table.insert(list, cf + Vector3.new(0, 3, 0))
	end
	return list
end

function MapUtil.prompt(parent: Instance, text: string, action: string, distance: number?): ProximityPrompt
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText = action
	pr.ObjectText = text
	pr.HoldDuration = 0
	pr.MaxActivationDistance = distance or 10
	pr.RequiresLineOfSight = false
	pr.Parent = parent
	return pr
end

function MapUtil.folder(name: string, parent: Instance): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

return MapUtil
