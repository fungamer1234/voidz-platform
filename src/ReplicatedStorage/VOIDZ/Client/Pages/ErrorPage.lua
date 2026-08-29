--!strict

local Theme = require(script.Parent.Parent.Theme)
local UI = require(script.Parent.Parent.UIKit)
local Config = require(script.Parent.Parent.Parent.Shared.Config)

local ErrorPage = {}

function ErrorPage.create(parent: Instance, message: string, onRetry: () -> ())
	local layer = UI.create("Frame", {
		Parent = parent,
		Name = "Error",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Bg,
		BorderSizePixel = 0,
		ZIndex = 60,
	})
	local card = UI.create("Frame", {
		Parent = layer,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(420, 240),
		BackgroundColor3 = Theme.Surface,
		Corner = 18,
		Stroke = true,
		Pad = 24,
	})
	UI.text({
		Parent = card,
		Text = Config.Name,
		Font = Theme.FontBlack,
		TextSize = 18,
		TextColor3 = Theme.Accent,
		Size = UDim2.new(1, 0, 0, 22),
	})
	UI.text({
		Parent = card,
		Text = "Couldn't load your profile",
		Font = Theme.FontBold,
		TextSize = 22,
		Position = UDim2.fromOffset(0, 36),
		Size = UDim2.new(1, 0, 0, 28),
	})
	UI.text({
		Parent = card,
		Text = message,
		TextColor3 = Theme.TextMuted,
		TextSize = 14,
		TextWrapped = true,
		Position = UDim2.fromOffset(0, 72),
		Size = UDim2.new(1, 0, 0, 60),
	})
	UI.button({
		Parent = card,
		Text = "Retry",
		Accent = true,
		Size = UDim2.fromOffset(140, 40),
		Position = UDim2.fromOffset(0, 150),
		OnClick = onRetry,
	})
	return layer
end

return ErrorPage
