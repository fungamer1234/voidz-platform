--!strict

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local Theme = require(script.Parent.Parent.Theme)
local UI = require(script.Parent.Parent.UIKit)
local Net = require(script.Parent.Parent.Net)
local Audio = require(script.Parent.Parent.AudioController)
local GameRegistry = require(script.Parent.Parent.Parent.Shared.GameRegistry)

local MatchClient = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local hud: Frame
local loadLayer: Frame
local results: Frame
local objLabel: TextLabel
local timeLabel: TextLabel
local board: Frame
local actionBar: Frame
local feed: Frame
local state: any = { phase = "Idle" }
local cursor = { x = 0, y = 0, z = 0, color = 1 }
local lastActionAt: { [string]: number } = {}

local function sys(text: string)
	pcall(function()
		local chans = TextChatService:FindFirstChild("TextChannels")
		local gen = chans and chans:FindFirstChild("RBXGeneral")
		if gen and gen:IsA("TextChannel") then
			gen:DisplaySystemMessage("[VOIDZ] " .. text)
		end
	end)
end

local function platformVisible(on: boolean)
	local pg = player:FindFirstChildOfClass("PlayerGui")
	if not pg then
		return
	end
	local pgui = pg:FindFirstChild("VOIDZ")
	if pgui and pgui:IsA("ScreenGui") then
		pgui.Enabled = on
	end
	local peek = pg:FindFirstChild("VOIDZ_Peek")
	if peek and peek:IsA("ScreenGui") then
		peek.Enabled = false
	end
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		if on then
			hum.WalkSpeed = 0
			hum.JumpHeight = 0
		else
			if hum.WalkSpeed == 0 then
				hum.WalkSpeed = 16
			end
			if hum.JumpHeight == 0 then
				hum.JumpHeight = 7.2
			end
		end
	end
end

local function remaining(): number
	if type(state.endsAt) ~= "number" then
		return 0
	end
	return math.max(0, state.endsAt - os.time())
end

local function paintBoard()
	for _, ch in board:GetChildren() do
		if ch:IsA("TextLabel") then
			ch:Destroy()
		end
	end
	local list = table.clone(state.players or {})
	table.sort(list, function(a, b)
		return (a.score or 0) > (b.score or 0)
	end)
	for i, row in list do
		if i > 8 then
			break
		end
		UI.text({
			Parent = board,
			Text = i .. ". " .. (row.name or "?") .. "  " .. tostring(math.floor(row.score or 0)) .. (if row.alive == false then "  ✕" else ""),
			TextSize = 13,
			TextColor3 = if row.userId == player.UserId then Theme.Accent2 else Theme.Text,
			Size = UDim2.new(1, 0, 0, 18),
		})
	end
end

local function doAction(name: string, payload: any?)
	local now = os.clock()
	if (lastActionAt[name] or 0) + 0.12 > now then
		return
	end
	lastActionAt[name] = now
	Audio.Click()
	if name == "place" then
		payload = { x = cursor.x, y = cursor.y, z = cursor.z, color = cursor.color }
	elseif name == "delete" then
		payload = { x = cursor.x, y = cursor.y, z = cursor.z }
	elseif name == "buy" then
		payload = { egg = cursor.color }
	elseif name == "vote" then
		local first
		for _, row in state.players or {} do
			if row.userId ~= player.UserId then
				first = row.userId
				break
			end
		end
		payload = { userId = first }
	end
	task.spawn(function()
		Net.Invoke("MatchAction", name, payload)
	end)
end

local function paintActions()
	for _, ch in actionBar:GetChildren() do
		if ch:IsA("GuiButton") or ch:IsA("TextLabel") then
			ch:Destroy()
		end
	end
	local acts = state.actions or {}
	if state.gameId == "build_battle" and state.extra and state.extra.phase == "build" then
		for _, d in { { "N", 0, 1 }, { "S", 0, -1 }, { "E", 1, 0 }, { "W", -1, 0 } } do
			UI.button({
				Parent = actionBar,
				Text = d[1],
				Ghost = true,
				Size = UDim2.fromOffset(44, 40),
				OnClick = function()
					cursor.x += d[2]
					cursor.z += d[3]
				end,
			})
		end
		UI.button({
			Parent = actionBar,
			Text = "Up",
			Ghost = true,
			Size = UDim2.fromOffset(48, 40),
			OnClick = function()
				cursor.y = math.min(8, cursor.y + 1)
			end,
		})
		UI.button({
			Parent = actionBar,
			Text = "Down",
			Ghost = true,
			Size = UDim2.fromOffset(56, 40),
			OnClick = function()
				cursor.y = math.max(0, cursor.y - 1)
			end,
		})
		UI.button({
			Parent = actionBar,
			Text = "Color",
			Ghost = true,
			Size = UDim2.fromOffset(64, 40),
			OnClick = function()
				cursor.color = (cursor.color % 8) + 1
			end,
		})
	end
	if state.gameId == "pet_planet" then
		for i = 1, 3 do
			UI.button({
				Parent = actionBar,
				Text = "Egg " .. i,
				Ghost = true,
				Size = UDim2.fromOffset(70, 40),
				OnClick = function()
					cursor.color = i
					doAction("buy", { egg = i })
				end,
			})
		end
	end
	for _, a in acts do
		UI.button({
			Parent = actionBar,
			Text = string.upper(a),
			Accent = a == "attack" or a == "play" or a == "roll" or a == "boost",
			Ghost = not (a == "attack" or a == "roll" or a == "boost"),
			Size = UDim2.fromOffset(88, 40),
			TextSize = 13,
			OnClick = function()
				doAction(a)
			end,
		})
	end
