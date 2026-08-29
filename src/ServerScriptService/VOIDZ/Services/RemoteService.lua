--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VOIDZ = ReplicatedStorage:WaitForChild("VOIDZ")
local RemoteNames = require(VOIDZ.Remotes.RemoteNames)

local RemoteService = {}
RemoteService.Functions = {} :: { [string]: RemoteFunction }
RemoteService.Events = {} :: { [string]: RemoteEvent }

function RemoteService.Init()
	local folder = VOIDZ:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = VOIDZ
	end
	-- Keep RemoteNames module; add live instances beside it.
	for _, name in RemoteNames.Functions do
		local rf = folder:FindFirstChild(name)
		if not rf then
			rf = Instance.new("RemoteFunction")
			rf.Name = name
			rf.Parent = folder
		end
		RemoteService.Functions[name] = rf :: RemoteFunction
	end
	for _, name in RemoteNames.Events do
		local re = folder:FindFirstChild(name)
		if not re then
			re = Instance.new("RemoteEvent")
			re.Name = name
			re.Parent = folder
		end
		RemoteService.Events[name] = re :: RemoteEvent
	end
end

function RemoteService.OnFunction(name: string, handler: (Player, ...any) -> ...any)
	local rf = RemoteService.Functions[name]
	assert(rf, "Missing RemoteFunction " .. name)
	rf.OnServerInvoke = function(player: Player, ...: any)
		if typeof(player) ~= "Instance" or not player:IsA("Player") then
			return { ok = false, error = "invalid" }
		end
		local ok, a, b = pcall(handler, player, ...)
		if not ok then
			warn("[VOIDZ] Remote", name, a)
			return { ok = false, error = "server" }
		end
		return a, b
	end
end

function RemoteService.Fire(name: string, player: Player, payload: any)
	local re = RemoteService.Events[name]
	if re and player.Parent then
		re:FireClient(player, payload)
	end
end

function RemoteService.FireAll(name: string, payload: any)
	local re = RemoteService.Events[name]
	if re then
		re:FireAllClients(payload)
	end
end

return RemoteService
