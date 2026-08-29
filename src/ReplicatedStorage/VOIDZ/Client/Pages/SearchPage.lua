--!strict

local GameRegistry = require(script.Parent.Parent.Parent.Shared.GameRegistry)
local Config = require(script.Parent.Parent.Parent.Shared.Config)
local Theme = require(script.Parent.Parent.Theme)
local UI = require(script.Parent.Parent.UIKit)
local GameCard = require(script.Parent.Parent.Components.GameCard)

local SearchPage = {}

function SearchPage.mount(parent: Instance, deps: any)
	local root = UI.scroll({
		Parent = parent,
		Name = "Search",
		Size = UDim2.fromScale(1, 1),
	})
	UI.list(root, 12)
	local q = deps.getQuery() or ""

	local function refresh()
		for _, ch in root:GetChildren() do
			if not ch:IsA("UIListLayout") then
				ch:Destroy()
			end
		end
		q = deps.getQuery() or ""
		UI.text({
			Parent = root,
			Text = if q == "" then "Search" else "Results for “" .. q .. "”",
			Font = Theme.FontBlack,
			TextSize = 26,
			Size = UDim2.new(1, 0, 0, 32),
		})
		if q == "" then
			UI.empty(root, "Type to search", "Games, categories, and players in this lobby.")
			return
		end
		local games = GameRegistry.Search(q)
		local cats = {}
		for _, c in Config.Categories do
			if string.find(string.lower(c), string.lower(q), 1, true) then
				table.insert(cats, c)
			end
		end
		if #cats > 0 then
			UI.text({ Parent = root, Text = "Categories", Font = Theme.FontBold, Size = UDim2.new(1, 0, 0, 22) })
			for _, c in cats do
				UI.button({
					Parent = root,
					Text = c,
					Ghost = true,
					Size = UDim2.new(1, 0, 0, 40),
					OnClick = function()
						deps.openDiscover(c)
					end,
				})
			end
		end
		UI.text({ Parent = root, Text = "Games", Font = Theme.FontBold, Size = UDim2.new(1, 0, 0, 22) })
		if #games == 0 then
			UI.empty(root, "No games", "Nothing in the registry matches that.")
		else
			local wrap = UI.create("Frame", {
				Parent = root,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 220),
				AutomaticSize = Enum.AutomaticSize.Y,
			})
			UI.grid(wrap, Vector2.new(220, 214), 12)
			for _, g in games do
				GameCard.Create(wrap, g, deps.getLive(), deps.openGame, false)
			end
		end
		UI.text({ Parent = root, Text = "Players", Font = Theme.FontBold, Size = UDim2.new(1, 0, 0, 22) })
		local players = deps.getPlayerResults() or {}
		if #players == 0 then
			UI.text({
				Parent = root,
				Text = "No matching players in this lobby.",
				TextColor3 = Theme.TextDim,
				Size = UDim2.new(1, 0, 0, 20),
			})
		else
			for _, p in players do
				UI.button({
					Parent = root,
					Text = (p.displayName or p.name) .. "  @" .. p.name,
					Ghost = true,
					Size = UDim2.new(1, 0, 0, 40),
					OnClick = function()
						deps.viewProfile(p.userId)
					end,
				})
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

return SearchPage
