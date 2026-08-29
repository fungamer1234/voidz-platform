--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VOIDZ = ReplicatedStorage:WaitForChild("VOIDZ")

local Net = {}
local folder: Folder? = nil

local function remotes(): Folder
	if folder and folder.Parent then
		return folder
	end
	folder = VOIDZ:WaitForChild("Remotes") :: Folder
	return folder
end

function Net.Function(name: string): RemoteFunction
	return remotes():WaitForChild(name, 30) :: RemoteFunction
end

function Net.Event(name: string): RemoteEvent
	return remotes():WaitForChild(name, 30) :: RemoteEvent
end

function Net.Invoke(name: string, ...: any): any
	local rf = Net.Function(name)
	local ok, result = pcall(function(...)
		return rf:InvokeServer(...)
	end, ...)
	if not ok then
		return { ok = false, error = "Couldn't reach the server." }
	end
	return result
end

return Net
