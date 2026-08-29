--!strict

local AvatarCatalog = require(script.Parent.Parent.Parent.Shared.AvatarCatalog)
local InventoryCatalog = require(script.Parent.Parent.Parent.Shared.InventoryCatalog)
local Constants = require(script.Parent.Parent.Parent.Shared.Constants)
local Theme = require(script.Parent.Parent.Theme)
local UI = require(script.Parent.Parent.UIKit)

local InventoryPage = {}

function InventoryPage.mount(parent: Instance, deps: any)
	local root = UI.create("Frame", {
		Parent = parent,
		Name = "Inventory",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	})
	local mode = "Owned"
	local filter = "All"
	local query = ""
	local sort = "Name"

	UI.text({
		Parent = root,
		Text = "Inventory",
		Font = Theme.FontBlack,
		TextSize = 28,
		Size = UDim2.new(0.4, 0, 0, 32),
	})

	local top = UI.create("Frame", {
		Parent = root,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 40),
		Size = UDim2.new(1, 0, 0, 44),
	})
	UI.list(top, 8, Enum.FillDirection.Horizontal)
	local searchBox = UI.input({
		Parent = top,
		PlaceholderText = "Search items",
		Text = "",
		Size = UDim2.fromOffset(220, 36),
	})
	local debounceAt = 0
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		query = searchBox.Text
		debounceAt = os.clock()
		local stamp = debounceAt
		task.delay(0.12, function()
			if stamp == debounceAt then
				paint()
			end
		end)
	end)

	local gridHost = UI.scroll({
		Parent = root,
		Position = UDim2.fromOffset(0, 132),
		Size = UDim2.new(0.68, -8, 1, -140),
	})
	UI.grid(gridHost, Vector2.new(160, 110), 10)

	local detail = UI.create("Frame", {
		Parent = root,
		Position = UDim2.new(0.68, 8, 0, 132),
		Size = UDim2.new(0.32, -8, 1, -140),
		BackgroundColor3 = Theme.Surface,
		Corner = 16,
		Stroke = true,
		Pad = 16,
	})

	local selectedId: string? = nil

	local function allDefs(): { any }
		local t = {}
		for _, it in AvatarCatalog.GetAll() do
			table.insert(t, it)
		end
		for _, it in InventoryCatalog.GetExtras() do
			table.insert(t, it)
		end
		return t
	end

	local function matches(it: any, data: any): boolean
		if mode == "Owned" then
			if not data.inventory.items[it.Id] then
				return false
			end
		else
			if it.Price == nil or it.Price <= 0 then
				return false
			end
			if data.inventory.items[it.Id] and it.Slot ~= "consumable" then
				return false
			end
		end
		if filter ~= "All" then
			local map = {
				Skin = "skin",
				Hair = "hair",
				Face = "face",
				Shirt = "shirt",
				Pants = "pants",
				Hats = "hat",
				Accessories = "accessory",
				Back = "back",
				Effects = "effect",
				Titles = "title",
			}
			local want = map[filter]
			if want and it.Slot ~= want then
				return false
			end
		end
		if query ~= "" then
			local q = string.lower(query)
			local hay = string.lower((it.Name or "") .. " " .. (it.Description or "") .. " " .. (it.Slot or ""))
			if not string.find(hay, q, 1, true) then
				return false
			end
		end
		return true
	end

	local function showDetail(it: any)
		selectedId = it.Id
		for _, ch in detail:GetChildren() do
			if not ch:IsA("UIPadding") and not ch:IsA("UICorner") and not ch:IsA("UIStroke") then
				ch:Destroy()
			end
		end
		local data = deps.getData()
		UI.text({ Parent = detail, Text = it.Name, Font = Theme.FontBold, TextSize = 20, Size = UDim2.new(1, 0, 0, 28) })
		UI.text({
			Parent = detail,
			Text = (it.Rarity or "Common") .. " · " .. (Constants.SLOT_LABELS[it.Slot] or it.Slot or "Item"),
			TextColor3 = Theme.TextMuted,
			Position = UDim2.fromOffset(0, 32),
			Size = UDim2.new(1, 0, 0, 20),
		})
		UI.text({
			Parent = detail,
			Text = it.Description or "",
			TextColor3 = Theme.TextMuted,
			TextWrapped = true,
			Position = UDim2.fromOffset(0, 60),
			Size = UDim2.new(1, 0, 0, 80),
		})
		local owned = data.inventory.items[it.Id] ~= nil
		local equipped = false
		if it.Slot and data.inventory.equipped[it.Slot] == it.Id then
			equipped = true
		end
		if mode == "Shop" or (not owned and it.Price and it.Price > 0) then
			UI.button({
				Parent = detail,
				Text = "Buy · " .. tostring(it.Price) .. " VC",
				Accent = true,
				Size = UDim2.new(1, 0, 0, 40),
				Position = UDim2.fromOffset(0, 160),
				OnClick = function()
					deps.purchase(it.Id)
				end,
			})
		elseif owned and AvatarCatalog.Get(it.Id) then
			UI.button({
				Parent = detail,
				Text = if equipped then "Unequip" else "Equip",
				Accent = not equipped,
				Ghost = equipped,
				Size = UDim2.new(1, 0, 0, 40),
				Position = UDim2.fromOffset(0, 160),
				OnClick = function()
					if equipped then
						deps.unequip(it.Slot)
					else
						deps.equip(it.Id)
					end
				end,
			})
		end
	end

	local function paint()
		local data = deps.getData()
		for _, ch in gridHost:GetChildren() do
			if ch:IsA("GuiButton") or ch:IsA("TextLabel") or ch:IsA("Frame") then
				ch:Destroy()
			end
		end
		local list = {}
		for _, it in allDefs() do
			if matches(it, data) then
				table.insert(list, it)
			end
		end
		if sort == "Price" then
			table.sort(list, function(a, b)
				return (a.Price or 0) < (b.Price or 0)
			end)
		elseif sort == "Rarity" then
			local rank = { Common = 1, Rare = 2, Epic = 3, Legendary = 4 }
			table.sort(list, function(a, b)
				return (rank[a.Rarity] or 0) > (rank[b.Rarity] or 0)
			end)
		else
			table.sort(list, function(a, b)
				return a.Name < b.Name
			end)
		end
		if #list == 0 then
			UI.empty(gridHost, "No items", "Try another filter or open the shop.")
			return
		end
		for _, it in list do
			local eq = it.Slot and data.inventory.equipped[it.Slot] == it.Id
			local btn = UI.create("TextButton", {
				Parent = gridHost,
				Text = "",
				AutoButtonColor = false,
				BackgroundColor3 = Theme.Surface,
				Corner = 12,
				Stroke = true,
				BorderSizePixel = 0,
			})
			UI.text({
				Parent = btn,
				Text = it.Name,
				Font = Theme.FontBold,
				TextSize = 14,
				Position = UDim2.fromOffset(8, 10),
				Size = UDim2.new(1, -16, 0, 36),
				TextWrapped = true,
			})
			UI.text({
				Parent = btn,
				Text = if mode == "Shop" then tostring(it.Price) .. " VC" elseif eq then "Equipped" else (it.Rarity or ""),
				TextColor3 = Theme.TextMuted,
				TextSize = 12,
				Position = UDim2.fromOffset(8, 70),
				Size = UDim2.new(1, -16, 0, 20),
			})
			btn.Activated:Connect(function()
				showDetail(it)
			end)
		end
	end

	local filters = UI.scroll({
		Parent = root,
		Position = UDim2.fromOffset(0, 88),
		Size = UDim2.new(1, 0, 0, 36),
		ScrollingDirection = Enum.ScrollingDirection.X,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
	})
	UI.list(filters, 8, Enum.FillDirection.Horizontal)

	local function paintFilters()
		for _, ch in filters:GetChildren() do
			if ch:IsA("GuiButton") then
				ch:Destroy()
			end
		end
		local function chip(label: string, setter: () -> ())
			UI.button({
				Parent = filters,
				Text = label,
				Ghost = true,
				Size = UDim2.fromOffset(96, 32),
				TextSize = 12,
				OnClick = setter,
			})
		end
		chip(if mode == "Owned" then "• Owned" else "Owned", function()
			mode = "Owned"
			paint()
			paintFilters()
		end)
		chip(if mode == "Shop" then "• Shop" else "Shop", function()
			mode = "Shop"
			paint()
			paintFilters()
		end)
		chip("All", function()
			filter = "All"
			paint()
		end)
		for _, s in { "Skin", "Hair", "Face", "Shirt", "Pants", "Hats", "Accessories", "Back", "Effects", "Titles" } do
			chip(s, function()
				filter = s
				paint()
			end)
		end
		chip("Name", function()
			sort = "Name"
			paint()
		end)
		chip("Price", function()
			sort = "Price"
			paint()
		end)
		chip("Rarity", function()
			sort = "Rarity"
			paint()
		end)
	end

	UI.empty(detail, "Select an item", "Equip, unequip, or buy from the shop.")
	paintFilters()
	paint()

	return {
		refresh = paint,
		destroy = function()
			root:Destroy()
		end,
		root = root,
	}
end

return InventoryPage
