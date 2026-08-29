--!strict

local Theme = require(script.Parent.Parent.Theme)
local UI = require(script.Parent.Parent.UIKit)
local ViewportAvatar = require(script.Parent.Parent.ViewportAvatar)
local Audio = require(script.Parent.Parent.AudioController)
local Config = require(script.Parent.Parent.Parent.Shared.Config)
local Validate = require(script.Parent.Parent.Parent.Shared.Validate)
local AvatarCatalog = require(script.Parent.Parent.Parent.Shared.AvatarCatalog)
local Utility = require(script.Parent.Parent.Parent.Shared.Utility)

local OnboardingPage = {}

local STEPS = { "Welcome", "Name", "Avatar", "Reward", "Done" }

function OnboardingPage.create(parent: Instance, robloxName: string, onFinish: (string, any) -> string?)
	local layer = UI.create("Frame", {
		Parent = parent,
		Name = "Onboarding",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Bg,
		BorderSizePixel = 0,
		ZIndex = 40,
	})

	local displayName = robloxName
	displayName = string.gsub(displayName, "[^%a%d_]", "")
	if #displayName < 3 then
		displayName = "Player" .. tostring(math.random(100, 999))
	end
	if #displayName > 16 then
		displayName = string.sub(displayName, 1, 16)
	end

	local equipped = Utility.deepCopy(Config.DefaultEquipped)
	local skinTone = Utility.deepCopy(Config.DefaultAvatar.skinTone)
	local step = 1
	local errLabel: TextLabel
	local vpHandle
	local nameBox: TextBox
	local body: Frame

	local header = UI.create("Frame", {
		Parent = layer,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -48, 0, 72),
		Position = UDim2.fromOffset(24, 16),
	})
	UI.text({
		Parent = header,
		Text = Config.Name,
		Font = Theme.FontBlack,
		TextSize = 20,
		TextColor3 = Theme.Accent2,
		Size = UDim2.new(0.4, 0, 1, 0),
	})
	local dots = UI.create("Frame", {
		Parent = header,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(180, 16),
	})
	UI.list(dots, 8, Enum.FillDirection.Horizontal)
	local dotFrames = {}
	for i = 1, #STEPS do
		dotFrames[i] = UI.create("Frame", {
			Parent = dots,
			Size = UDim2.fromOffset(22, 8),
			BackgroundColor3 = if i == 1 then Theme.Accent else Theme.Surface3,
			Corner = 4,
			BorderSizePixel = 0,
		})
	end

	body = UI.create("Frame", {
		Parent = layer,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(24, 96),
		Size = UDim2.new(1, -48, 1, -180),
	})

	local footer = UI.create("Frame", {
		Parent = layer,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 24, 1, -72),
		Size = UDim2.new(1, -48, 0, 52),
	})
	errLabel = UI.text({
		Parent = layer,
		Text = "",
		TextColor3 = Theme.Danger,
		TextSize = 14,
		Position = UDim2.new(0, 24, 1, -108),
		Size = UDim2.new(1, -48, 0, 24),
	})

	local backBtn, nextBtn

	local function setDots()
		for i, d in dotFrames do
			d.BackgroundColor3 = if i <= step then Theme.Accent else Theme.Surface3
		end
	end

	local function clearBody()
		for _, ch in body:GetChildren() do
			ch:Destroy()
		end
		if vpHandle then
			vpHandle.destroy()
			vpHandle = nil
		end
	end

	local function render()
		clearBody()
		setDots()
		errLabel.Text = ""
		backBtn.Visible = step > 1 and step < 5
		if step == 5 then
			nextBtn.Text = "Enter VOIDZ"
		elseif step == 4 then
			nextBtn.Text = "Collect"
		else
			nextBtn.Text = "Continue"
		end

		if step == 1 then
			UI.text({
				Parent = body,
				Text = "Welcome to " .. Config.Name,
				Font = Theme.FontBlack,
				TextSize = 36,
				Size = UDim2.new(1, 0, 0, 48),
			})
			UI.text({
				Parent = body,
				Text = "A home for games, avatars, and friends — all on one platform. This profile is yours inside "
					.. Config.Name
					.. ". It is not your Roblox password or account, and we'll never ask for either.",
				TextColor3 = Theme.TextMuted,
				TextSize = 16,
				TextWrapped = true,
				Position = UDim2.fromOffset(0, 64),
				Size = UDim2.new(1, 0, 0, 90),
			})
			UI.text({
				Parent = body,
				Text = "Roblox player: @" .. robloxName,
				TextColor3 = Theme.TextDim,
				TextSize = 14,
				Position = UDim2.fromOffset(0, 164),
				Size = UDim2.new(1, 0, 0, 22),
			})
		elseif step == 2 then
			UI.text({
				Parent = body,
				Text = "Choose a display name",
				Font = Theme.FontBlack,
				TextSize = 32,
				Size = UDim2.new(1, 0, 0, 40),
			})
			UI.text({
				Parent = body,
				Text = "3–16 letters, numbers, or underscores. This is how other VOIDZ players will see you.",
				TextColor3 = Theme.TextMuted,
				TextWrapped = true,
				Position = UDim2.fromOffset(0, 48),
				Size = UDim2.new(1, 0, 0, 48),
			})
			nameBox = UI.input({
				Parent = body,
				Text = displayName,
				PlaceholderText = "Display name",
				Position = UDim2.fromOffset(0, 110),
				Size = UDim2.new(0.6, 0, 0, 48),
			})
			nameBox:GetPropertyChangedSignal("Text"):Connect(function()
				displayName = nameBox.Text
			end)
		elseif step == 3 then
			UI.text({
				Parent = body,
				Text = "Build your look",
				Font = Theme.FontBlack,
				TextSize = 32,
				Size = UDim2.new(1, 0, 0, 40),
			})
			local preview = UI.create("Frame", {
				Parent = body,
				Position = UDim2.fromOffset(0, 56),
				Size = UDim2.new(0.38, 0, 1, -56),
				BackgroundColor3 = Theme.Surface,
				Corner = 16,
				Stroke = true,
			})
			vpHandle = ViewportAvatar.Attach(preview, equipped, skinTone)
			local side = UI.scroll({
				Parent = body,
				Position = UDim2.new(0.4, 12, 0, 56),
				Size = UDim2.new(0.6, -12, 1, -56),
			})
			UI.list(side, 8)
			local function chipRow(slot: string, label: string)
				UI.text({ Parent = side, Text = label, Font = Theme.FontBold, Size = UDim2.new(1, 0, 0, 22) })
				local row = UI.create("Frame", { Parent = side, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44) })
				UI.list(row, 8, Enum.FillDirection.Horizontal)
				for _, it in AvatarCatalog.GetSlot(slot) do
					if it.Starter or it.Price == 0 then
						local b = UI.button({
							Parent = row,
							Text = it.Name,
							Size = UDim2.fromOffset(120, 36),
							TextSize = 13,
							Ghost = equipped[slot] ~= it.Id,
							Accent = equipped[slot] == it.Id,
							OnClick = function()
								equipped[slot] = it.Id
								if slot == "skin" then
									skinTone = { it.Color[1], it.Color[2], it.Color[3] }
								end
								if vpHandle then
									vpHandle.set(equipped, skinTone)
								end
								render()
							end,
						})
					end
				end
			end
			chipRow("skin", "Skin")
			chipRow("hair", "Hair")
			chipRow("shirt", "Shirt")
			chipRow("pants", "Pants")
		elseif step == 4 then
			UI.text({
				Parent = body,
				Text = "Starter grant",
				Font = Theme.FontBlack,
				TextSize = 32,
				Size = UDim2.new(1, 0, 0, 40),
			})
			UI.text({
				Parent = body,
				Text = "A small stack of " .. Config.CurrencyName .. " to get you moving.",
				TextColor3 = Theme.TextMuted,
				Position = UDim2.fromOffset(0, 48),
				Size = UDim2.new(1, 0, 0, 28),
			})
			local coin = UI.create("Frame", {
				Parent = body,
				Position = UDim2.fromOffset(0, 100),
				Size = UDim2.fromOffset(280, 120),
				BackgroundColor3 = Theme.Surface,
				Corner = 18,
				Stroke = true,
				Pad = 18,
			})
			UI.text({
				Parent = coin,
				Text = "+" .. tostring(Config.StarterCurrency) .. " " .. Config.CurrencySymbol,
				Font = Theme.FontBlack,
				TextSize = 32,
				TextColor3 = Theme.Accent2,
				Size = UDim2.new(1, 0, 0, 40),
			})
			UI.text({
				Parent = coin,
				Text = "Spend them in Inventory → Shop. You keep them between sessions.",
				TextColor3 = Theme.TextMuted,
				TextWrapped = true,
				Position = UDim2.fromOffset(0, 48),
				Size = UDim2.new(1, 0, 0, 44),
			})
			Audio.Reward()
		else
			UI.text({
				Parent = body,
				Text = "You're in.",
				Font = Theme.FontBlack,
				TextSize = 36,
				Size = UDim2.new(1, 0, 0, 44),
			})
			UI.text({
				Parent = body,
				Text = "Home is live. Discover games, dress up, and spend VoidCoins. Future titles plug into this same platform.",
				TextColor3 = Theme.TextMuted,
				TextWrapped = true,
				Position = UDim2.fromOffset(0, 56),
				Size = UDim2.new(1, 0, 0, 80),
			})
		end
	end

	backBtn = UI.button({
		Parent = footer,
		Text = "Back",
		Ghost = true,
		Size = UDim2.fromOffset(120, 44),
		OnClick = function()
			if step > 1 then
				step -= 1
				render()
			end
		end,
	})
	nextBtn = UI.button({
		Parent = footer,
		Text = "Continue",
		Accent = true,
		Size = UDim2.fromOffset(180, 44),
		Position = UDim2.new(1, -180, 0, 0),
		OnClick = function()
			if step == 2 then
				local text = if nameBox then nameBox.Text else displayName
				local ok, name, err = Validate.displayName(text)
				if not ok then
					errLabel.Text = err
					Audio.Error()
					return
				end
				displayName = name
			end
			if step < 5 then
				step += 1
				render()
			else
				local err = onFinish(displayName, { equipped = equipped, skinTone = skinTone })
				if type(err) == "string" and err ~= "" then
					errLabel.Text = err
					Audio.Error()
				end
			end
		end,
	})

	render()
	return layer
end

return OnboardingPage
