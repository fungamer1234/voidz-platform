--!strict

local GameRegistry = require(script.Parent.Parent.Parent.Shared.GameRegistry)
local Utility = require(script.Parent.Parent.Parent.Shared.Utility)
local Config = require(script.Parent.Parent.Parent.Shared.Config)
local Theme = require(script.Parent.Parent.Theme)
local UI = require(script.Parent.Parent.UIKit)
local GameCard = require(script.Parent.Parent.Components.GameCard)

local HomePage = {}

local function recommend(data: any): { GameRegistry.GameDef }
	local cats: { [string]: number } = {}
	for _, id in data.recentlyPlayed or {} do
		local g = GameRegistry.Get(id)
		if g then
			cats[g.Category] = (cats[g.Category] or 0) + 2
		end
	end
	for _, id in data.favorites or {} do
		local g = GameRegistry.Get(id)
		if g then
			cats[g.Category] = (cats[g.Category] or 0) + 3
		end
	end
	local list = {}
	for _, g in GameRegistry.GetAll() do
		local s = (cats[g.Category] or 0) + g.SeedPopularity / 100000
		if Utility.includes(data.recentlyPlayed or {}, g.Id) then
			s -= 0.5
		end
		table.insert(list, { g = g, s = s })
	end
	table.sort(list, function(a, b)
		return a.s > b.s
	end)
	local out = {}
	for i = 1, math.min(6, #list) do
		table.insert(out, list[i].g)
	end
	return out
end

local function popular(live: any): { GameRegistry.GameDef }
	local list = {}
	for _, g in GameRegistry.GetAll() do
		local plays = live and live[g.Id] and live[g.Id].plays or g.SeedPopularity
		table.insert(list, { g = g, p = plays })
	end
	table.sort(list, function(a, b)
		return a.p > b.p
	end)
	local out = {}
	for i = 1, math.min(8, #list) do
		table.insert(out, list[i].g)
	end
	return out
end

local function shelf(parent: Instance, title: string, games: { GameRegistry.GameDef }, live: any, openGame: (string) -> (), order: number)
	if #games == 0 then
		return
	end
	local wrap = UI.create("Frame", {
		Parent = parent,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 250),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order,
	})
	UI.text({
		Parent = wrap,
		Text = title,
		Font = Theme.FontBold,
		TextSize = 20,
		Size = UDim2.new(1, 0, 0, 28),
	})
	local sc = UI.scroll({
		Parent = wrap,
		Position = UDim2.fromOffset(0, 36),
		Size = UDim2.new(1, 0, 0, 220),
		ScrollingDirection = Enum.ScrollingDirection.X,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		CanvasSize = UDim2.new(),
	})
	local layout = UI.list(sc, 12, Enum.FillDirection.Horizontal)
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	for _, g in games do
		GameCard.Create(sc, g, live, openGame, false)
	end
end

function HomePage.mount(parent: Instance, deps: any)
	local root = UI.scroll({
		Parent = parent,
		Name = "Home",
		Size = UDim2.fromScale(1, 1),
		Pad = { 8, 4, 8, 24 },
	})
	local layout = UI.list(root, 18)
	layout.SortOrder = Enum.SortOrder.LayoutOrder

	local function refresh()
		for _, ch in root:GetChildren() do
			if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then
				ch:Destroy()
			end
		end
		local data = deps.getData()
		local live = deps.getLive()
		local name = data.profile.displayName ~= "" and data.profile.displayName or deps.robloxName()

		local hero = UI.create("Frame", {
			Parent = root,
			BackgroundColor3 = Theme.Surface,
			Size = UDim2.new(1, 0, 0, 168),
			Corner = 20,
			Stroke = true,
			LayoutOrder = 1,
		})
		Theme.gradient(hero, Color3.fromRGB(40, 28, 90), Color3.fromRGB(18, 40, 48), 20)
		UI.text({
			Parent = hero,
			Text = "Welcome back, " .. name,
			Font = Theme.FontBlack,
			TextSize = 28,
			Position = UDim2.fromOffset(24, 28),
			Size = UDim2.new(1, -48, 0, 36),
		})
		UI.text({
			Parent = hero,
			Text = Config.Tagline .. "  ·  " .. tostring(deps.lobbyPlayers()) .. " in lobby",
			TextColor3 = Theme.TextMuted,
			Position = UDim2.fromOffset(24, 72),
			Size = UDim2.new(1, -48, 0, 22),
		})
		UI.button({
			Parent = hero,
			Text = "Discover games",
			Accent = true,
			Size = UDim2.fromOffset(180, 40),
			Position = UDim2.fromOffset(24, 108),
			OnClick = function()
				deps.openPage("Discover")
			end,
		})
		UI.button({
			Parent = hero,
			Text = "Edit avatar",
			Ghost = true,
			Size = UDim2.fromOffset(140, 40),
			Position = UDim2.fromOffset(214, 108),
			OnClick = function()
				deps.openPage("Avatar")
			end,
		})
		UI.button({
			Parent = hero,
			Text = "Daily drop",
			Ghost = true,
			Size = UDim2.fromOffset(120, 40),
			Position = UDim2.fromOffset(364, 108),
			OnClick = function()
				deps.claimDaily()
			end,
		})

		local featured = GameRegistry.GetFeatured()
		if #featured > 0 then
			local feat = UI.create("Frame", {
				Parent = root,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 200),
				LayoutOrder = 2,
			})
			UI.text({ Parent = feat, Text = "Featured", Font = Theme.FontBold, TextSize = 20, Size = UDim2.new(1, 0, 0, 28) })
			local row = UI.create("Frame", {
				Parent = feat,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, 32),
				Size = UDim2.new(1, 0, 0, 168),
			})
			local g = Instance.new("UIGridLayout")
			g.CellPadding = UDim2.fromOffset(12, 12)
			g.CellSize = UDim2.new(0.25, -12, 1, 0)
			g.FillDirectionMaxCells = 4
			g.Parent = row
			for i = 1, math.min(4, #featured) do
				GameCard.Create(row, featured[i], live, deps.openGame, true)
			end
		end

		local recent = {}
		for _, id in data.recentlyPlayed or {} do
			local g = GameRegistry.Get(id)
			if g then
				table.insert(recent, g)
			end
		end
		shelf(root, "Continue playing", recent, live, deps.openGame, 3)
		shelf(root, "Recommended", recommend(data), live, deps.openGame, 4)
		shelf(root, "Popular", popular(live), live, deps.openGame, 5)

		local cats = UI.create("Frame", {
			Parent = root,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 80),
			LayoutOrder = 6,
		})
		UI.text({ Parent = cats, Text = "Categories", Font = Theme.FontBold, TextSize = 20, Size = UDim2.new(1, 0, 0, 28) })
		local crow = UI.create("Frame", {
			Parent = cats,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 36),
			Size = UDim2.new(1, 0, 0, 40),
		})
		UI.list(crow, 8, Enum.FillDirection.Horizontal)
		for _, c in Config.Categories do
			UI.button({
				Parent = crow,
				Text = c,
				Ghost = true,
				Size = UDim2.fromOffset(110, 36),
				TextSize = 13,
				OnClick = function()
					deps.openDiscover(c)
				end,
			})
		end
	end

	refresh()
	return {
		refresh = refresh,
		destroy = function()
			root:Destroy()
		end,
		root = root,
	}
end

return HomePage
