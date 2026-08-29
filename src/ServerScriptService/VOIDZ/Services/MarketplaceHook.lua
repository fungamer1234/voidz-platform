--!strict
--[[
	Optional Developer Product grants. Inactive until Config.Products contains real productIds.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VOIDZ = ReplicatedStorage:WaitForChild("VOIDZ")
local Config = require(VOIDZ.Shared.Config)

local CurrencyService = require(script.Parent.CurrencyService)
local NotificationService = require(script.Parent.NotificationService)
local DataService = require(script.Parent.DataService)

local MarketplaceHook = {}

local function coinsFor(productId: number): number?
	for _, p in Config.Products do
		if p.productId == productId then
			return p.coins
		end
	end
	return nil
end

function MarketplaceHook.Init()
	MarketplaceService.ProcessReceipt = function(info: any)
		local coins = coinsFor(info.ProductId)
		if not coins then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local player = Players:GetPlayerByUserId(info.PlayerId)
		if not player or not DataService.GetData(player) then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local ok = CurrencyService.Add(player, coins, "product:" .. tostring(info.ProductId))
		if not ok then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		NotificationService.Push(player, "Currency", "Purchase complete", coins .. " VoidCoins added to your balance.")
		DataService.Save(player)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

return MarketplaceHook
