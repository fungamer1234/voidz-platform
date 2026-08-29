--!strict

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VOIDZ = ReplicatedStorage:WaitForChild("VOIDZ")
local Config = require(VOIDZ.Shared.Config)
local Constants = require(VOIDZ.Shared.Constants)
local Validate = require(VOIDZ.Shared.Validate)
local Sanitize = require(VOIDZ.Shared.Sanitize)
local Utility = require(VOIDZ.Shared.Utility)

local DataService = require(script.Parent.DataService)
local CurrencyService = require(script.Parent.CurrencyService)
local InventoryService = require(script.Parent.InventoryService)
local NotificationService = require(script.Parent.NotificationService)
local AchievementService = require(script.Parent.AchievementService)
local RemoteService = require(script.Parent.RemoteService)

local ProfileService = {}

local nameStore: DataStore? = nil
local memoryNames: { [string]: number } = {}

local function nameKey(name: string): string
	return string.lower(name)
end

local function initNameStore()
	local ok, store = pcall(function()
		return DataStoreService:GetDataStore(Config.NameStoreName)
	end)
	if ok then
		nameStore = store
	end
end

local function claimName(userId: number, name: string, previous: string?): (boolean, string?)
	local key = nameKey(name)
	if not nameStore or DataService.UsingFallback() then
		local owner = memoryNames[key]
		if owner and owner ~= userId then
			return false, Constants.ERRORS.NAME_TAKEN
		end
		if previous and previous ~= "" then
			memoryNames[nameKey(previous)] = nil
		end
		memoryNames[key] = userId
		return true, nil
	end
	local ok, err = Utility.pcallRetry(4, 0.3, function()
		local conflict = false
		nameStore:UpdateAsync("n_" .. key, function(old)
			if type(old) == "number" and old ~= userId then
				conflict = true
				return old
			end
			return userId
		end)
		if conflict then
			error("taken")
		end
		return true
	end)
	if not ok then
		if tostring(err) == "taken" or string.find(tostring(err), "taken", 1, true) then
			return false, Constants.ERRORS.NAME_TAKEN
		end
		-- If the name store is down, allow the name for this session but don't persist uniqueness.
		if RunService:IsStudio() then
			memoryNames[key] = userId
			return true, nil
		end
		return false, Constants.ERRORS.SAVE_FAILED
	end
	if previous and previous ~= "" and nameKey(previous) ~= key then
		pcall(function()
			(nameStore :: DataStore):RemoveAsync("n_" .. nameKey(previous))
		end)
	end
	return true, nil
end

function ProfileService.Init()
	initNameStore()
end

function ProfileService.GetClientPackage(player: Player): any
	local live = DataService.GetLive(player)
	if not live then
		return { ok = false, error = Constants.ERRORS.SESSION }
	end
	if live.loadFailed then
		return { ok = false, error = Constants.ERRORS.LOAD_FAILED, retry = true }
	end
	if not live.loaded then
		return { ok = false, error = Constants.ERRORS.SESSION }
	end
	return {
		ok = true,
		isNew = not live.data.onboarded,
		fallback = live.fallback or DataService.UsingFallback(),
		data = Sanitize.forClient(live.data),
		userId = player.UserId,
		robloxName = player.Name,
		displayNameRoblox = player.DisplayName,
		version = Config.Version,
		maintenance = Config.MaintenanceMode,
	}
end

function ProfileService.CompleteOnboarding(player: Player, displayName: any, avatarPayload: any): any
	local data = DataService.GetData(player)
	if not data then
		return { ok = false, error = Constants.ERRORS.SESSION }
	end
	if data.onboarded then
		return { ok = false, error = Constants.ERRORS.ALREADY_ONBOARDED }
	end
	local okName, name, nerr = Validate.displayName(displayName)
	if not okName then
		return { ok = false, error = nerr }
	end
	local claimed, cerr = claimName(player.UserId, name, data.profile.displayName)
	if not claimed then
		return { ok = false, error = cerr }
	end
	data.profile.displayName = name
	data.profile.nameChangedAt = os.time()
	data.profile.createdAt = data.profile.createdAt ~= 0 and data.profile.createdAt or os.time()
	InventoryService.GrantStarter(player)
	if type(avatarPayload) == "table" then
		-- AvatarService required lazily to avoid cycle
		local AvatarService = require(script.Parent.AvatarService)
		AvatarService.Save(player, avatarPayload)
	end
	data.onboarded = true
	CurrencyService.Add(player, Config.StarterCurrency, "starter")
	NotificationService.Push(player, "Welcome", "Welcome to VOIDZ", "Your profile is live. Spend your starter VoidCoins, or jump into a game.")
	NotificationService.Push(player, "Currency", "Starter grant", Config.StarterCurrency .. " VoidCoins added to your balance.")
	AchievementService.Evaluate(player)
	DataService.MarkDirty(player)
	DataService.Save(player)
	pcall(function()
		player:SetAttribute("VOIDZ_DisplayName", name)
	end)
	return ProfileService.GetClientPackage(player)
end

function ProfileService.SetDisplayName(player: Player, displayName: any): any
	local data = DataService.GetData(player)
	if not data then
		return { ok = false, error = Constants.ERRORS.SESSION }
	end
	if not data.onboarded then
		return { ok = false, error = Constants.ERRORS.NOT_ONBOARDED }
	end
	local last = data.profile.nameChangedAt or 0
	if os.time() - last < Config.DisplayNameChangeCooldown then
		return { ok = false, error = "You can change your name again in a minute." }
	end
	local okName, name, nerr = Validate.displayName(displayName)
	if not okName then
		return { ok = false, error = nerr }
	end
	if name == data.profile.displayName then
		return { ok = true, displayName = name }
	end
	local claimed, cerr = claimName(player.UserId, name, data.profile.displayName)
	if not claimed then
		return { ok = false, error = cerr }
	end
	data.profile.displayName = name
	data.profile.nameChangedAt = os.time()
	DataService.MarkDirty(player)
	pcall(function()
		player:SetAttribute("VOIDZ_DisplayName", name)
	end)
	return { ok = true, displayName = name }
end

function ProfileService.SaveSettings(player: Player, patch: any): any
	local data = DataService.GetData(player)
	if not data then
		return { ok = false, error = Constants.ERRORS.SESSION }
	end
	local clean = Validate.settingsPatch(patch)
	for k, v in clean do
		data.settings[k] = v
	end
	DataService.MarkDirty(player)
	return { ok = true, settings = data.settings }
end

function ProfileService.GetPublic(viewer: Player, userId: any): any
	if type(userId) ~= "number" then
		return { ok = false, error = Constants.ERRORS.INVALID }
	end
	local target = Players:GetPlayerByUserId(userId)
	if not target then
		return { ok = false, error = "That player is not in this server." }
	end
	local data = DataService.GetData(target)
	if not data then
		return { ok = false, error = Constants.ERRORS.SESSION }
	end
	return { ok = true, profile = Sanitize.publicProfile(data, target.UserId, target.Name) }
end

function ProfileService.PushFull(player: Player)
	local pkg = ProfileService.GetClientPackage(player)
	if pkg.ok then
		RemoteService.Fire("DataUpdate", player, pkg.data)
	end
end

return ProfileService