end

local function showResults()
	results.Visible = true
	for _, ch in results:GetChildren() do
		if not ch:IsA("UICorner") and not ch:IsA("UIStroke") and not ch:IsA("UIPadding") and not ch:IsA("UIListLayout") then
			ch:Destroy()
		end
	end
	UI.text({
		Parent = results,
		Text = "RESULTS",
		Font = Theme.FontBlack,
		TextSize = 26,
		Size = UDim2.new(1, 0, 0, 32),
	})
	UI.text({
		Parent = results,
		Text = state.extra and state.extra.reason or "Round over",
		TextColor3 = Theme.TextMuted,
		Size = UDim2.new(1, 0, 0, 20),
	})
	for _, row in (state.extra and state.extra.results) or {} do
		UI.text({
			Parent = results,
			Text = "#"
				.. tostring(row.placement)
				.. "  "
				.. row.name
				.. "   "
				.. tostring(row.score)
				.. "   +"
				.. tostring(row.coins)
				.. " VC",
			TextColor3 = if row.won then Theme.Accent2 else Theme.Text,
			Size = UDim2.new(1, 0, 0, 22),
		})
	end
	UI.button({
		Parent = results,
		Text = "Play again",
		Accent = true,
		Size = UDim2.new(1, 0, 0, 42),
		OnClick = function()
			Net.Invoke("PlayAgain")
		end,
	})
	UI.button({
		Parent = results,
		Text = "Return to VOIDZ",
		Ghost = true,
		Size = UDim2.new(1, 0, 0, 42),
		OnClick = function()
			Net.Invoke("LeaveMatch")
		end,
	})
end

local function applyState(s: any)
	if type(s) ~= "table" then
		return
	end
	state = s
	local idle = s.phase == "Idle" or s.phase == nil or s.phase == ""
	gui.Enabled = not idle
	platformVisible(idle)
	if idle then
		ContextActionService:UnbindAction("VOIDZ_MatchAct")
		return
	end
	loadLayer.Visible = s.phase == "Loading" or s.phase == "Lobby" or s.phase == "Countdown"
	hud.Visible = s.phase == "Playing" or s.phase == "Countdown"
	results.Visible = s.phase == "Results"
	local g = GameRegistry.Get(s.gameId or "")
	objLabel.Text = (s.objective or "") .. (if s.extra and s.extra.modifier then "  ·  " .. s.extra.modifier else "")
	if g then
		objLabel.Text = g.Name .. " — " .. objLabel.Text
	end
	if s.phase == "Results" then
		showResults()
	else
		results.Visible = false
	end
	paintBoard()
	paintActions()
	if s.phase == "Loading" then
		loadLayer:FindFirstChild("Status").Text = "Loading map..."
	elseif s.phase == "Lobby" then
		loadLayer:FindFirstChild("Status").Text = "Waiting for players..."
	elseif s.phase == "Countdown" then
		loadLayer:FindFirstChild("Status").Text = s.objective or "Get ready"
	end
end

