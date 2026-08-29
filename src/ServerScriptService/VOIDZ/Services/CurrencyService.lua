--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VOIDZ = ReplicatedStorage:WaitForChild("VOIDZ")
local Config = require(VOIDZ.Shared.Config)
local Constants = require(VOIDZ.Shared.Constants)
local Validate = require(VOIDZ.Shared.Validate)

local DataService = require(script.Parent.DataService)
local RemoteService = require(script.Parent.RemoteService)

local CurrencyService = {}

local function log(data: any, kind: string, amount: number, reason: string, balance: number)
	data.stats.transactions = data.stats.transactions or {}
	table.insert(data.stats.transactions, 1, {
		kind = kind,
		amount = amount,
		reason = reason,
		balance = balance,
		at = os.time(),
	})
	while #data.stats.transactions > Config.MaxTransactionLog do
		table.remove(data.stats.transactions)
	end
end

function CurrencyService.GetBalance(player: Player): number
	local data = DataService.GetData(player)
	if not data then
		return 0
	end
	return data.currency.VoidCoins or 0
end

function CurrencyService.CanAfford(player: Player, amount: number): boolean
	return CurrencyService.GetBalance(player) >= amount
end

function CurrencyService.Add(player: Player, amount: number, reason: string): (boolean, string?)
	local okAmt, n = Validate.positiveInt(amount, Config.MaxGrantPerCall)
	if not okAmt then
		return false, Constants.ERRORS.INVALID
	end
	local data = DataService.GetData(player)
	if not data then
		return false, Constants.ERRORS.SESSION
	end
	local bal = data.currency.VoidCoins or 0
	bal = math.min(Config.MaxCurrency, bal + n)
	data.currency.VoidCoins = bal
	log(data, "add", n, Validate.reason(reason), bal)
	DataService.MarkDirty(player)
	RemoteService.Fire("CurrencyDelta", player, { amount = n, reason = reason, balance = bal })
	return true, nil
end

function CurrencyService.Remove(player: Player, amount: number, reason: string): (boolean, string?)
	local okAmt, n = Validate.positiveInt(amount, Config.MaxCurrency)
	if not okAmt then
		return false, Constants.ERRORS.INVALID
	end
	local data = DataService.GetData(player)
	if not data then
		return false, Constants.ERRORS.SESSION
	end
	local bal = data.currency.VoidCoins or 0
	if bal < n then
		return false, Constants.ERRORS.CANNOT_AFFORD
	end
	bal -= n
	data.currency.VoidCoins = bal
	log(data, "remove", n, Validate.reason(reason), bal)
	DataService.MarkDirty(player)
	RemoteService.Fire("CurrencyDelta", player, { amount = -n, reason = reason, balance = bal })
	return true, nil
end

return CurrencyService
