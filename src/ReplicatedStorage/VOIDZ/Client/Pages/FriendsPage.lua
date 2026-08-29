--!strict

local Theme = require(script.Parent.Parent.Theme)
local UI = require(script.Parent.Parent.UIKit)

local FriendsPage = {}

local function row(parent: Instance, p: any, actions: { { text: string, fn: () -> (), accent: boolean? } })
	local f = UI.create("Frame", {
		Parent = parent,
		BackgroundColor3 = Theme.Surface,
		Size = UDim2.new(1, 0, 0, 64),
		Corner = 12,
		Stroke = true,
	})
	UI.create("Frame", {
		Parent = f,
		Size = UDim2.fromOffset(10, 10),
		Position = UDim2.fromOffset(16, 27),
		BackgroundColor3 = if p.online then Theme.Online else Theme.Offline,
		Corner = 5,
		BorderSizePixel = 0,
	})
	UI.text({
		Parent = f,
		Text = p.displayName or p.name,
		Font = Theme.FontBold,
		TextSize = 16,
		Position = UDim2.fromOffset(36, 10),
		Size = UDim2.new(0.5, 0, 0, 24),
	})
	UI.text({
		Parent = f,
		Text = "@" .. (p.name or "") .. " · " .. (p.source or ""),
		TextColor3 = Theme.TextMuted,
		TextSize = 12,
		Position = UDim2.fromOffset(36, 34),
		Size = UDim2.new(0.5, 0, 0, 18),
	})
	for i, a in actions do
		UI.button({
			Parent = f,
			Text = a.text,
			Accent = a.accent,
			Ghost = not a.accent,
			Size = UDim2.fromOffset(88, 32),
			Position = UDim2.new(1, -8 - (88 + 8) * (#actions - i + 1) + 8, 0.5, -16),
			TextSize = 13,
			OnClick = a.fn,
		})
	end
end

function FriendsPage.mount(parent: Instance, deps: any)
	local root = UI.create("Frame", {
		Parent = parent,
		Name = "Friends",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	})
	UI.text({
		Parent = root,
		Text = "Friends",
		Font = Theme.FontBlack,
		TextSize = 28,
		Size = UDim2.new(1, 0, 0, 32),
	})
	local search = UI.input({
		Parent = root,
		PlaceholderText = "Search players in this server",
		Position = UDim2.fromOffset(0, 40),
		Size = UDim2.new(0.6, 0, 0, 40),
	})
	UI.button({
		Parent = root,
		Text = "Search",
		Accent = true,
		Size = UDim2.fromOffset(100, 40),
		Position = UDim2.new(0.6, 8, 0, 40),
		OnClick = function()
			deps.searchPlayers(search.Text)
		end,
	})

	local list = UI.scroll({
		Parent = root,
		Position = UDim2.fromOffset(0, 92),
		Size = UDim2.new(1, 0, 1, -92),
		Pad = 4,
	})
	UI.list(list, 10)

	local pack = { ok = true, voidz = { accepted = {}, incoming = {}, outgoing = {} }, roblox = {}, server = {}, results = nil }

	local function section(title: string)
		UI.text({
			Parent = list,
			Text = title,
			Font = Theme.FontBold,
			TextSize = 16,
			Size = UDim2.new(1, 0, 0, 22),
		})
	end

	local function paint()
		for _, ch in list:GetChildren() do
			if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then
				ch:Destroy()
			end
		end
		if pack.results then
			section("Search results")
			if #pack.results == 0 then
				UI.empty(list, "No players", "Names match players currently in this lobby.")
			else
				for _, p in pack.results do
					row(list, p, {
						{ text = "Add", accent = true, fn = function()
							deps.friendRequest(p.userId)
						end },
						{ text = "Profile", fn = function()
							deps.viewProfile(p.userId)
						end },
					})
				end
			end
		end
		section("Requests")
		if pack.voidz and #(pack.voidz.incoming or {}) > 0 then
			for _, p in pack.voidz.incoming do
				row(list, p, {
					{ text = "Accept", accent = true, fn = function()
						deps.friendRespond(p.userId, true)
					end },
					{ text = "Decline", fn = function()
						deps.friendRespond(p.userId, false)
					end },
				})
			end
		else
			UI.text({
				Parent = list,
				Text = "No incoming requests.",
				TextColor3 = Theme.TextDim,
				Size = UDim2.new(1, 0, 0, 20),
			})
		end
		section("VOIDZ friends")
		if pack.voidz and #(pack.voidz.accepted or {}) > 0 then
			for _, p in pack.voidz.accepted do
				row(list, p, {
					{ text = "Remove", fn = function()
						deps.removeFriend(p.userId)
					end },
					{ text = "Profile", fn = function()
						deps.viewProfile(p.userId)
					end },
				})
			end
		else
			UI.text({
				Parent = list,
				Text = "No VOIDZ friends yet. Add someone from this lobby.",
				TextColor3 = Theme.TextDim,
				TextWrapped = true,
				Size = UDim2.new(1, 0, 0, 20),
			})
		end
		if pack.voidz and #(pack.voidz.outgoing or {}) > 0 then
			section("Outgoing")
			for _, p in pack.voidz.outgoing do
				row(list, p, { { text = "Pending", fn = function() end } })
			end
		end
		section("Roblox friends")
		if pack.roblox and #pack.roblox > 0 then
			for i, p in pack.roblox do
				if i > 40 then
					break
				end
				row(list, p, {
					{ text = "Add", accent = true, fn = function()
						deps.friendRequest(p.userId)
					end },
				})
			end
		else
			UI.text({
				Parent = list,
				Text = "Roblox friends will appear here when available.",
				TextColor3 = Theme.TextDim,
				Size = UDim2.new(1, 0, 0, 20),
			})
		end
		section("In this lobby")
		if pack.server and #pack.server > 0 then
			for _, p in pack.server do
				row(list, p, {
					{ text = "Add", accent = true, fn = function()
						deps.friendRequest(p.userId)
					end },
					{ text = "Party", fn = function()
						deps.partyInvite(p.userId)
					end },
				})
			end
		else
			UI.text({
				Parent = list,
				Text = "You're the only one here.",
				TextColor3 = Theme.TextDim,
				Size = UDim2.new(1, 0, 0, 20),
			})
		end
	end

	local function apply(res: any)
		if type(res) == "table" and res.ok then
			pack = res
			if res.results then
				pack.results = res.results
			end
			paint()
		end
	end

	paint()
	task.spawn(function()
		local res = deps.loadFriends()
		apply(res)
	end)

	return {
		refresh = function()
			task.spawn(function()
				apply(deps.loadFriends())
			end)
		end,
		apply = apply,
		destroy = function()
			root:Destroy()
		end,
		root = root,
	}
end

return FriendsPage
