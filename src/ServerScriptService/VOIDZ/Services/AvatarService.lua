--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VOIDZ = ReplicatedStorage:WaitForChild("VOIDZ")
local Config = require(VOIDZ.Shared.Config)
local Constants = require(VOIDZ.Shared.Constants)
local AvatarCatalog = require(VOIDZ.Shared.AvatarCatalog)
local Validate = require(VOIDZ.Shared.Validate)
local Utility = require(VOIDZ.Shared.Utility)

local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)

local AvatarService = {}

local function applyToCharacter(player: Player, data: any)
	local char = player.Character
	if not char then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	-- Platform cosmetics are previewed in ViewportFrame. On the live character we tint BodyColors
	-- so the lobby avatar matches without destroying the Roblox character or loading foreign clothing.
	local tone = Validate.skinTone(data.avatar.skinTone)
	local color = Color3.new(tone[1], tone[2], tone[3])
	local bc = char:FindFirstChildOfClass("BodyColors")
	if not bc then
		bc = Instance.new("BodyColors")
		bc.Parent = char
	end
	local brick = BrickColor.new(color)
	bc.HeadColor = brick
	bc.TorsoColor = brick
	bc.LeftArmColor = brick
	bc.RightArmColor = brick
	bc.LeftLegColor = brick
	bc.RightLegColor = brick
	-- Shirt/pants as BodyColors already applied; extra platform parts are not welded onto the
	-- real character (prevents breaking movement / accessories). Viewport handles full cosmetics.
end

function AvatarService.ApplyCharacter(player: Player)
	local data = DataService.GetData(player)
	if data then
		applyToCharacter(player, data)
	end
end

function AvatarService.Save(player: Player, payload: any): any
	if type(payload) ~= "table" then
		return { ok = false, error = Constants.ERRORS.INVALID }
	end
	local data = DataService.GetData(player)
	if not data then
		return { ok = false, error = Constants.ERRORS.SESSION }
	end
	local equipped = payload.equipped
	if type(equipped) == "table" then
		for _, slot in { "skin", "hair", "face", "shirt", "pants", "hat", "accessory", "back", "effect" } do
			local id = equipped[slot]
			if type(id) == "string" then
				local def = AvatarCatalog.Get(id)
				if not def or def.Slot ~= slot then
					return { ok = false, error = Constants.ERRORS.INVALID }
				end
				if not InventoryService.Owns(player, id) then
					return { ok = false, error = Constants.ERRORS.NOT_OWNED }
				end
				data.inventory.equipped[slot] = id
			end
		end
	end
	if payload.skinTone ~= nil then
		data.avatar.skinTone = Validate.skinTone(payload.skinTone)
	end
	DataService.MarkDirty(player)
	applyToCharacter(player, data)
	return { ok = true, equipped = data.inventory.equipped, avatar = data.avatar }
end

function AvatarService.Reset(player: Player): any
	local data = DataService.GetData(player)
	if not data then
		return { ok = false, error = Constants.ERRORS.SESSION }
	end
	for slot, id in Config.DefaultEquipped do
		data.inventory.equipped[slot] = id
	end
	data.avatar.skinTone = Utility.deepCopy(Config.DefaultAvatar.skinTone)
	DataService.MarkDirty(player)
	applyToCharacter(player, data)
	return { ok = true, equipped = data.inventory.equipped, avatar = data.avatar }
end

return AvatarService
