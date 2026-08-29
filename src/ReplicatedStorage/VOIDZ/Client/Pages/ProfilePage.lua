--!strict

local GameRegistry = require(script.Parent.Parent.Parent.Shared.GameRegistry)
local Achievements = require(script.Parent.Parent.Parent.Shared.Achievements)
local Utility = require(script.Parent.Parent.Parent.Shared.Utility)
local Config = require(script.Parent.Parent.Parent.Shared.Config)
local Theme = require(script.Parent.Parent.Theme)
local UI = require(script.Parent.Parent.UIKit)
local ViewportAvatar = require(script.Parent.Parent.ViewportAvatar)
local Validate = require(script.Parent.Parent.Parent.Shared.Validate)

local ProfilePage = {}

function ProfilePage.mount(parent: Instance, deps: any)
	local root = UI.scroll({
		Parent = parent,
		Name = "Profile",
		Size = UDim2.fromScale(1, 1),
		Pad = 4,
	})
	UI.list(root, 14)
	local vp

	local function refresh()
		for _, ch in root:GetChildren() do
			if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then
				ch:Destroy()
			end
		end
		if vp then
			vp.destroy()
			vp = nil
		end
		local data = deps.getData()
		local card = UI.create("Frame", {
			Parent = root,
			BackgroundColor3 = Theme.Surface,
			Size = UDim2.new(1, 0, 0, 180),
			Corner = 18,
			Stroke = true,
		})
		local prev = UI.create("Frame", {
			Parent = card,
			Size = UDim2.fromOffset(140, 156),
			Position = UDim2.fromOffset(12, 12),
			BackgroundColor3 = Theme.BgElev,
			Corner = 14,
		})
		vp = ViewportAvatar.Attach(prev, data.inventory.equipped, data.avatar.skinTone)
		UI.text({
			Parent = card,
			Text = data.profile.displayName ~= "" and data.profile.displayName or deps.robloxName(),
			Font = Theme.FontBlack,
			TextSize = 26,
			Position = UDim2.fromOffset(168, 20),
			Size = UDim2.new(1, -180, 0, 32),
		})
		UI.text({
			Parent = card,
			Text = "@" .. deps.robloxName() .. "  ·  Joined " .. Utility.formatDate(data.profile.createdAt),
			TextColor3 = Theme.TextMuted,
			Position = UDim2.fromOffset(168, 56),
			Size = UDim2.new(1, -180, 0, 22),
		})
		UI.text({
			Parent = card,
			Text = Utility.formatNumber(data.currency.VoidCoins or 0) .. " " .. Config.CurrencySymbol,
			TextColor3 = Theme.Accent2,
			Font = Theme.FontBold,
			TextSize = 18,
			Position = UDim2.fromOffset(168, 86),
			Size = UDim2.new(1, -180, 0, 24),
		})

		local rename = UI.create("Frame", {
			Parent = root,
			BackgroundColor3 = Theme.Surface,
			Size = UDim2.new(1, 0, 0, 72),
			Corner = 16,
			Stroke = true,
			Pad = 12,
		})
		local box = UI.input({
			Parent = rename,
			Text = data.profile.displayName,
			PlaceholderText = "Display name",
			Size = UDim2.new(0.7, -8, 1, 0),
		})
		UI.button({
			Parent = rename,
			Text = "Save name",
			Accent = true,
			Size = UDim2.new(0.3, 0, 1, 0),
			Position = UDim2.new(0.7, 8, 0, 0),
			OnClick = function()
				local ok, name, err = Validate.displayName(box.Text)
				if not ok then
					deps.toast(err)
					return
				end
				deps.setDisplayName(name)
			end,
		})

		local stats = UI.create("Frame", {
			Parent = root,
			BackgroundColor3 = Theme.Surface,
			Size = UDim2.new(1, 0, 0, 100),
			Corner = 16,
			Stroke = true,
			Pad = 12,
		})
		local function s(x: number, label: string, value: string)
			local f = UI.create("Frame", {
				Parent = stats,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(x, 0),
				Size = UDim2.fromScale(0.25, 1),
			})
			UI.text({ Parent = f, Text = value, Font = Theme.FontBlack, TextSize = 22, Size = UDim2.new(1, 0, 0, 28) })
			UI.text({ Parent = f, Text = label, TextColor3 = Theme.TextMuted, Position = UDim2.fromOffset(0, 32), Size = UDim2.new(1, 0, 0, 20) })
		end
		s(0, "Games launched", tostring(data.stats.playClicks or 0))
		s(0.25, "Logins", tostring(data.stats.logins or 0))
		s(0.5, "Items", tostring(data.stats.itemsOwned or 0))
		s(0.75, "Friends", tostring(data.stats.friends or 0))

		UI.text({ Parent = root, Text = "Favorites", Font = Theme.FontBold, TextSize = 18, Size = UDim2.new(1, 0, 0, 24) })
		if #(data.favorites or {}) == 0 then
			UI.text({
				Parent = root,
				Text = "Favorite a game from its page and it will land here.",
				TextColor3 = Theme.TextDim,
				Size = UDim2.new(1, 0, 0, 22),
			})
		else
			for _, id in data.favorites do
				local g = GameRegistry.Get(id)
				if g then
					UI.button({
						Parent = root,
						Text = g.Name .. "  ·  " .. g.Category,
						Ghost = true,
						Size = UDim2.new(1, 0, 0, 40),
						OnClick = function()
							deps.openGame(id)
						end,
					})
				end
			end
		end

		UI.text({ Parent = root, Text = "Quests", Font = Theme.FontBold, TextSize = 18, Size = UDim2.new(1, 0, 0, 24) })
		task.spawn(function()
			local q = deps.getQuests and deps.getQuests()
			if type(q) == "table" and q.ok then
				for _, item in q.quests or {} do
					UI.text({
						Parent = root,
						Text = item.name
							.. "  "
							.. tostring(item.progress)
							.. "/"
							.. tostring(item.target)
							.. (if item.completed then "  done" else ""),
						TextColor3 = if item.completed then Theme.Accent2 else Theme.TextMuted,
						Size = UDim2.new(1, 0, 0, 20),
					})
				end
			end
		end)
		UI.button({
			Parent = root,
			Text = "Accept party invites",
			Ghost = true,
			Size = UDim2.fromOffset(200, 36),
			OnClick = function()
				deps.partyRespond(true)
			end,
		})
		UI.text({ Parent = root, Text = "Achievements", Font = Theme.FontBold, TextSize = 18, Size = UDim2.new(1, 0, 0, 24) })
		for _, a in Achievements.GetAll() do
			local unlocked = data.achievements[a.Id] ~= nil
			local row = UI.create("Frame", {
				Parent = root,
				BackgroundColor3 = Theme.Surface,
				Size = UDim2.new(1, 0, 0, 56),
				Corner = 12,
				Stroke = true,
			})
			UI.text({
				Parent = row,
				Text = a.Icon .. "  " .. a.Name,
				Font = Theme.FontBold,
				TextColor3 = if unlocked then Theme.Text else Theme.TextDim,
				Position = UDim2.fromOffset(14, 8),
				Size = UDim2.new(1, -24, 0, 22),
			})
			UI.text({
				Parent = row,
				Text = if unlocked then a.Description .. " · " .. Utility.formatDate(data.achievements[a.Id]) else a.Description,
				TextColor3 = Theme.TextMuted,
				TextSize = 13,
				Position = UDim2.fromOffset(14, 30),
				Size = UDim2.new(1, -24, 0, 18),
			})
		end
	end

	refresh()
	return {
		refresh = refresh,
		destroy = function()
			if vp then
				vp.destroy()
			end
			root:Destroy()
		end,
		root = root,
	}
end

return ProfilePage
