--!strict
--[[
	Non-avatar inventory items (titles, consumable cosmetics).
	Avatar pieces live in AvatarCatalog and are also inventory items.
]]

local AvatarCatalog = require(script.Parent.AvatarCatalog)

export type ExtraItem = {
	Id: string,
	Name: string,
	Slot: string,
	Price: number,
	Rarity: string,
	Description: string,
	Category: string,
}

local EXTRA: { ExtraItem } = {
	{ Id = "title_rookie", Name = "Rookie", Slot = "title", Price = 0, Rarity = "Common", Description = "Everyone starts here.", Category = "Title" },
	{ Id = "title_forged", Name = "Forged", Slot = "title", Price = 200, Rarity = "Rare", Description = "A title for collectors.", Category = "Title" },
	{ Id = "title_voidwalker", Name = "Voidwalker", Slot = "title", Price = 600, Rarity = "Legendary", Description = "Walk between games.", Category = "Title" },
	{ Id = "boost_spark", Name = "Spark Trail (1 use)", Slot = "consumable", Price = 75, Rarity = "Rare", Description = "A one-time lobby spark burst. Cosmetic only.", Category = "Consumable" },
}

local InventoryCatalog = {}

function InventoryCatalog.GetExtras(): { ExtraItem }
	return EXTRA
end

function InventoryCatalog.Get(id: string): any
	local a = AvatarCatalog.Get(id)
	if a then
		return a
	end
	for _, e in EXTRA do
		if e.Id == id then
			return e
		end
	end
	return nil
end

function InventoryCatalog.AllShop(): { any }
	local out = {}
	for _, it in AvatarCatalog.GetAll() do
		if it.Price > 0 then
			table.insert(out, it)
		end
	end
	for _, e in EXTRA do
		if e.Price > 0 then
			table.insert(out, e)
		end
	end
	return out
end

function InventoryCatalog.IsStackable(id: string): boolean
	local it = InventoryCatalog.Get(id)
	return it ~= nil and it.Slot == "consumable"
end

return InventoryCatalog
