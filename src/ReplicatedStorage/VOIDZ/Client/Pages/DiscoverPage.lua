--!strict

local GameRegistry = require(script.Parent.Parent.Parent.Shared.GameRegistry)
local Config = require(script.Parent.Parent.Parent.Shared.Config)
local Theme = require(script.Parent.Parent.Theme)
local UI = require(script.Parent.Parent.UIKit)
local GameCard = require(script.Parent.Parent.Components.GameCard)

local DiscoverPage = {}

function DiscoverPage.mount(parent: Instance, deps: any)
	local root = UI.create("Frame", {
		Parent = parent,
		Name = "Discover",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	})
	local cat = deps.initialCategory or "All"
	local header = UI.create("Frame", {
		Parent = root,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 84),
	})
	UI.text({
		Parent = header,
		Text = "Discover",
		Font = Theme.FontBlack,
		TextSize = 28,
		Size = UDim2.new(1, 0, 0, 32),
	})
	local tabs = UI.scroll({
		Parent = header,
		Position = UDim2.fromOffset(0, 40),
		Size = UDim2.new(1, 0, 0, 40),
		ScrollingDirection = Enum.ScrollingDirection.X,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
	})
	UI.list(tabs, 8, Enum.FillDirection.Horizontal)

	local gridHost = UI.scroll({
		Parent = root,
		Position = UDim2.fromOffset(0, 92),
		Size = UDim2.new(1, 0, 1, -92),
	})
	local grid = UI.grid(gridHost, Vector2.new(220, 214), 12)

	local paintTabs
	local paintGrid

	paintTabs = function()
		for _, ch in tabs:GetChildren() do
			if ch:IsA("GuiButton") then
				ch:Destroy()
			end
		end
		local function tab(name: string)
			UI.button({
				Parent = tabs,
				Text = name,
				Accent = cat == name,
				Ghost = cat ~= name,
				Size = UDim2.fromOffset(108, 34),
				TextSize = 13,
				OnClick = function()
					cat = name
					paintTabs()
					paintGrid()
				end,
			})
		end
		tab("All")
		tab("Featured")
		tab("Popular")
		for _, c in Config.Categories do
			tab(c)
		end
	end

	paintGrid = function()
		for _, ch in gridHost:GetChildren() do
			if ch:IsA("GuiButton") then
				ch:Destroy()
			end
		end
		local list
		if cat == "All" then
			list = table.clone(GameRegistry.GetAll())
		elseif cat == "Featured" then
			list = GameRegistry.GetFeatured()
		elseif cat == "Popular" then
			list = table.clone(GameRegistry.GetAll())
			table.sort(list, function(a, b)
				local la = deps.getLive()
				local pa = la and la[a.Id] and la[a.Id].plays or a.SeedPopularity
				local pb = la and la[b.Id] and la[b.Id].plays or b.SeedPopularity
				return pa > pb
			end)
		else
			list = GameRegistry.GetByCategory(cat)
		end
		if #list == 0 then
			UI.empty(gridHost, "Nothing here yet", "New games will land in this category.")
			return
		end
		for _, g in list do
			GameCard.Create(gridHost, g, deps.getLive(), deps.openGame, false)
		end
	end

	paintTabs()
	paintGrid()
	return {
		refresh = paintGrid,
		setCategory = function(c: string)
			cat = c or "All"
			paintTabs()
			paintGrid()
		end,
		destroy = function()
			root:Destroy()
		end,
		root = root,
	}
end

return DiscoverPage
