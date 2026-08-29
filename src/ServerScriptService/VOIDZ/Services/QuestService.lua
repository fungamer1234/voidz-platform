--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VOIDZ = ReplicatedStorage:WaitForChild("VOIDZ")
local Quests = require(VOIDZ.Shared.Quests)
local Config = require(VOIDZ.Shared.Config)

local DataService = require(script.Parent.DataService)
local CurrencyService = require(script.Parent.CurrencyService)
local NotificationService = require(script.Parent.NotificationService)

local QuestService = {}

local function rec(data: any, id: string)
	data.quests = data.quests or {}
	data.quests[id] = data.quests[id] or { progress = 0, completed = false, claimed = false }
	return data.quests[id]
end

function QuestService.Add(player: Player, stat: string, amount: number)
	local data = DataService.GetData(player)
	if not data then
		return
	end
	data.stats[stat] = (data.stats[stat] or 0) + amount
	for _, q in Quests.GetAll() do
		if q.Stat == stat then
			local r = rec(data, q.Id)
			if not r.completed then
				r.progress = math.min(q.Target, (r.progress or 0) + amount)
				if r.progress >= q.Target then
					r.completed = true
					if not r.claimed then
						r.claimed = true
						local grant = math.min(q.Reward, Config.QuestRewardCap)
						CurrencyService.Add(player, grant, "quest:" .. q.Id)
						NotificationService.Push(player, "Achievement", q.Name, "Quest complete · +" .. grant .. " VC")
					end
				end
			end
		end
	end
	DataService.MarkDirty(player)
end

function QuestService.Snapshot(player: Player): any
	local data = DataService.GetData(player)
	if not data then
		return { ok = false }
	end
	local list = {}
	for _, q in Quests.GetAll() do
		local r = rec(data, q.Id)
		table.insert(list, {
			id = q.Id,
			name = q.Name,
			description = q.Description,
			progress = r.progress or 0,
			target = q.Target,
			completed = r.completed == true,
			reward = q.Reward,
		})
	end
	return { ok = true, quests = list }
end

return QuestService
