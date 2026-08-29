--!strict

local GameRegistry = require(script.Parent.Parent.Parent.Shared.GameRegistry)
local Utility = require(script.Parent.Parent.Parent.Shared.Utility)
local Theme = require(script.Parent.Parent.Theme)
local UI = require(script.Parent.Parent.UIKit)
local Audio = require(script.Parent.Parent.AudioController)
local Anim = require(script.Parent.Parent.AnimationController)

local GameCard = {}

function GameCard.PaintThumb(parent: Instance, g: GameRegistry.GameDef, tall: boolean?): Frame
	local a = GameRegistry.AccentColor(g)
	local b = GameRegistry.Accent2Color(g)
	local thumb = UI.create("Frame", {
		Parent = parent,
		Name = "Thumb",
		BackgroundColor3 = a,
		Size = if tall then UDim2.new(1, 0, 0, 150) else UDim2.new(1, 0, 0, 92),
		BorderSizePixel = 0,
		Corner = 12,
	})
	Theme.gradient(thumb, a, b, 35)
	UI.text({
		Parent = thumb,
		Text = GameRegistry.Mark(g),
		Font = Theme.FontBlack,
		TextSize = if tall then 42 else 28,
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = Theme.White,
		BackgroundTransparency = 1,
	})
	if not GameRegistry.IsPlayable(g.Id) then
		UI.text({
			Parent = thumb,
			Text = " COMING SOON ",
			Font = Theme.FontBold,
			TextSize = 11,
			TextColor3 = Theme.White,
			BackgroundColor3 = Theme.Black,
			BackgroundTransparency = 0.35,
			Size = UDim2.fromOffset(108, 20),
			Position = UDim2.new(1, -116, 1, -28),
			TextXAlignment = Enum.TextXAlignment.Center,
			Corner = 8,
		})
	end
	return thumb
end

function GameCard.Create(parent: Instance, g: GameRegistry.GameDef, live: any, onOpen: (string) -> (), wide: boolean?): TextButton
	local card = UI.create("TextButton", {
		Parent = parent,
		Name = g.Id,
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Theme.Surface,
		Size = if wide then UDim2.new(1, 0, 0, 168) else UDim2.fromOffset(220, 210),
		BorderSizePixel = 0,
		Corner = 16,
		Stroke = true,
	})
	GameCard.PaintThumb(card, g, wide)
	UI.text({
		Parent = card,
		Text = g.Name,
		Font = Theme.FontBold,
		TextSize = 16,
		Position = UDim2.fromOffset(12, if wide then 158 else 100),
		Size = UDim2.new(1, -24, 0, 22),
	})
	local plays = live and live[g.Id] and live[g.Id].plays or g.SeedPopularity
	UI.text({
		Parent = card,
		Text = g.Category .. "  ·  " .. Utility.formatNumber(plays) .. " plays",
		TextColor3 = Theme.TextMuted,
		TextSize = 12,
		Position = UDim2.fromOffset(12, if wide then 180 else 124),
		Size = UDim2.new(1, -24, 0, 18),
	})
	if not wide then
		UI.text({
			Parent = card,
			Text = g.Tagline,
			TextColor3 = Theme.TextDim,
			TextSize = 12,
			Position = UDim2.fromOffset(12, 146),
			Size = UDim2.new(1, -24, 0, 48),
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top,
		})
	end
	card.MouseEnter:Connect(function()
		Audio.Hover()
		Anim.Tween(card, 0.14, { BackgroundColor3 = Theme.Surface2 })
	end)
	card.MouseLeave:Connect(function()
		Anim.Tween(card, 0.14, { BackgroundColor3 = Theme.Surface })
	end)
	card.Activated:Connect(function()
		Audio.Click()
		onOpen(g.Id)
	end)
	return card
end

return GameCard
