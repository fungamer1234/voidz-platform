--!strict

local Constants = require(script.Parent.Parent.Shared.Constants)
local Config = require(script.Parent.Parent.Shared.Config)
local Utility = require(script.Parent.Parent.Shared.Utility)
local Theme = require(script.Parent.Theme)
local UI = require(script.Parent.UIKit)
local Anim = require(script.Parent.AnimationController)

local Chrome = {}

function Chrome.mount(parent: Instance, deps: any)
	local root = UI.create("Frame", {
		Parent = parent,
		Name = "Main",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Bg,
		BorderSizePixel = 0,
		Visible = false,
	})

	local mobile = deps.isMobile()
	local navW = if mobile then 0 else Theme.NavWidth
	local navH = if mobile then Theme.NavHeightMobile else 0
	local topH = Theme.TopBar

	local nav = UI.create("Frame", {
		Parent = root,
		Name = "Nav",
		BackgroundColor3 = Theme.BgElev,
		BorderSizePixel = 0,
		Size = if mobile then UDim2.new(1, 0, 0, navH) else UDim2.new(0, navW, 1, 0),
		Position = if mobile then UDim2.new(0, 0, 1, -navH) else UDim2.new(),
		ZIndex = 5,
	})
	if not mobile then
		Theme.stroke(nav)
	end

	local top = UI.create("Frame", {
		Parent = root,
		Name = "Top",
		BackgroundColor3 = Theme.BgElev,
		BorderSizePixel = 0,
		Position = if mobile then UDim2.new() else UDim2.fromOffset(navW, 0),
		Size = if mobile then UDim2.new(1, 0, 0, topH) else UDim2.new(1, -navW, 0, topH),
		ZIndex = 4,
	})
	Theme.stroke(top)

	local content = UI.create("Frame", {
		Parent = root,
		Name = "Content",
		BackgroundTransparency = 1,
		Position = if mobile then UDim2.fromOffset(16, topH + 8) else UDim2.fromOffset(navW + 20, topH + 12),
		Size = if mobile then UDim2.new(1, -32, 1, -(topH + navH + 16)) else UDim2.new(1, -(navW + 40), 1, -(topH + 24)),
		ZIndex = 2,
	})

	-- Nav buttons
	local navButtons: { [string]: TextButton } = {}
	local navLayoutParent = nav
	if mobile then
		UI.list(nav, 0, Enum.FillDirection.Horizontal).HorizontalAlignment = Enum.HorizontalAlignment.Center
	else
		local brand = UI.text({
			Parent = nav,
			Text = "VZ",
			Font = Theme.FontBlack,
			TextSize = 22,
			TextColor3 = Theme.Accent,
			Size = UDim2.new(1, 0, 0, 64),
			TextXAlignment = Enum.TextXAlignment.Center,
		})
		local listHost = UI.create("Frame", {
			Parent = nav,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(8, 72),
			Size = UDim2.new(1, -16, 1, -88),
		})
		UI.list(listHost, 6)
		navLayoutParent = listHost
	end

	for _, name in Constants.NAV_ORDER do
		local b = UI.create("TextButton", {
			Parent = navLayoutParent,
			Name = name,
			Text = if mobile then Constants.NAV_GLYPHS[name] else Constants.NAV_GLYPHS[name] .. "  " .. Constants.NAV_LABELS[name],
			Font = Theme.FontMed,
			TextSize = if mobile then 20 else 14,
			TextColor3 = Theme.TextMuted,
			BackgroundColor3 = Theme.Surface,
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Size = if mobile then UDim2.new(1 / #Constants.NAV_ORDER, -4, 1, -8) else UDim2.new(1, 0, 0, 40),
			Corner = 10,
			BorderSizePixel = 0,
		})
		b.Activated:Connect(function()
			deps.openPage(name)
		end)
		navButtons[name] = b
	end

	function Chrome.setActive(page: string)
		for name, b in navButtons do
			local on = name == page or (page == "Game" and name == "Discover") or (page == "Search" and name == "Discover")
			b.TextColor3 = if on then Theme.Text else Theme.TextMuted
			b.BackgroundTransparency = if on then 0.35 else 1
		end
	end

	-- Top bar
	local search = UI.input({
		Parent = top,
		PlaceholderText = "Search games, categories, players",
		Text = "",
		Position = UDim2.fromOffset(16, 14),
		Size = UDim2.new(0.42, 0, 0, 36),
	})
	local searchStamp = 0
	search:GetPropertyChangedSignal("Text"):Connect(function()
		searchStamp = os.clock()
		local mine = searchStamp
		task.delay(0.14, function()
			if mine == searchStamp then
				deps.onSearch(search.Text)
			end
		end)
	end)

	local coin = UI.create("Frame", {
		Parent = top,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -168, 0.5, 0),
		Size = UDim2.fromOffset(130, 36),
		BackgroundColor3 = Theme.Surface2,
		Corner = 12,
		Stroke = true,
	})
	local coinText = UI.text({
		Parent = coin,
		Text = "0 VC",
		Font = Theme.FontBold,
		TextColor3 = Theme.Accent2,
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	function Chrome.setCoins(n: number)
		coinText.Text = Utility.formatNumber(n) .. " " .. Config.CurrencySymbol
	end

	local bell = UI.iconButton({
		Parent = top,
		Text = "●",
		Ghost = true,
		Size = UDim2.fromOffset(36, 36),
		Position = UDim2.new(1, -120, 0.5, -18),
		OnClick = function()
			deps.toggleNotifs()
		end,
	})
	local badge = UI.text({
		Parent = bell,
		Text = "",
		Font = Theme.FontBold,
		TextSize = 10,
		TextColor3 = Theme.White,
		BackgroundColor3 = Theme.Danger,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.new(1, -10, 0, -4),
		TextXAlignment = Enum.TextXAlignment.Center,
		Corner = 8,
		ZIndex = 6,
	})
	function Chrome.setUnread(n: number)
		if n <= 0 then
			badge.BackgroundTransparency = 1
			badge.Text = ""
		else
			badge.BackgroundTransparency = 0
			badge.Text = if n > 9 then "9+" else tostring(n)
		end
	end

	UI.iconButton({
		Parent = top,
		Text = "Lobby",
		Ghost = true,
		Size = UDim2.fromOffset(64, 36),
		Position = UDim2.new(1, -80, 0.5, -18),
		TextSize = 12,
		OnClick = function()
			deps.toggleLobby()
		end,
	})

	-- Notification panel
	local panel = UI.create("Frame", {
		Parent = root,
		Name = "NotifPanel",
		Visible = false,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, topH + 8),
		Size = UDim2.fromOffset(340, 420),
		BackgroundColor3 = Theme.Surface,
		Corner = 16,
		Stroke = true,
		ZIndex = 20,
		Pad = 12,
	})
	UI.text({
		Parent = panel,
		Text = "Notifications",
		Font = Theme.FontBold,
		TextSize = 18,
		Size = UDim2.new(1, -80, 0, 24),
	})
	UI.button({
		Parent = panel,
		Text = "Clear",
		Ghost = true,
		Size = UDim2.fromOffset(70, 28),
		Position = UDim2.new(1, -70, 0, 0),
		TextSize = 12,
		OnClick = function()
			deps.clearNotifs()
		end,
	})
	local nlist = UI.scroll({
		Parent = panel,
		Position = UDim2.fromOffset(0, 36),
		Size = UDim2.new(1, 0, 1, -36),
	})
	UI.list(nlist, 8)

	function Chrome.setPanel(open: boolean)
		panel.Visible = open
	end

	function Chrome.paintNotifs(list: { any })
		for _, ch in nlist:GetChildren() do
			if not ch:IsA("UIListLayout") then
				ch:Destroy()
			end
		end
		if #list == 0 then
			UI.empty(nlist, "All caught up", "Rewards, friends, and system notes land here.")
			return
		end
		for _, n in list do
			local f = UI.create("TextButton", {
				Parent = nlist,
				Text = "",
				AutoButtonColor = false,
				BackgroundColor3 = if n.read then Theme.Surface2 else Theme.AccentDeep,
				Size = UDim2.new(1, 0, 0, 64),
				Corner = 12,
				BorderSizePixel = 0,
			})
			UI.text({
				Parent = f,
				Text = n.title,
				Font = Theme.FontBold,
				TextSize = 14,
				Position = UDim2.fromOffset(10, 8),
				Size = UDim2.new(1, -20, 0, 20),
			})
			UI.text({
				Parent = f,
				Text = n.body,
				TextColor3 = Theme.TextMuted,
				TextSize = 12,
				Position = UDim2.fromOffset(10, 30),
				Size = UDim2.new(1, -20, 0, 24),
				TextWrapped = true,
			})
			f.Activated:Connect(function()
				deps.markRead(n.id)
			end)
		end
	end

	-- Toasts
	local toasts = UI.create("Frame", {
		Parent = root,
		Name = "Toasts",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -(if mobile then navH + 16 else 16)),
		Size = UDim2.fromOffset(320, 240),
		ZIndex = 30,
	})
	UI.list(toasts, 8)
	;(toasts:FindFirstChildOfClass("UIListLayout") :: UIListLayout).VerticalAlignment = Enum.VerticalAlignment.Bottom

	function Chrome.toast(title: string, body: string)
		local f = UI.create("Frame", {
			Parent = toasts,
			BackgroundColor3 = Theme.Surface2,
			Size = UDim2.new(1, 0, 0, 64),
			Corner = 12,
			Stroke = true,
		})
		UI.text({
			Parent = f,
			Text = title,
			Font = Theme.FontBold,
			TextSize = 14,
			Position = UDim2.fromOffset(12, 8),
			Size = UDim2.new(1, -24, 0, 20),
		})
		UI.text({
			Parent = f,
			Text = body,
			TextColor3 = Theme.TextMuted,
			TextSize = 12,
			Position = UDim2.fromOffset(12, 30),
			Size = UDim2.new(1, -24, 0, 24),
		})
		task.delay(4, function()
			Anim.Tween(f, 0.2, { BackgroundTransparency = 1 })
			task.wait(0.2)
			f:Destroy()
		end)
	end

	local banner = UI.create("TextLabel", {
		Parent = root,
		Name = "Banner",
		Visible = false,
		BackgroundColor3 = Theme.AccentDeep,
		TextColor3 = Theme.Text,
		Font = Theme.FontMed,
		TextSize = 14,
		Size = UDim2.new(1, -40, 0, 32),
		Position = UDim2.new(0, 20, 0, topH + 4),
		ZIndex = 8,
		Corner = 8,
		BorderSizePixel = 0,
	})
	function Chrome.announce(text: string?)
		if type(text) == "string" and text ~= "" then
			banner.Visible = true
			banner.Text = "  " .. text
		else
			banner.Visible = false
		end
	end

	function Chrome.setSearch(text: string)
		if search.Text ~= text then
			search.Text = text
		end
	end

	function Chrome.focusSearch()
		search:CaptureFocus()
	end

	return {
		root = root,
		content = content,
		setActive = Chrome.setActive,
		setCoins = Chrome.setCoins,
		setUnread = Chrome.setUnread,
		setPanel = Chrome.setPanel,
		paintNotifs = Chrome.paintNotifs,
		toast = Chrome.toast,
		announce = Chrome.announce,
		setSearch = Chrome.setSearch,
		focusSearch = Chrome.focusSearch,
		show = function()
			root.Visible = true
		end,
		hide = function()
			root.Visible = false
		end,
	}
end

return Chrome
