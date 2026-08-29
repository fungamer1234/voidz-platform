--!strict
--[[
	VOIDZ client entry. Waits for replicated modules, then starts the app.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
if not player then
	return
end

local VOIDZ = ReplicatedStorage:WaitForChild("VOIDZ", 30)
if not VOIDZ then
	warn("[VOIDZ] ReplicatedStorage.VOIDZ missing")
	return
end

local Client = VOIDZ:WaitForChild("Client")
local App = require(Client:WaitForChild("App"))
App.start()
