--!strict
--[[
	Builds a compact night lobby around spawn.
	Game pedestals are tagged VOIDZGamePad with attribute GameId for client prompts.
]]

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VOIDZ = ReplicatedStorage:WaitForChild("VOIDZ")
local GameRegistry = require(VOIDZ.Shared.GameRegistry)
local ACCENT = Color3.fromRGB(124, 92, 255)
local MINT = Color3.fromRGB(46, 230, 166)
local BG = Color3.fromRGB(12, 14, 22)

local WorldService = {}

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = props.CanCollide ~= false
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.Color = props.Color or BG
	p.Size = props.Size or Vector3.new(4, 1, 4)
	p.CFrame = props.CFrame or CFrame.new()
	p.Name = props.Name or "Part"
	p.CastShadow = props.CastShadow ~= false
	if props.Transparency then
		p.Transparency = props.Transparency
	end
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = props.Parent
	return p
end

local function neonStrip(parent: Instance, cf: CFrame, size: Vector3, color: Color3)
	local p = part({
		Parent = parent,
		CFrame = cf,
		Size = size,
		Color = color,
		Material = Enum.Material.Neon,
		Name = "Neon",
		CanCollide = false,
		CastShadow = false,
	})
	return p
end

local function applyLighting()
	Lighting.ClockTime = 21.4
	Lighting.Brightness = 1.35
	Lighting.Ambient = Color3.fromRGB(22, 18, 40)
	Lighting.OutdoorAmbient = Color3.fromRGB(28, 26, 55)
	Lighting.FogColor = Color3.fromRGB(10, 8, 22)
	Lighting.FogStart = 40
	Lighting.FogEnd = 420
	Lighting.EnvironmentDiffuseScale = 0.4
	Lighting.EnvironmentSpecularScale = 0.6
	pcall(function()
		Lighting.Technology = Enum.Technology.ShadowMap
	end)
	local function ensure(className: string, name: string, apply: (Instance) -> ())
		local inst = Lighting:FindFirstChild(name)
		if not inst then
			inst = Instance.new(className)
			inst.Name = name
			inst.Parent = Lighting
		end
		apply(inst)
	end
	ensure("Atmosphere", "VOIDZ_Atmosphere", function(i)
		local a = i :: Atmosphere
		a.Density = 0.28
		a.Offset = 0.2
		a.Color = Color3.fromRGB(40, 32, 70)
		a.Decay = Color3.fromRGB(12, 10, 24)
		a.Glare = 0.15
		a.Haze = 1.4
	end)
	ensure("BloomEffect", "VOIDZ_Bloom", function(i)
		local b = i :: BloomEffect
		b.Intensity = 0.6
		b.Size = 22
		b.Threshold = 0.85
	end)
	ensure("ColorCorrectionEffect", "VOIDZ_CC", function(i)
		local c = i :: ColorCorrectionEffect
		c.Saturation = 0.08
		c.Contrast = 0.08
		c.TintColor = Color3.fromRGB(235, 230, 255)
	end)
	ensure("DepthOfFieldEffect", "VOIDZ_DoF", function(i)
		local d = i :: DepthOfFieldEffect
		d.FarIntensity = 0.18
		d.FocusDistance = 40
		d.InFocusRadius = 50
		d.NearIntensity = 0.05
	end)
end