function MatchClient.start()
	local pg = player:WaitForChild("PlayerGui")
	gui = Instance.new("ScreenGui")
	gui.Name = "VOIDZ_Match"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 220
	gui.Enabled = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = pg

	loadLayer = UI.create("Frame", {
		Parent = gui,
		Name = "Load",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Bg,
		BorderSizePixel = 0,
		Visible = false,
	})
	Theme.gradient(loadLayer, Color3.fromRGB(10, 8, 22), Color3.fromRGB(30, 16, 48), 110)
	UI.text({
		Parent = loadLayer,
		Name = "Title",
		Text = "VOIDZ",
		Font = Theme.FontBlack,
		TextSize = 42,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.4),
		Size = UDim2.fromOffset(420, 50),
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	UI.text({
		Parent = loadLayer,
		Name = "Status",
		Text = "Loading map...",
		TextColor3 = Theme.TextMuted,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(420, 28),
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	UI.text({
		Parent = loadLayer,
		Name = "Tip",
		Text = "Party members in this server join the same match.",
		TextColor3 = Theme.TextDim,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.58, 0),
		Size = UDim2.fromOffset(480, 40),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextWrapped = true,
	})

	hud = UI.create("Frame", {
		Parent = gui,
		Name = "Hud",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
	})
	local top = UI.create("Frame", {
		Parent = hud,
		BackgroundColor3 = Theme.BgElev,
		BackgroundTransparency = 0.15,
		Size = UDim2.new(1, -32, 0, 64),
		Position = UDim2.fromOffset(16, 12),
		Corner = 14,
		Stroke = true,
	})
	objLabel = UI.text({
		Parent = top,
		Text = "",
		Font = Theme.FontBold,
		TextSize = 16,
		Position = UDim2.fromOffset(16, 8),
		Size = UDim2.new(1, -140, 0, 24),
	})
	timeLabel = UI.text({
		Parent = top,
		Text = "0:00",
		Font = Theme.FontBlack,
		TextSize = 22,
		TextColor3 = Theme.Accent2,
		Position = UDim2.new(1, -120, 0, 16),
		Size = UDim2.fromOffset(104, 32),
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	board = UI.create("Frame", {
		Parent = hud,
		BackgroundColor3 = Theme.Surface,
		BackgroundTransparency = 0.12,
		Size = UDim2.fromOffset(220, 180),
		Position = UDim2.new(1, -236, 0, 88),
		Corner = 12,
		Stroke = true,
		Pad = 10,
	})
	UI.list(board, 2)
	feed = UI.create("Frame", {
		Parent = hud,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(280, 120),
		Position = UDim2.fromOffset(16, 88),
	})
	UI.list(feed, 4)
	actionBar = UI.create("Frame", {
		Parent = hud,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -18),
		Size = UDim2.new(0.9, 0, 0, 48),
	})
	UI.list(actionBar, 8, Enum.FillDirection.Horizontal).HorizontalAlignment = Enum.HorizontalAlignment.Center

	UI.button({
		Parent = hud,
		Text = "Leave",
		Ghost = true,
		Size = UDim2.fromOffset(80, 32),
		Position = UDim2.fromOffset(16, 80),
		TextSize = 13,
		OnClick = function()
			Net.Invoke("LeaveMatch")
		end,
	})

	results = UI.create("Frame", {
		Parent = gui,
		Visible = false,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(420, 420),
		BackgroundColor3 = Theme.Surface,
		Corner = 18,
		Stroke = true,
		Pad = 16,
	})
	UI.list(results, 8)

	Net.Event("MatchState").OnClientEvent:Connect(applyState)
	Net.Event("MatchEvent").OnClientEvent:Connect(function(ev)
		if type(ev) ~= "table" then
			return
		end
		if ev.kind == "sys" and type(ev.text) == "string" then
			sys(ev.text)
			local line = UI.text({
				Parent = feed,
				Text = ev.text,
				TextColor3 = Theme.Accent2,
				TextSize = 13,
				Size = UDim2.new(1, 0, 0, 18),
			})
			task.delay(4, function()
				if line.Parent then
					line:Destroy()
				end
			end)
		end
		Audio.Click()
	end)

	task.spawn(function()
		while gui.Parent do
			task.wait(0.25)
			if gui.Enabled then
				local r = remaining()
				timeLabel.Text = string.format("%d:%02d", math.floor(r / 60), r % 60)
			end
		end
	end)

	ContextActionService:BindAction("VOIDZ_MatchPrimary", function(_n, st)
		if st == Enum.UserInputState.Begin and gui.Enabled and state.phase == "Playing" then
			local acts = state.actions or {}
			if table.find(acts, "attack") then
				doAction("attack")
			elseif table.find(acts, "roll") then
				doAction("roll")
			elseif table.find(acts, "boost") then
				doAction("boost")
			end
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2)

	UserInputService.InputBegan:Connect(function(input, gp)
		if gp or not gui.Enabled then
			return
		end
		if input.KeyCode == Enum.KeyCode.Q and table.find(state.actions or {}, "dash") then
			doAction("dash")
		elseif input.KeyCode == Enum.KeyCode.E and table.find(state.actions or {}, "grab") then
			doAction("grab")
		elseif input.KeyCode == Enum.KeyCode.F and table.find(state.actions or {}, "lock") then
			doAction("lock")
		elseif input.KeyCode == Enum.KeyCode.R and table.find(state.actions or {}, "roll") then
			doAction("roll")
		elseif input.KeyCode == Enum.KeyCode.LeftShift and table.find(state.actions or {}, "sprint") then
			doAction("sprint")
		elseif input.KeyCode == Enum.KeyCode.F and table.find(state.actions or {}, "block") then
			doAction("block")
		end
	end)
end

return MatchClient
