--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VOIDZ = ReplicatedStorage:WaitForChild("VOIDZ")
local Config = require(VOIDZ.Shared.Config)
local Constants = require(VOIDZ.Shared.Constants)

local DataService = require(script.Parent.DataService)
local CurrencyService = require(script.Parent.CurrencyService)
local NotificationService = require(script.Parent.NotificationService)

local DailyRewardService = {}

local DAY = 86400

function DailyRewardService.Status(player: Player): any
	local data = DataService.GetData(player)
	if not data then
		return { ok = false, error = Constants.ERRORS.SESSION }
	end
	data.daily = data.daily or { lastClaim = 0, streak = 0 }
	local last = data.daily.lastClaim or 0
	local ready = os.time() - last >= DAY
	return { ok = true, ready = ready, streak = data.daily.streak or 0, lastClaim = last }
end

function DailyRewardService.Claim(player: Player): any
	local data = DataService.GetData(player)
	if not data then
		return { ok = false, error = Constants.ERRORS.SESSION }
	end
	data.daily = data.daily or { lastClaim = 0, streak = 0 }
	local now = os.time()
	if now - (data.daily.lastClaim or 0) < DAY then
		return { ok = false, error = Constants.ERRORS.DAILY_CLAIMED }
	end
	local gap = now - (data.daily.lastClaim or 0)
	if data.daily.lastClaim == 0 or gap > DAY * 2 then
		data.daily.streak = 1
	else
		data.daily.streak = (data.daily.streak or 0) + 1
	end
	data.daily.lastClaim = now
	local amount = Config.DailyReward + (data.daily.streak - 1) * Config.DailyStreakBonus
	amount = math.clamp(amount, 10, 250)
	CurrencyService.Add(player, amount, "daily")
	NotificationService.Push(player, "Reward", "Daily drop", "+" .. amount .. " VC · streak " .. data.daily.streak)
	DataService.MarkDirty(player)
	return { ok = true, amount = amount, streak = data.daily.streak }
end

return DailyRewardService