function WorldService.Build()
	applyLighting()
	local existing = workspace:FindFirstChild("VOIDZ_World")
	if existing then
		existing:Destroy()
	end
	local world = Instance.new("Folder")
	world.Name = "VOIDZ_World"
	world.Parent = workspace

	-- Remove default baseplate if present so the lobby owns the floor.
	local bp = workspace:FindFirstChild("Baseplate")
	if bp and bp:IsA("BasePart") then
		bp:Destroy()
	end
	local spawnOld = workspace:FindFirstChildOfClass("SpawnLocation")
	if spawnOld then
		spawnOld:Destroy()
	end

	local floor = part({
		Parent = world,
		Name = "Floor",
		Size = Vector3.new(240, 4, 240),
		CFrame = CFrame.new(0, -2, 0),
		Color = Color3.fromRGB(16, 18, 28),
		Material = Enum.Material.Slate,
	})

	-- Grid of faint tiles
	for x = -4, 4 do
		for z = -4, 4 do
			if (x + z) % 2 == 0 then
				part({
					Parent = world,
					Name = "Tile",
					Size = Vector3.new(22, 0.2, 22),
					CFrame = CFrame.new(x * 24, 0.12, z * 24),
					Color = Color3.fromRGB(22, 24, 36),
					CanCollide = false,
					CastShadow = false,
				})
			end
		end
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "VOIDZ_Spawn"
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.CFrame = CFrame.new(0, 0.6, 8)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Color = Color3.fromRGB(28, 24, 48)
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = world
	local spawnCorner = Instance.new("CylinderHandleAdornment")
	spawnCorner.Adornee = spawn
	spawnCorner.Transparency = 1
	spawnCorner.Parent = spawn
	neonStrip(world, CFrame.new(0, 0.22, 8), Vector3.new(12.4, 0.18, 12.4), ACCENT)

	-- Central ring
	local ring = Instance.new("Part")
	ring.Name = "Ring"
	ring.Anchored = true
	ring.CanCollide = false
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.4, 28, 28)
	ring.CFrame = CFrame.new(0, 0.4, 0) * CFrame.Angles(0, 0, math.rad(90))
	ring.Material = Enum.Material.Neon
	ring.Color = ACCENT
	ring.Parent = world

	-- Logo monument
	local monument = part({
		Parent = world,
		Name = "Monument",
		Size = Vector3.new(18, 10, 2),
		CFrame = CFrame.new(0, 5, -28),
		Color = Color3.fromRGB(18, 16, 30),
	})
	neonStrip(world, CFrame.new(0, 10.2, -28), Vector3.new(18, 0.3, 2.2), MINT)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.PixelsPerStud = 20
	gui.Parent = monument
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromScale(1, 0.7)
	title.Font = Enum.Font.GothamBlack
	title.Text = "VOIDZ"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Parent = gui
	local sub = Instance.new("TextLabel")
	sub.BackgroundTransparency = 1
	sub.Position = UDim2.fromScale(0, 0.68)
	sub.Size = UDim2.fromScale(1, 0.28)
	sub.Font = Enum.Font.Gotham
	sub.Text = "A UNIVERSE OF GAMES"
	sub.TextColor3 = MINT
	sub.TextScaled = true
	sub.Parent = gui

	-- Side walls / arches
	for _, x in { -70, 70 } do
		part({
			Parent = world,
			Name = "Pillar",
			Size = Vector3.new(4, 28, 4),
			CFrame = CFrame.new(x, 14, -20),
			Color = Color3.fromRGB(20, 22, 34),
		})
		neonStrip(world, CFrame.new(x, 28.4, -20), Vector3.new(4.4, 0.4, 4.4), ACCENT)
	end
	part({
		Parent = world,
		Name = "Arch",
		Size = Vector3.new(144, 3, 3),
		CFrame = CFrame.new(0, 27, -20),
		Color = Color3.fromRGB(24, 20, 40),
	})

	-- Ambient lights
	local function light(at: Vector3, color: Color3, bright: number, range: number)
		local a = Instance.new("Part")
		a.Name = "LightAnchor"
		a.Anchored = true
		a.CanCollide = false
		a.Transparency = 1
		a.Size = Vector3.new(0.4, 0.4, 0.4)
		a.Position = at
		a.Parent = world
		local pl = Instance.new("PointLight")
		pl.Color = color
		pl.Brightness = bright
		pl.Range = range
		pl.Parent = a
	end
	light(Vector3.new(0, 12, 0), ACCENT, 2.2, 40)
	light(Vector3.new(0, 10, -28), MINT, 1.6, 28)
	light(Vector3.new(24, 8, 16), Color3.fromRGB(80, 120, 255), 1.2, 24)
	light(Vector3.new(-24, 8, 16), Color3.fromRGB(255, 90, 140), 1.2, 24)

	-- Showcase pedestals in an arc
	local showcase = GameRegistry.GetAll()
	local count = math.min(8, #showcase)
	for i = 1, count do
		local g = showcase[i]
		local t = (i - 1) / math.max(1, count - 1)
		local angle = math.rad(-70 + 140 * t)
		local radius = 36
		local pos = Vector3.new(math.sin(angle) * radius, 0, 18 + math.cos(angle) * 10)
		local accent = Color3.new(g.Accent[1], g.Accent[2], g.Accent[3])
		local base = part({
			Parent = world,
			Name = "Pedestal_" .. g.Id,
			Size = Vector3.new(6, 1.2, 6),
			CFrame = CFrame.new(pos + Vector3.new(0, 0.6, 0)),
			Color = Color3.fromRGB(22, 24, 38),
		})
		neonStrip(world, CFrame.new(pos + Vector3.new(0, 1.28, 0)), Vector3.new(6.2, 0.16, 6.2), accent)
		local screen = part({
			Parent = world,
			Name = "Screen_" .. g.Id,
			Size = Vector3.new(7, 4.4, 0.4),
			CFrame = CFrame.new(pos + Vector3.new(0, 4.2, -0.4)),
			Color = Color3.fromRGB(10, 12, 18),
		})
		CollectionService:AddTag(screen, "VOIDZGamePad")
		screen:SetAttribute("GameId", g.Id)
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Open"
		prompt.ObjectText = g.Name
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false
		prompt.Parent = screen
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Front
		sg.PixelsPerStud = 25
		sg.Parent = screen
		local bg = Instance.new("Frame")
		bg.Size = UDim2.fromScale(1, 1)
		bg.BorderSizePixel = 0
		bg.BackgroundColor3 = Color3.new(g.Accent[1] * 0.25, g.Accent[2] * 0.25, g.Accent[3] * 0.25)
		bg.Parent = sg
		local grad = Instance.new("UIGradient")
		grad.Color = ColorSequence.new(accent, Color3.new(g.Accent2[1], g.Accent2[2], g.Accent2[3]))
		grad.Rotation = 45
		grad.Parent = bg
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.GothamBold
		label.Text = g.Name
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextScaled = true
		label.Parent = sg
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 12)
		pad.PaddingRight = UDim.new(0, 12)
		pad.Parent = label
		light(pos + Vector3.new(0, 6, 0), accent, 1.1, 16)
	end

	-- Avatar studio pad
	local studio = part({
		Parent = world,
		Name = "AvatarPad",
		Size = Vector3.new(16, 1, 16),
		CFrame = CFrame.new(48, 0.5, 8),
		Color = Color3.fromRGB(24, 20, 40),
	})
	neonStrip(world, CFrame.new(48, 1.15, 8), Vector3.new(16.4, 0.16, 16.4), MINT)
	CollectionService:AddTag(studio, "VOIDZAvatarPad")
	local sg2 = Instance.new("SurfaceGui")
	sg2.Face = Enum.NormalId.Top
	sg2.PixelsPerStud = 12
	sg2.Parent = studio
	local t2 = Instance.new("TextLabel")
	t2.BackgroundTransparency = 1
	t2.Size = UDim2.fromScale(1, 1)
	t2.Font = Enum.Font.GothamBold
	t2.Text = "AVATAR STUDIO"
	t2.TextColor3 = Color3.new(1, 1, 1)
	t2.TextTransparency = 0.2
	t2.TextScaled = true
	t2.Parent = sg2

	-- Subtle floating cubes
	for i = 1, 10 do
		local c = part({
			Parent = world,
			Name = "Floater",
			Size = Vector3.new(1.4, 1.4, 1.4),
			CFrame = CFrame.new((math.random() - 0.5) * 80, 8 + math.random() * 10, (math.random() - 0.5) * 80),
			Color = if i % 2 == 0 then ACCENT else MINT,
			Material = Enum.Material.Neon,
			CanCollide = false,
			CastShadow = false,
		})
		c.Transparency = 0.35
	end

	-- Soft barrier walls so players don't walk into fog
	for _, cf in {
		CFrame.new(0, 10, -118),
		CFrame.new(0, 10, 118),
		CFrame.new(-118, 10, 0) * CFrame.Angles(0, math.rad(90), 0),
		CFrame.new(118, 10, 0) * CFrame.Angles(0, math.rad(90), 0),
	} do
		part({
			Parent = world,
			Name = "Barrier",
			Size = Vector3.new(240, 24, 2),
			CFrame = cf,
			Color = Color3.fromRGB(8, 8, 16),
			Transparency = 0.35,
		})
	end

	-- Keep default character scripts; just tag spawn.
	Players.CharacterAutoLoads = true
end

return WorldService
