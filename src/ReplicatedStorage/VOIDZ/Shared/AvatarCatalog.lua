--!strict

export type ItemDef = {
	Id: string,
	Name: string,
	Slot: string,
	Price: number,
	Rarity: string,
	Description: string,
	Color: { number },
	Style: string,
	Starter: boolean?,
}

local ITEMS: { ItemDef } = {
	{ Id = "skin_void", Name = "Void Tone", Slot = "skin", Price = 0, Rarity = "Common", Description = "Standard VOIDZ complexion.", Color = { 0.55, 0.42, 0.34 }, Style = "tone", Starter = true },
	{ Id = "skin_pale", Name = "Pale", Slot = "skin", Price = 40, Rarity = "Common", Description = "Light complexion.", Color = { 0.96, 0.84, 0.74 }, Style = "tone" },
	{ Id = "skin_warm", Name = "Warm", Slot = "skin", Price = 40, Rarity = "Common", Description = "Warm complexion.", Color = { 0.72, 0.48, 0.32 }, Style = "tone" },
	{ Id = "skin_deep", Name = "Deep", Slot = "skin", Price = 40, Rarity = "Common", Description = "Deep complexion.", Color = { 0.32, 0.2, 0.14 }, Style = "tone" },
	{ Id = "skin_olive", Name = "Olive", Slot = "skin", Price = 40, Rarity = "Common", Description = "Olive complexion.", Color = { 0.55, 0.48, 0.28 }, Style = "tone" },
	{ Id = "skin_cool", Name = "Cool Ash", Slot = "skin", Price = 80, Rarity = "Rare", Description = "Cool-toned complexion.", Color = { 0.7, 0.68, 0.78 }, Style = "tone" },
	{ Id = "skin_gold", Name = "Gilded", Slot = "skin", Price = 220, Rarity = "Epic", Description = "A metallic gold wash.", Color = { 0.92, 0.74, 0.28 }, Style = "tone" },
	{ Id = "skin_voidlit", Name = "Voidlit", Slot = "skin", Price = 350, Rarity = "Legendary", Description = "Skin that drinks neon.", Color = { 0.35, 0.28, 0.62 }, Style = "tone" },

	{ Id = "hair_short", Name = "Short Crop", Slot = "hair", Price = 0, Rarity = "Common", Description = "Clean short cut.", Color = { 0.12, 0.1, 0.1 }, Style = "short", Starter = true },
	{ Id = "hair_spiky", Name = "Spike", Slot = "hair", Price = 60, Rarity = "Common", Description = "Pushed-up spikes.", Color = { 0.18, 0.16, 0.2 }, Style = "spiky" },
	{ Id = "hair_long", Name = "Long Fall", Slot = "hair", Price = 90, Rarity = "Rare", Description = "Long hair down the back.", Color = { 0.35, 0.22, 0.12 }, Style = "long" },
	{ Id = "hair_wavy", Name = "Wave", Slot = "hair", Price = 90, Rarity = "Rare", Description = "Soft side wave.", Color = { 0.55, 0.35, 0.18 }, Style = "wavy" },
	{ Id = "hair_buzz", Name = "Buzz", Slot = "hair", Price = 40, Rarity = "Common", Description = "Close buzz.", Color = { 0.2, 0.18, 0.16 }, Style = "buzz" },
	{ Id = "hair_pony", Name = "Ponytail", Slot = "hair", Price = 110, Rarity = "Rare", Description = "High ponytail.", Color = { 0.08, 0.08, 0.1 }, Style = "pony" },
	{ Id = "hair_mohawk", Name = "Mohawk", Slot = "hair", Price = 140, Rarity = "Epic", Description = "Center ridge.", Color = { 0.7, 0.15, 0.45 }, Style = "mohawk" },
	{ Id = "hair_neon", Name = "Neon Sweep", Slot = "hair", Price = 260, Rarity = "Legendary", Description = "Slick neon sweep.", Color = { 0.48, 0.36, 1 }, Style = "wavy" },

	{ Id = "face_neutral", Name = "Neutral", Slot = "face", Price = 0, Rarity = "Common", Description = "Calm default face.", Color = { 0.1, 0.1, 0.12 }, Style = "neutral", Starter = true },
	{ Id = "face_smile", Name = "Smile", Slot = "face", Price = 50, Rarity = "Common", Description = "Easy smile.", Color = { 0.1, 0.1, 0.12 }, Style = "smile" },
	{ Id = "face_focus", Name = "Focused", Slot = "face", Price = 50, Rarity = "Common", Description = "Sharp gaze.", Color = { 0.1, 0.1, 0.12 }, Style = "focus" },
	{ Id = "face_cool", Name = "Cool", Slot = "face", Price = 80, Rarity = "Rare", Description = "Half-lidded calm.", Color = { 0.1, 0.1, 0.12 }, Style = "cool" },
	{ Id = "face_determined", Name = "Determined", Slot = "face", Price = 80, Rarity = "Rare", Description = "Set jaw, forward.", Color = { 0.1, 0.1, 0.12 }, Style = "determined" },
	{ Id = "face_cheer", Name = "Cheer", Slot = "face", Price = 80, Rarity = "Rare", Description = "Open and bright.", Color = { 0.1, 0.1, 0.12 }, Style = "cheer" },

	{ Id = "shirt_core", Name = "Core Tee", Slot = "shirt", Price = 0, Rarity = "Common", Description = "VOIDZ core shirt.", Color = { 0.14, 0.16, 0.22 }, Style = "tee", Starter = true },
	{ Id = "shirt_white", Name = "Plain White", Slot = "shirt", Price = 40, Rarity = "Common", Description = "Clean white tee.", Color = { 0.92, 0.93, 0.95 }, Style = "tee" },
	{ Id = "shirt_jacket", Name = "Night Jacket", Slot = "shirt", Price = 140, Rarity = "Rare", Description = "Layered jacket.", Color = { 0.12, 0.12, 0.16 }, Style = "jacket" },
	{ Id = "shirt_runner", Name = "Runner", Slot = "shirt", Price = 120, Rarity = "Rare", Description = "Athletic top.", Color = { 0.18, 0.55, 0.5 }, Style = "runner" },
	{ Id = "shirt_armor", Name = "Light Plate", Slot = "shirt", Price = 220, Rarity = "Epic", Description = "Stylized chest plate.", Color = { 0.55, 0.58, 0.65 }, Style = "armor" },
	{ Id = "shirt_void", Name = "Void Coat", Slot = "shirt", Price = 320, Rarity = "Legendary", Description = "Long void coat.", Color = { 0.28, 0.18, 0.55 }, Style = "coat" },
	{ Id = "shirt_gold", Name = "Gala", Slot = "shirt", Price = 280, Rarity = "Epic", Description = "Formal gold trim.", Color = { 0.42, 0.32, 0.12 }, Style = "gala" },
	{ Id = "shirt_crimson", Name = "Crimson", Slot = "shirt", Price = 160, Rarity = "Rare", Description = "Deep red shirt.", Color = { 0.62, 0.14, 0.2 }, Style = "tee" },

	{ Id = "pants_core", Name = "Core Pants", Slot = "pants", Price = 0, Rarity = "Common", Description = "Standard trousers.", Color = { 0.12, 0.13, 0.18 }, Style = "pants", Starter = true },
	{ Id = "pants_denim", Name = "Denim", Slot = "pants", Price = 50, Rarity = "Common", Description = "Blue denim.", Color = { 0.22, 0.32, 0.5 }, Style = "pants" },
	{ Id = "pants_dark", Name = "Dark Cargo", Slot = "pants", Price = 70, Rarity = "Common", Description = "Utility cargo.", Color = { 0.16, 0.17, 0.16 }, Style = "cargo" },
	{ Id = "pants_sport", Name = "Track", Slot = "pants", Price = 90, Rarity = "Rare", Description = "Track pants.", Color = { 0.15, 0.18, 0.28 }, Style = "sport" },
	{ Id = "pants_armor", Name = "Greaves", Slot = "pants", Price = 220, Rarity = "Epic", Description = "Armored legs.", Color = { 0.45, 0.48, 0.55 }, Style = "armor" },
	{ Id = "pants_void", Name = "Void Trousers", Slot = "pants", Price = 260, Rarity = "Legendary", Description = "Matched to the coat.", Color = { 0.18, 0.12, 0.32 }, Style = "pants" },
	{ Id = "pants_white", Name = "White", Slot = "pants", Price = 60, Rarity = "Common", Description = "Light trousers.", Color = { 0.88, 0.88, 0.9 }, Style = "pants" },
	{ Id = "pants_crimson", Name = "Crimson Slacks", Slot = "pants", Price = 140, Rarity = "Rare", Description = "Deep red slacks.", Color = { 0.42, 0.1, 0.16 }, Style = "pants" },

	{ Id = "hat_none", Name = "No Hat", Slot = "hat", Price = 0, Rarity = "Common", Description = "Unequipped.", Color = { 1, 1, 1 }, Style = "none", Starter = true },
	{ Id = "hat_cap", Name = "Cap", Slot = "hat", Price = 80, Rarity = "Common", Description = "Forward cap.", Color = { 0.15, 0.16, 0.2 }, Style = "cap" },
	{ Id = "hat_beanie", Name = "Beanie", Slot = "hat", Price = 80, Rarity = "Common", Description = "Soft beanie.", Color = { 0.2, 0.22, 0.3 }, Style = "beanie" },
	{ Id = "hat_crown", Name = "Thin Crown", Slot = "hat", Price = 400, Rarity = "Legendary", Description = "A restrained crown.", Color = { 0.95, 0.78, 0.28 }, Style = "crown" },
	{ Id = "hat_visor", Name = "Visor", Slot = "hat", Price = 160, Rarity = "Rare", Description = "Neon visor.", Color = { 0.2, 0.95, 0.8 }, Style = "visor" },
	{ Id = "hat_helm", Name = "Circuit Helm", Slot = "hat", Price = 280, Rarity = "Epic", Description = "Closed helm.", Color = { 0.4, 0.42, 0.5 }, Style = "helm" },

	{ Id = "acc_none", Name = "No Accessory", Slot = "accessory", Price = 0, Rarity = "Common", Description = "Unequipped.", Color = { 1, 1, 1 }, Style = "none", Starter = true },
	{ Id = "acc_shades", Name = "Shades", Slot = "accessory", Price = 90, Rarity = "Common", Description = "Dark shades.", Color = { 0.08, 0.08, 0.1 }, Style = "shades" },
	{ Id = "acc_comm", Name = "Comm Set", Slot = "accessory", Price = 140, Rarity = "Rare", Description = "Ear comms.", Color = { 0.5, 0.55, 0.65 }, Style = "comm" },
	{ Id = "acc_scarf", Name = "Scarf", Slot = "accessory", Price = 120, Rarity = "Rare", Description = "Wrapped scarf.", Color = { 0.55, 0.12, 0.18 }, Style = "scarf" },
	{ Id = "acc_chain", Name = "Chain", Slot = "accessory", Price = 160, Rarity = "Rare", Description = "Short chain.", Color = { 0.9, 0.8, 0.35 }, Style = "chain" },
	{ Id = "acc_mask", Name = "Half Mask", Slot = "accessory", Price = 240, Rarity = "Epic", Description = "Lower-face mask.", Color = { 0.12, 0.12, 0.14 }, Style = "mask" },

	{ Id = "back_none", Name = "No Backpiece", Slot = "back", Price = 0, Rarity = "Common", Description = "Unequipped.", Color = { 1, 1, 1 }, Style = "none", Starter = true },
	{ Id = "back_pack", Name = "Daypack", Slot = "back", Price = 100, Rarity = "Common", Description = "Simple pack.", Color = { 0.2, 0.22, 0.28 }, Style = "pack" },
	{ Id = "back_cape", Name = "Short Cape", Slot = "back", Price = 220, Rarity = "Epic", Description = "Cropped cape.", Color = { 0.28, 0.16, 0.5 }, Style = "cape" },
	{ Id = "back_wings", Name = "Light Wings", Slot = "back", Price = 480, Rarity = "Legendary", Description = "Stylized light wings.", Color = { 0.7, 0.85, 1 }, Style = "wings" },

	{ Id = "fx_none", Name = "No Effect", Slot = "effect", Price = 0, Rarity = "Common", Description = "Unequipped.", Color = { 1, 1, 1 }, Style = "none", Starter = true },
	{ Id = "fx_spark", Name = "Spark", Slot = "effect", Price = 180, Rarity = "Rare", Description = "Soft sparks.", Color = { 0.7, 0.8, 1 }, Style = "spark" },
	{ Id = "fx_aura", Name = "Aura", Slot = "effect", Price = 260, Rarity = "Epic", Description = "Idle aura.", Color = { 0.48, 0.36, 1 }, Style = "aura" },
	{ Id = "fx_ember", Name = "Ember", Slot = "effect", Price = 260, Rarity = "Epic", Description = "Falling embers.", Color = { 1, 0.45, 0.2 }, Style = "ember" },
	{ Id = "fx_void", Name = "Void Drift", Slot = "effect", Price = 420, Rarity = "Legendary", Description = "Particles that fall upward.", Color = { 0.45, 0.3, 1 }, Style = "void" },
}

local byId: { [string]: ItemDef } = {}
for _, it in ITEMS do
	byId[it.Id] = it
end

local AvatarCatalog = {}

function AvatarCatalog.GetAll(): { ItemDef }
	return ITEMS
end

function AvatarCatalog.Get(id: string): ItemDef?
	return byId[id]
end

function AvatarCatalog.GetSlot(slot: string): { ItemDef }
	local out = {}
	for _, it in ITEMS do
		if it.Slot == slot then
			table.insert(out, it)
		end
	end
	return out
end

function AvatarCatalog.Color(it: ItemDef): Color3
	return Color3.new(it.Color[1], it.Color[2], it.Color[3])
end

function AvatarCatalog.RarityColor(r: string): Color3
	if r == "Legendary" then
		return Color3.fromRGB(255, 184, 72)
	elseif r == "Epic" then
		return Color3.fromRGB(188, 108, 255)
	elseif r == "Rare" then
		return Color3.fromRGB(80, 168, 255)
	end
	return Color3.fromRGB(160, 170, 188)
end

return AvatarCatalog
