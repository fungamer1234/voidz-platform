--!strict

local GameRegistry = require(script.Parent.Parent.Parent.Shared.GameRegistry)
local Utility = require(script.Parent.Parent.Parent.Shared.Utility)
local Theme = require(script.Parent.Parent.Theme)
local UI = require(script.Parent.Parent.UIKit)
local GameCard = require(script.Parent.Parent.Components.GameCard)

local GamePage = {}

function GamePage.mount(parent: Instance, deps: any)
	local root = UI.scroll({
		Parent = parent,
		Name = "Game",
		Size = UDim2.fromScale(1, 1),
		Pad = 4,
	})
	UI.list(root, 16)
	local currentId = deps.gameId

	local function refresh()
		for _, ch in root:GetChildren() do
			if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then
				ch:Destroy()
			end
		end
		currentId = deps.gameId
		local g = GameRegistry.Get(currentId)
		if not g then
			UI.empty(root, "Game missing", "This title isn't in the registry.")
			return
		end
		local data = deps.getData()
		local live = deps.getLive()
		local stats = live and live[g.Id] or { plays = g.SeedPopularity, likes = 0, favorites = 0 }
		local playable = GameRegistry.IsPlayable(g.Id)

		UI.button({
			Parent = root,
			Text = "← Back",
			Ghost = true,
			Size = UDim2.fromOffset(100, 36),
			OnClick = function()
				deps.openPage("Discover")
			end,
		})

		local hero = UI.create("Frame", {
			Parent = root,
			BackgroundColor3 = Theme.Surface,
			Size = UDim2.new(1, 0, 0, 220),
			Corner = 20,
			Stroke = true,
		})
		GameCard.PaintThumb(hero, g, true)
		local overlay = UI.create("Frame", {
			Parent = hero,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(20, 150),
			Size = UDim2.new(1, -40, 0, 56),
		})
		UI.text({
			Parent = overlay,
			Text = g.Name,
			Font = Theme.FontBlack,
			TextSize = 28,
			Size = UDim2.new(0.6, 0, 0, 32),
		})
		UI.text({
			Parent = overlay,
			Text = g.Category .. " · " .. g.Creator .. " · " .. g.MaxPlayers .. " max",
			TextColor3 = Theme.TextMuted,
			Position = UDim2.fromOffset(0, 32),
			Size = UDim2.new(1, 0, 0, 20),
		})

		local actions = UI.create("Frame", {
			Parent = root,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 48),
		})
		UI.list(actions, 10, Enum.FillDirection.Horizontal)

		UI.button({
			Parent = actions,
			Text = if playable then "Play" else "Coming Soon",
			Accent = playable,
			Ghost = not playable,
			Size = UDim2.fromOffset(160, 44),
			OnClick = function()
				deps.playGame(g.Id)
			end,
		})
		local favOn = Utility.includes(data.favorites or {}, g.Id)
		UI.button({
			Parent = actions,
			Text = if favOn then "Favorited" else "Favorite",
			Ghost = not favOn,
			Size = UDim2.fromOffset(130, 44),
			OnClick = function()
				deps.toggleFavorite(g.Id)
			end,
		})
		local likeOn = Utility.includes(data.likes or {}, g.Id)
		UI.button({
			Parent = actions,
			Text = if likeOn then "Liked" else "Like",
			Ghost = not likeOn,
			Size = UDim2.fromOffset(110, 44),
			OnClick = function()
				deps.toggleLike(g.Id)
			end,
		})

		local statsRow = UI.create("Frame", {
			Parent = root,
			BackgroundColor3 = Theme.Surface,
			Size = UDim2.new(1, 0, 0, 88),
			Corner = 16,
			Stroke = true,
			Pad = 16,
		})
		local function stat(x: number, label: string, value: string)
			local f = UI.create("Frame", {
				Parent = statsRow,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(x, 0),
				Size = UDim2.fromScale(0.25, 1),
			})
			UI.text({ Parent = f, Text = value, Font = Theme.FontBlack, TextSize = 22, Size = UDim2.new(1, 0, 0, 28) })
			UI.text({ Parent = f, Text = label, TextColor3 = Theme.TextMuted, TextSize = 13, Position = UDim2.fromOffset(0, 32), Size = UDim2.new(1, 0, 0, 20) })
		end
		stat(0, "Plays", Utility.formatNumber(stats.plays or 0))
		stat(0.25, "Likes", Utility.formatNumber(stats.likes or 0))
		stat(0.5, "Favorites", Utility.formatNumber(stats.favorites or 0))
		stat(0.75, "Status", if playable then "Live" else g.Release)

		local about = UI.create("Frame", {
			Parent = root,
			BackgroundColor3 = Theme.Surface,
			Size = UDim2.new(1, 0, 0, 140),
			AutomaticSize = Enum.AutomaticSize.Y,
			Corner = 16,
			Stroke = true,
			Pad = 16,
		})
		UI.text({ Parent = about, Text = "About", Font = Theme.FontBold, TextSize = 18, Size = UDim2.new(1, 0, 0, 24) })
		UI.text({
			Parent = about,
			Text = g.Description,
			TextColor3 = Theme.TextMuted,
			TextWrapped = true,
			Position = UDim2.fromOffset(0, 32),
			Size = UDim2.new(1, 0, 0, 80),
		})

		local shots = UI.create("Frame", {
			Parent = root,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 120),
		})
		UI.text({ Parent = shots, Text = "Gallery", Font = Theme.FontBold, TextSize = 18, Size = UDim2.new(1, 0, 0, 24) })
		local row = UI.create("Frame", {
			Parent = shots,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 32),
			Size = UDim2.new(1, 0, 0, 88),
		})
		UI.list(row, 10, Enum.FillDirection.Horizontal)
		for i = 1, 3 do
			local f = UI.create("Frame", {
				Parent = row,
				Size = UDim2.fromOffset(180, 88),
				BackgroundColor3 = GameRegistry.AccentColor(g),
				Corner = 12,
			})
			Theme.gradient(f, GameRegistry.AccentColor(g), GameRegistry.Accent2Color(g), 25 + i * 20)
			UI.text({
				Parent = f,
				Text = "Look " .. i,
				Size = UDim2.fromScale(1, 1),
				TextXAlignment = Enum.TextXAlignment.Center,
				Font = Theme.FontBold,
			})
		end

		task.spawn(function()
			local lb = deps.getLeaderboard and deps.getLeaderboard(g.Id)
			if type(lb) == "table" and lb.ok then
				UI.text({ Parent = root, Text = "Wins leaderboard", Font = Theme.FontBold, TextSize = 18, Size = UDim2.new(1, 0, 0, 24) })
				for i, row in lb.wins or {} do
					UI.text({
						Parent = root,
						Text = i .. ". " .. (row.name or "?") .. "  —  " .. tostring(row.value),
						TextColor3 = Theme.TextMuted,
						Size = UDim2.new(1, 0, 0, 18),
					})
				end
			end
		end)

		local more = GameRegistry.GetByCategory(g.Category)
		UI.text({ Parent = root, Text = "More " .. g.Category, Font = Theme.FontBold, TextSize = 18, Size = UDim2.new(1, 0, 0, 24) })
		local moreRow = UI.scroll({
			Parent = root,
			Size = UDim2.new(1, 0, 0, 220),
			ScrollingDirection = Enum.ScrollingDirection.X,
			AutomaticCanvasSize = Enum.AutomaticSize.X,
		})
		UI.list(moreRow, 12, Enum.FillDirection.Horizontal)
		for _, og in more do
			if og.Id ~= g.Id then
				GameCard.Create(moreRow, og, live, deps.openGame, false)
			end
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

return GamePage
