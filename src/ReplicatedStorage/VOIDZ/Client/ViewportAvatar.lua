--!strict
--[[
	Builds a local dummy inside a ViewportFrame + WorldModel.
	Does not touch the player's live character.
]]

local AvatarCatalog = require(script.Parent.Parent.Shared.AvatarCatalog)
local Config = require(script.Parent.Parent.Shared.Config)
local Validate = require(script.Parent.Parent.Shared.Validate)
local Theme = require(script.Parent.Theme)

local ViewportAvatar = {}

local function col(t: { number }): Color3
	return Color3.new(t[1], t[2], t[3])
end

local function limb(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.SmoothPlastic
	p.Color = color
	p.Size = size
	p.CFrame = cf
	p.CastShadow = false
	p.Parent = parent
	return p
end

local function attach(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CastShadow = false
	p.Material = material or Enum.Material.SmoothPlastic
	p.Color = color
	p.Size = size
	p.CFrame = cf
	p.Parent = parent
	return p
end

local function faceDeco(model: Model, style: string, head: BasePart)
	local function dot(name: string, size: Vector3, off: CFrame, color: Color3)
		attach(model, name, size, head.CFrame * off, color)
	end
	dot("EyeL", Vector3.new(0.22, 0.22, 0.12), CFrame.new(-0.28, 0.12, -0.55), Color3.new(0.08, 0.08, 0.1))
	dot("EyeR", Vector3.new(0.22, 0.22, 0.12), CFrame.new(0.28, 0.12, -0.55), Color3.new(0.08, 0.08, 0.1))
	if style == "smile" or style == "cheer" then
		attach(model, "Mouth", Vector3.new(0.42, 0.1, 0.1), head.CFrame * CFrame.new(0, -0.28, -0.55), Color3.new(0.4, 0.12, 0.16))
	elseif style == "cool" then
		attach(model, "ShadesBar", Vector3.new(1.1, 0.16, 0.16), head.CFrame * CFrame.new(0, 0.12, -0.52), Color3.new(0.05, 0.05, 0.06), Enum.Material.SmoothPlastic)
	elseif style == "focus" or style == "determined" then
		attach(model, "Brow", Vector3.new(0.9, 0.08, 0.08), head.CFrame * CFrame.new(0, 0.32, -0.52), Color3.new(0.1, 0.1, 0.1))
		attach(model, "Mouth", Vector3.new(0.28, 0.08, 0.08), head.CFrame * CFrame.new(0, -0.26, -0.55), Color3.new(0.2, 0.12, 0.12))
	else
		attach(model, "Mouth", Vector3.new(0.28, 0.08, 0.08), head.CFrame * CFrame.new(0, -0.26, -0.55), Color3.new(0.2, 0.12, 0.12))
	end
end

local function hairFor(model: Model, style: string, color: Color3, head: BasePart)
	if style == "short" or style == "buzz" then
		attach(model, "Hair", Vector3.new(1.35, 0.35, 1.25), head.CFrame * CFrame.new(0, 0.55, 0), color)
	elseif style == "spiky" then
		for i = -1, 1 do
			attach(model, "Spike", Vector3.new(0.28, 0.9, 0.28), head.CFrame * CFrame.new(i * 0.32, 0.9, -0.1), color)
		end
	elseif style == "long" then
		attach(model, "HairTop", Vector3.new(1.4, 0.4, 1.3), head.CFrame * CFrame.new(0, 0.55, 0), color)
		attach(model, "HairBack", Vector3.new(1.1, 1.6, 0.4), head.CFrame * CFrame.new(0, -0.4, 0.55), color)
	elseif style == "wavy" then
		attach(model, "Hair", Vector3.new(1.5, 0.5, 1.35), head.CFrame * CFrame.new(0.1, 0.5, 0), color)
	elseif style == "pony" then
		attach(model, "HairTop", Vector3.new(1.35, 0.4, 1.25), head.CFrame * CFrame.new(0, 0.55, 0), color)
		attach(model, "Tail", Vector3.new(0.35, 1.4, 0.35), head.CFrame * CFrame.new(0, -0.2, 0.7), color)
	elseif style == "mohawk" then
		attach(model, "Hawk", Vector3.new(0.28, 1.1, 1.1), head.CFrame * CFrame.new(0, 0.85, 0), color)
	end
end

local function extra(model: Model, equipped: { [string]: string }, head: BasePart, torso: BasePart)
	local function item(slot: string): AvatarCatalog.ItemDef?
		local id = equipped[slot]
		if type(id) == "string" then
			return AvatarCatalog.Get(id)
		end
		return nil
	end
	local hat = item("hat")
	if hat and hat.Style ~= "none" then
		local c = AvatarCatalog.Color(hat)
		if hat.Style == "cap" then
			attach(model, "Hat", Vector3.new(1.5, 0.28, 1.5), head.CFrame * CFrame.new(0, 0.72, 0), c)
			attach(model, "Brim", Vector3.new(1.5, 0.1, 0.7), head.CFrame * CFrame.new(0, 0.58, -0.7), c)
		elseif hat.Style == "beanie" then
			attach(model, "Hat", Vector3.new(1.45, 0.55, 1.45), head.CFrame * CFrame.new(0, 0.7, 0), c)
		elseif hat.Style == "crown" then
			attach(model, "Hat", Vector3.new(1.3, 0.18, 1.3), head.CFrame * CFrame.new(0, 0.85, 0), c, Enum.Material.Neon)
		elseif hat.Style == "visor" then
			attach(model, "Hat", Vector3.new(1.3, 0.16, 0.7), head.CFrame * CFrame.new(0, 0.18, -0.5), c, Enum.Material.Neon)
		elseif hat.Style == "helm" then
			attach(model, "Hat", Vector3.new(1.5, 1.1, 1.5), head.CFrame * CFrame.new(0, 0.2, 0), c)
		end
	end
	local acc = item("accessory")
	if acc and acc.Style ~= "none" then
		local c = AvatarCatalog.Color(acc)
		if acc.Style == "shades" then
			attach(model, "Acc", Vector3.new(1.2, 0.18, 0.18), head.CFrame * CFrame.new(0, 0.1, -0.55), c)
		elseif acc.Style == "comm" then
			attach(model, "Acc", Vector3.new(0.25, 0.4, 0.25), head.CFrame * CFrame.new(0.7, 0, 0), c)
		elseif acc.Style == "scarf" then
			attach(model, "Acc", Vector3.new(1.4, 0.35, 1.1), torso.CFrame * CFrame.new(0, 0.7, 0), c)
		elseif acc.Style == "chain" then
			attach(model, "Acc", Vector3.new(0.7, 0.12, 0.7), torso.CFrame * CFrame.new(0, 0.55, -0.5), c, Enum.Material.Metal)
		elseif acc.Style == "mask" then
			attach(model, "Acc", Vector3.new(1.05, 0.45, 0.35), head.CFrame * CFrame.new(0, -0.2, -0.5), c)
		end
	end
	local back = item("back")
	if back and back.Style ~= "none" then
		local c = AvatarCatalog.Color(back)
		if back.Style == "pack" then
			attach(model, "Back", Vector3.new(1.2, 1.4, 0.55), torso.CFrame * CFrame.new(0, 0.1, 0.8), c)
		elseif back.Style == "cape" then
			attach(model, "Back", Vector3.new(1.6, 2.2, 0.2), torso.CFrame * CFrame.new(0, -0.4, 0.75), c)
		elseif back.Style == "wings" then
			attach(model, "WingL", Vector3.new(0.25, 1.8, 1.4), torso.CFrame * CFrame.new(-1.1, 0.2, 0.6), c, Enum.Material.Neon)
			attach(model, "WingR", Vector3.new(0.25, 1.8, 1.4), torso.CFrame * CFrame.new(1.1, 0.2, 0.6), c, Enum.Material.Neon)
		end
	end
	local fx = item("effect")
	if fx and fx.Style ~= "none" then
		local att = Instance.new("Part")
		att.Name = "FX"
		att.Anchored = true
		att.CanCollide = false
		att.Transparency = 1
		att.Size = Vector3.new(0.2, 0.2, 0.2)
		att.CFrame = torso.CFrame
		att.Parent = model
		local pe = Instance.new("ParticleEmitter")
		pe.Rate = 10
		pe.Lifetime = NumberRange.new(0.6, 1.2)
		pe.Speed = NumberRange.new(0.4, 1.4)
		pe.Size = NumberSequence.new(0.2, 0)
		pe.LightEmission = 0.6
		pe.Color = ColorSequence.new(AvatarCatalog.Color(fx))
		if fx.Style == "void" then
			pe.Acceleration = Vector3.new(0, 2, 0)
		elseif fx.Style == "ember" then
			pe.Acceleration = Vector3.new(0, 1, 0)
		end
		pe.Parent = att
	end
end

function ViewportAvatar.BuildModel(equipped: any, skinTone: any): Model
	equipped = equipped or Config.DefaultAvatar
	local tone = Validate.skinTone(skinTone)
	local skin = col(tone)
	local shirtDef = AvatarCatalog.Get(equipped.shirt or "shirt_core")
	local pantsDef = AvatarCatalog.Get(equipped.pants or "pants_core")
	local hairDef = AvatarCatalog.Get(equipped.hair or "hair_short")
	local faceDef = AvatarCatalog.Get(equipped.face or "face_neutral")
	local shirt = if shirtDef then AvatarCatalog.Color(shirtDef) else Color3.fromRGB(40, 44, 58)
	local pants = if pantsDef then AvatarCatalog.Color(pantsDef) else Color3.fromRGB(30, 32, 42)

	local model = Instance.new("Model")
	model.Name = "Preview"
	local torso = limb(model, "Torso", Vector3.new(2, 2, 1), CFrame.new(0, 2.1, 0), shirt)
	local head = limb(model, "Head", Vector3.new(1.2, 1.2, 1.2), CFrame.new(0, 3.55, 0), skin)
	limb(model, "LArm", Vector3.new(1, 2, 1), CFrame.new(-1.5, 2.1, 0), skin)
	limb(model, "RArm", Vector3.new(1, 2, 1), CFrame.new(1.5, 2.1, 0), skin)
	limb(model, "LLeg", Vector3.new(1, 2, 1), CFrame.new(-0.5, 0.1, 0), pants)
	limb(model, "RLeg", Vector3.new(1, 2, 1), CFrame.new(0.5, 0.1, 0), pants)
	if hairDef then
		hairFor(model, hairDef.Style, AvatarCatalog.Color(hairDef), head)
	end
	if faceDef then
		faceDeco(model, faceDef.Style, head)
	end
	extra(model, equipped, head, torso)
	model.PrimaryPart = torso
	return model
end

export type Handle = {
	frame: ViewportFrame,
	set: (any, any) -> (),
	setYaw: (number) -> (),
	destroy: () -> (),
}

function ViewportAvatar.Attach(parent: Instance, equipped: any, skinTone: any): Handle
	local frame = Instance.new("ViewportFrame")
	frame.Name = "AvatarView"
	frame.BackgroundColor3 = Theme.BgElev
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromScale(1, 1)
	frame.Ambient = Color3.fromRGB(80, 80, 110)
	frame.LightColor = Color3.fromRGB(200, 200, 255)
	frame.LightDirection = Vector3.new(-1, -1, -1)
	frame.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = frame

	local world = Instance.new("WorldModel")
	world.Parent = frame
	local cam = Instance.new("Camera")
	cam.Parent = frame
	frame.CurrentCamera = cam

	local yaw = 20
	local distance = 7
	local model: Model? = nil

	local function layout()
		if not model or not model.PrimaryPart then
			return
		end
		local look = CFrame.new(0, 2.2, 0)
		cam.CFrame = CFrame.new(look.Position + Vector3.new(math.sin(math.rad(yaw)) * distance, 1.4, math.cos(math.rad(yaw)) * distance), look.Position)
	end

	local function set(eq: any, tone: any)
		if model then
			model:Destroy()
		end
		model = ViewportAvatar.BuildModel(eq, tone)
		model.Parent = world
		layout()
	end

	set(equipped, skinTone)

	return {
		frame = frame,
		set = set,
		setYaw = function(v: number)
			yaw = v
			layout()
		end,
		destroy = function()
			frame:Destroy()
		end,
	}
end

return ViewportAvatar
