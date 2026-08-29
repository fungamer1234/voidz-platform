--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VOIDZ = ReplicatedStorage:WaitForChild("VOIDZ")
local Config = require(VOIDZ.Shared.Config)
local Constants = require(VOIDZ.Shared.Constants)
local InventoryCatalog = require(VOIDZ.Shared.InventoryCatalog)
local AvatarCatalog = require(VOIDZ.Shared.AvatarCatalog)

local DataService = require(script.Parent.DataService)
local CurrencyService = require(script.Parent.CurrencyService)

local InventoryService = {}

local function countOwned(data: any): number
	local n = 0
	for _ in data.inventory.items do
		n += 1
	end
	return n
end

function InventoryService.Owns(player: Player, itemId: string): boolean
	local data = DataService.GetData(player)
	if not data then
		return false
	end
	local rec = data.inventory.items[itemId]
	return rec ~= nil and (rec.qty or 0) > 0
end

function InventoryService.Grant(player: Player, itemId: string, qty: number?): (boolean, string?)
	local def = InventoryCatalog.Get(itemId) or AvatarCatalog.Get(itemId)
	if not def then
		return false, Constants.ERRORS.NOT_FOUND
	end
	local data = DataService.GetData(player)
	if not data then
		return false, Constants.ERRORS.SESSION
	end
	local stack = InventoryCatalog.IsStackable(itemId)
	local rec = data.inventory.items[itemId]
	if rec and not stack then
		return false, Constants.ERRORS.ALREADY_OWNED
	end
	if countOwned(data) >= Config.InventoryMaxUnique and not rec then
		return false, "Inventory is full."
	end
	local add = qty or 1
	if rec then
		rec.qty = (rec.qty or 1) + add
	else
		data.inventory.items[itemId] = { qty = add, acquiredAt = os.time() }
	end
	data.stats.itemsOwned = countOwned(data)
	DataService.MarkDirty(player)
	return true, nil
end

function InventoryService.GrantStarter(player: Player)
	for _, id in Config.StarterItems do
		InventoryService.Grant(player, id)
	end
	local data = DataService.GetData(player)
	if data then
		data.inventory.items["title_rookie"] = { qty = 1, acquiredAt = os.time() }
	end
end

function InventoryService.Equip(player: Player, itemId: string): any
	local def = AvatarCatalog.Get(itemId)
	if not def then
		return { ok = false, error = Constants.ERRORS.NOT_FOUND }
	end
	if not InventoryService.Owns(player, itemId) then
		return { ok = false, error = Constants.ERRORS.NOT_OWNED }
	end
	local data = DataService.GetData(player)
	if not data then
		return { ok = false, error = Constants.ERRORS.SESSION }
	end
	data.inventory.equipped[def.Slot] = itemId
	if def.Slot == "skin" then
		data.avatar.skinTone = { def.Color[1], def.Color[2], def.Color[3] }
	end
	DataService.MarkDirty(player)
	return { ok = true, equipped = data.inventory.equipped, avatar = data.avatar }
end

function InventoryService.Unequip(player: Player, slot: string): any
	local data = DataService.GetData(player)
	if not data then
		return { ok = false, error = Constants.ERRORS.SESSION }
	end
	local fallback = Config.DefaultEquipped[slot]
	if type(fallback) ~= "string" then
		return { ok = false, error = Constants.ERRORS.INVALID }
	end
	data.inventory.equipped[slot] = fallback
	DataService.MarkDirty(player)
	return { ok = true, equipped = data.inventory.equipped }
end

function InventoryService.Purchase(player: Player, itemId: string): any
	local def = InventoryCatalog.Get(itemId)
	if not def or type(def.Price) ~= "number" or def.Price <= 0 then
		return { ok = false, error = Constants.ERRORS.NOT_FOUND }
	end
	if InventoryService.Owns(player, itemId) and not InventoryCatalog.IsStackable(itemId) then
		return { ok = false, error = Constants.ERRORS.ALREADY_OWNED }
	end
	local okPay, err = CurrencyService.Remove(player, def.Price, "buy:" .. itemId)
	if not okPay then
		return { ok = false, error = err }
	end
	local okGrant, gerr = InventoryService.Grant(player, itemId)
	if not okGrant then
		-- refund
		CurrencyService.Add(player, def.Price, "refund:" .. itemId)
		return { ok = false, error = gerr }
	end
	local data = DataService.GetData(player)
	return { ok = true, inventory = data.inventory, currency = data.currency }
end

return InventoryService
