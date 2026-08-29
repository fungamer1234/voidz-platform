--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VOIDZ = ReplicatedStorage:WaitForChild("VOIDZ")
local Config = require(VOIDZ.Shared.Config)
local Constants = require(VOIDZ.Shared.Constants)
local GameRegistry = require(VOIDZ.Shared.GameRegistry)
local Validate = require(VOIDZ.Shared.Validate)

local CurrencyService = require(script.Parent.CurrencyService)
local InventoryService = require(script.Parent.InventoryService)
local NotificationService = require(script.Parent.NotificationService)
local GameService = require(script.Parent.GameService)
local RemoteService = require(script.Parent.RemoteService)
local DataService = require(script.Parent.DataService)

local AdminService = {}

local maintenance = Config.MaintenanceMode
local announcement: string? = nil

function AdminService.IsDeveloper(player: Player): boolean
	for _, id in Config.DeveloperUserIds do
		if player.UserId == id then
			return true
		end
	end
	-- Studio play-solo / local test only. Never granted in live servers.
	if RunService:IsStudio() then
		return true
	end
	return false
end

function AdminService.Maintenance(): boolean
	return maintenance
end

function AdminService.Announcement(): string?
	return announcement
end

function AdminService.GuardJoin(player: Player): boolean
	if maintenance and not AdminService.IsDeveloper(player) then
		player:Kick(Config.MaintenanceMessage)
		return false
	end
	return true
end

function AdminService.Run(player: Player, command: any): any
	if not AdminService.IsDeveloper(player) then
		return { ok = false, error = Constants.ERRORS.NOT_DEV }
	end
	if type(command) ~= "table" or type(command.action) ~= "string" then
		return { ok = false, error = Constants.ERRORS.INVALID }
	end
	local action = command.action
	if action == "announce" then
		if type(command.text) ~= "string" or #command.text < 1 or #command.text > 200 then
			return { ok = false, error = Constants.ERRORS.INVALID }
		end
		announcement = command.text
		RemoteService.FireAll("Announcement", { text = announcement, at = os.time() })
		return { ok = true }
	elseif action == "maintenance" then
		maintenance = command.enabled == true
		if maintenance then
			for _, p in Players:GetPlayers() do
				if not AdminService.IsDeveloper(p) then
					p:Kick(Config.MaintenanceMessage)
				end
			end
		end
		return { ok = true, maintenance = maintenance }
	elseif action == "grantCoins" then
		local targetId = command.userId
		local amtOk, amt = Validate.positiveInt(command.amount, Config.MaxGrantPerCall)
		if type(targetId) ~= "number" or not amtOk then
			return { ok = false, error = Constants.ERRORS.INVALID }
		end
		local target = Players:GetPlayerByUserId(targetId)
		if not target then
			return { ok = false, error = "Player not in this server." }
		end
		CurrencyService.Add(target, amt, "admin")
		NotificationService.Push(target, "Currency", "Developer grant", amt .. " VoidCoins added.")
		return { ok = true, balance = CurrencyService.GetBalance(target) }
	elseif action == "grantItem" then
		local target = Players:GetPlayerByUserId(command.userId)
		if not target or type(command.itemId) ~= "string" then
			return { ok = false, error = Constants.ERRORS.INVALID }
		end
		local ok, err = InventoryService.Grant(target, command.itemId)
		return { ok = ok, error = err }
	elseif action == "setFeatured" then
		if type(command.ids) ~= "table" then
			return { ok = false, error = Constants.ERRORS.INVALID }
		end
		local ids = {}
		for _, id in command.ids do
			if type(id) == "string" and GameRegistry.Get(id) then
				table.insert(ids, id)
			end
		end
		GameService.SetFeatured(ids)
		return { ok = true, ids = ids }
	elseif action == "stats" then
		return {
			ok = true,
			players = #Players:GetPlayers(),
			fallback = DataService.UsingFallback(),
			maintenance = maintenance,
			version = Config.Version,
			games = GameService.GetLiveSnapshot(),
		}
	end
	return { ok = false, error = "Unknown command." }
end

return AdminService
