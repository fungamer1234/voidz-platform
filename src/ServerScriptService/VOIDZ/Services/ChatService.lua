--!strict

local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ChatService = {}

function ChatService.Init()
	pcall(function()
		TextChatService.ChatVersion = Enum.ChatVersion.TextChatService
	end)
	-- System lines are shown on the client via MatchEvent {kind="sys"} so they
	-- go through TextChatService:DisplaySystemMessage locally (filtered path).
end

function ChatService.Ensure()
	-- Default RBXGeneral exists when ChatVersion is TextChatService.
end

return ChatService
