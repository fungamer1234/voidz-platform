--!strict
--[[
	VOIDZ server entry.
	Creates remotes, loads services, binds trusted handlers, builds the lobby.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VOIDZ = ReplicatedStorage:WaitForChild("VOIDZ")
local Config = require(VOIDZ.Shared.Config)
local Constants = require(VOIDZ.Shared.Constants)

local root = script.Parent
local Services = root:WaitForChild("Services")

local RateLimiter = require(Services.RateLimiter)
local RemoteService = require(Services.RemoteService)
local DataService = require(Services.DataService)
local CurrencyService = require(Services.CurrencyService)
local NotificationService = require(Services.NotificationService)
local InventoryService = require(Services.InventoryService)
local AvatarService = require(Services.AvatarService)
local AchievementService = require(Services.AchievementService)
local ProfileService = require(Services.ProfileService)
local GameService = require(Services.GameService)
local FriendsService = require(Services.FriendsService)
local AdminService = require(Services.AdminService)
local WorldService = require(Services.WorldService)
local MarketplaceHook = require(Services.MarketplaceHook)
local MatchService = require(Services.MatchService)
local PartyService = require(Services.PartyService)
local DailyRewardService = require(Services.DailyRewardService)
local QuestService = require(Services.QuestService)
local LeaderboardService = require(Services.LeaderboardService)
local ChatService = require(Services.ChatService)

RemoteService.Init()
DataService.Init()
ProfileService.Init()
MatchService.Init()
GameService.Init()
FriendsService.Init()
MarketplaceHook.Init()
ChatService.Init()
WorldService.Build()
print("[VOIDZ] Modes loaded:", MatchService.ModesLoaded())

local function gated(name: string, fn: (Player, ...any) -> any): (Player, ...any) -> any
	return function(player: Player, ...: any)
		if not RateLimiter.Allow(player, name) then
			return { ok = false, error = Constants.ERRORS.RATE_LIMIT }
		end
		if not DataService.GetData(player) and name ~= "GetSession" then
			return { ok = false, error = Constants.ERRORS.SESSION }
		end
		return fn(player, ...)
	end
end

RemoteService.OnFunction("GetSession", gated("GetSession", function(player)
	if not DataService.GetLive(player) then
		DataService.Load(player)
	end
	local pkg = ProfileService.GetClientPackage(player)
	if pkg.ok then
		pkg.live = GameService.GetLiveSnapshot()
		pkg.announcement = AdminService.Announcement()
		pkg.isDeveloper = AdminService.IsDeveloper(player)
	end
	return pkg
end))

RemoteService.OnFunction("CompleteOnboarding", gated("CompleteOnboarding", function(player, displayName, avatarPayload)
	local result = ProfileService.CompleteOnboarding(player, displayName, avatarPayload)
	if result.ok then
		result.live = GameService.GetLiveSnapshot()
		result.isDeveloper = AdminService.IsDeveloper(player)
	end
	return result
end))

RemoteService.OnFunction("SetDisplayName", gated("SetDisplayName", function(player, name)
	return ProfileService.SetDisplayName(player, name)
end))

RemoteService.OnFunction("SaveSettings", gated("SaveSettings", function(player, patch)
	return ProfileService.SaveSettings(player, patch)
end))

RemoteService.OnFunction("GetPublicProfile", gated("GetPublicProfile", function(player, userId)
	return ProfileService.GetPublic(player, userId)
end))

RemoteService.OnFunction("PlayGame", gated("PlayGame", function(player, gameId)
	return GameService.Play(player, gameId)
end))

RemoteService.OnFunction("ToggleFavorite", gated("ToggleFavorite", function(player, gameId)
	return GameService.ToggleFavorite(player, gameId)
end))

RemoteService.OnFunction("ToggleLike", gated("ToggleLike", function(player, gameId)
	return GameService.ToggleLike(player, gameId)
end))

RemoteService.OnFunction("EquipItem", gated("EquipItem", function(player, itemId)
	return InventoryService.Equip(player, itemId)
end))

RemoteService.OnFunction("UnequipItem", gated("UnequipItem", function(player, slot)
	return InventoryService.Unequip(player, slot)
end))

RemoteService.OnFunction("PurchaseItem", gated("PurchaseItem", function(player, itemId)
	local result = InventoryService.Purchase(player, itemId)
	if result.ok then
		AchievementService.Evaluate(player)
		ProfileService.PushFull(player)
	end
	return result
end))

RemoteService.OnFunction("SaveAvatar", gated("SaveAvatar", function(player, payload)
	local result = AvatarService.Save(player, payload)
	if result.ok then
		AchievementService.OnAvatarSaved(player)
	end
	return result
end))

RemoteService.OnFunction("ResetAvatar", gated("ResetAvatar", function(player)
	return AvatarService.Reset(player)
end))

RemoteService.OnFunction("GetFriends", gated("GetFriends", function(player)
	return FriendsService.Get(player)
end))

RemoteService.OnFunction("FriendRequest", gated("FriendRequest", function(player, userId)
	return FriendsService.Request(player, userId)
end))

RemoteService.OnFunction("FriendRespond", gated("FriendRespond", function(player, userId, accept)
	return FriendsService.Respond(player, userId, accept)
end))

RemoteService.OnFunction("RemoveFriend", gated("RemoveFriend", function(player, userId)
	return FriendsService.Remove(player, userId)
end))

RemoteService.OnFunction("SearchPlayers", gated("SearchPlayers", function(player, q)
	return FriendsService.Search(player, q)
end))

RemoteService.OnFunction("MarkNotificationsRead", gated("MarkNotificationsRead", function(player, id)
	return NotificationService.MarkRead(player, id)
end))

RemoteService.OnFunction("ClearNotifications", gated("ClearNotifications", function(player)
	return NotificationService.Clear(player)
end))

RemoteService.OnFunction("AdminCommand", gated("AdminCommand", function(player, command)
	return AdminService.Run(player, command)
end))

RemoteService.OnFunction("MatchAction", gated("MatchAction", function(player, action, payload)
	return MatchService.Action(player, action, payload)
end))

RemoteService.OnFunction("LeaveMatch", gated("LeaveMatch", function(player)
	return MatchService.Leave(player)
end))

RemoteService.OnFunction("PlayAgain", gated("PlayAgain", function(player)
	return MatchService.PlayAgain(player)
end))

RemoteService.OnFunction("ClaimDaily", gated("ClaimDaily", function(player)
	return DailyRewardService.Claim(player)
end))

RemoteService.OnFunction("GetDaily", gated("GetDaily", function(player)
	return DailyRewardService.Status(player)
end))

RemoteService.OnFunction("GetQuests", gated("GetQuests", function(player)
	return QuestService.Snapshot(player)
end))

RemoteService.OnFunction("GetLeaderboard", gated("GetLeaderboard", function(player, gameId)
	return LeaderboardService.Snapshot(gameId)
end))

RemoteService.OnFunction("PartyInvite", gated("PartyInvite", function(player, userId)
	return PartyService.Invite(player, userId)
end))

RemoteService.OnFunction("PartyRespond", gated("PartyRespond", function(player, accept)
	return PartyService.Respond(player, accept)
end))

RemoteService.OnFunction("PartyLeave", gated("PartyLeave", function(player)
	return PartyService.Leave(player)
end))

RemoteService.OnFunction("GetParty", gated("GetParty", function(player)
	return PartyService.Snapshot(player)
end))

local function onPlayer(player: Player)
	if not AdminService.GuardJoin(player) then
		return
	end
	local ok, err = DataService.Load(player)
	if not ok then
		warn("[VOIDZ] load failed", player.UserId, err)
		RemoteService.Fire("SoftError", player, { error = Constants.ERRORS.LOAD_FAILED, retry = true })
		return
	end
	AchievementService.Evaluate(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.2)
		AvatarService.ApplyCharacter(player)
	end)
	if player.Character then
		AvatarService.ApplyCharacter(player)
	end
end

Players.PlayerAdded:Connect(onPlayer)
for _, p in Players:GetPlayers() do
	task.spawn(onPlayer, p)
end

Players.PlayerRemoving:Connect(function(player)
	RateLimiter.Clear(player)
	PartyService.Clear(player)
end)

print("[VOIDZ] Server " .. Config.Version .. " ready")
