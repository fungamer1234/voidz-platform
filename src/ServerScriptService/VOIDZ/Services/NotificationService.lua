--!strict

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VOIDZ = ReplicatedStorage:WaitForChild("VOIDZ")
local Config = require(VOIDZ.Shared.Config)
local Constants = require(VOIDZ.Shared.Constants)

local DataService = require(script.Parent.DataService)
local RemoteService = require(script.Parent.RemoteService)

local NotificationService = {}

function NotificationService.Push(player: Player, kind: string, title: string, body: string, payload: any?)
	local data = DataService.GetData(player)
	if not data then
		return
	end
	if not Constants.NOTIFICATION_TYPES[kind] then
		kind = "System"
	end
	data.notifications = data.notifications or {}
	local n = {
		id = HttpService:GenerateGUID(false),
		kind = kind,
		title = title,
		body = body,
		payload = payload,
		read = false,
		at = os.time(),
	}
	table.insert(data.notifications, 1, n)
	while #data.notifications > Config.MaxNotifications do
		table.remove(data.notifications)
	end
	DataService.MarkDirty(player)
	RemoteService.Fire("Notification", player, n)
end

function NotificationService.MarkRead(player: Player, id: string?): any
	local data = DataService.GetData(player)
	if not data then
		return { ok = false, error = Constants.ERRORS.SESSION }
	end
	for _, n in data.notifications or {} do
		if id == nil or n.id == id then
			n.read = true
		end
	end
	DataService.MarkDirty(player)
	return { ok = true, notifications = data.notifications }
end

function NotificationService.Clear(player: Player): any
	local data = DataService.GetData(player)
	if not data then
		return { ok = false, error = Constants.ERRORS.SESSION }
	end
	data.notifications = {}
	DataService.MarkDirty(player)
	return { ok = true, notifications = {} }
end

return NotificationService
