--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VOIDZ = ReplicatedStorage:WaitForChild("VOIDZ")
local Achievements = require(VOIDZ.Shared.Achievements)

local DataService = require(script.Parent.DataService)
local NotificationService = require(script.Parent.NotificationService)

local AchievementService = {}

function AchievementService.Unlock(player: Player, id: string)
	local def = Achievements.Get(id)
	if not def then
		return
	end
	local data = DataService.GetData(player)
	if not data then
		return
	end
	if data.achievements[id] then
		return
	end
	data.achievements[id] = os.time()
	DataService.MarkDirty(player)
	NotificationService.Push(player, "Achievement", def.Name, def.Description, { achievementId = id })
end

function AchievementService.Evaluate(player: Player)
	local data = DataService.GetData(player)
	if not data then
		return
	end
	if data.onboarded then
		AchievementService.Unlock(player, "welcome")
	end
	if (data.stats.playClicks or 0) >= 1 then
		AchievementService.Unlock(player, "first_play")
	end
	local distinct = 0
	if type(data.stats.distinctGames) == "table" then
		for _ in data.stats.distinctGames do
			distinct += 1
		end
	end
	if distinct >= 3 then
		AchievementService.Unlock(player, "explorer")
	end
	if (data.stats.itemsOwned or 0) >= 10 then
		AchievementService.Unlock(player, "collector")
	end
	if (data.stats.friends or 0) >= 1 then
		AchievementService.Unlock(player, "social")
	end
	if (data.currency.VoidCoins or 0) >= 1000 then
		AchievementService.Unlock(player, "wealthy")
	end
	if (data.stats.logins or 0) >= 5 then
		AchievementService.Unlock(player, "regular")
	end
	if (data.stats.wins or 0) >= 1 then
		AchievementService.Unlock(player, "first_win")
	end
	if (data.stats.wins or 0) >= 5 then
		AchievementService.Unlock(player, "champion")
	end
end

function AchievementService.OnAvatarSaved(player: Player)
	AchievementService.Unlock(player, "customizer")
	AchievementService.Evaluate(player)
end

return AchievementService
