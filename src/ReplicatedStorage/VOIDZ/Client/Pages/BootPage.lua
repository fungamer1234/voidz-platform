--!strict

local RunService = game:GetService("RunService")
local Theme = require(script.Parent.Parent.Theme)
local UI = require(script.Parent.Parent.UIKit)
local Anim = require(script.Parent.Parent.AnimationController)
local Audio = require(script.Parent.Parent.AudioController)
local Config = require(script.Parent.Parent.Parent.Shared.Config)

local BootPage = {}

function BootPage.create(parent: Instance)
	local layer = UI.create("Frame", {
		Parent = parent,
		Name = "Boot",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Bg,
		BorderSizePixel = 0,
		ZIndex = 50,
	})
	Theme.gradient(layer, Color3.fromRGB(8, 6, 18), Color3.fromRGB(18, 14, 40), 120)

	local particles: { Frame } = {}
	for i = 1, 24 do
		local p = UI.create("Frame", {
			Parent = layer,
			BackgroundColor3 = if i % 3 == 0 then Theme.Accent else Theme.Accent2,
			BackgroundTransparency = 0.55,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(4, 4),
			Position = UDim2.fromScale(math.random(), math.random()),
			Corner = 2,
			ZIndex = 51,
		})
		table.insert(particles, p)
	end

	local brand = UI.create("Frame", {
		Parent = layer,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromOffset(420, 180),
		ZIndex = 52,
	})
	UI.text({
		Parent = brand,
		Text = Config.Name,
		Font = Theme.FontBlack,
		TextSize = 64,
		Size = UDim2.new(1, 0, 0, 72),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 52,
	})
	UI.text({
		Parent = brand,
		Text = Config.Tagline,
		TextColor3 = Theme.Accent2,
		TextSize = 18,
		Position = UDim2.fromOffset(0, 76),
		Size = UDim2.new(1, 0, 0, 28),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 52,
	})

	local status = UI.text({
		Parent = layer,
		Text = "Initializing...",
		TextColor3 = Theme.TextMuted,
		TextSize = 16,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.62, 0),
		Size = UDim2.fromOffset(360, 24),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 52,
	})

	local barBg = UI.create("Frame", {
		Parent = layer,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.66, 0),
		Size = UDim2.fromOffset(280, 8),
		BackgroundColor3 = Theme.Surface2,
		Corner = 4,
		BorderSizePixel = 0,
		ZIndex = 52,
	})
	local bar = UI.create("Frame", {
		Parent = barBg,
		Size = UDim2.fromScale(0.08, 1),
		BackgroundColor3 = Theme.Accent,
		Corner = 4,
		BorderSizePixel = 0,
		ZIndex = 53,
	})
	Theme.gradient(bar, Theme.Accent, Theme.Accent2, 0)

	Audio.Boot()

	local t0 = os.clock()
	local conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		for i, p in particles do
			local y = (p.Position.Y.Scale + 0.012 + i * 0.0002) % 1
			local x = (p.Position.X.Scale + math.sin(t + i) * 0.0008) % 1
			p.Position = UDim2.fromScale(x, y)
		end
	end)

	local handle = {}
	function handle.setStatus(text: string)
		status.Text = text
	end
	function handle.setProgress(p: number)
		Anim.Tween(bar, 0.2, { Size = UDim2.fromScale(math.clamp(p, 0.05, 1), 1) })
	end
	function handle.destroy()
		conn:Disconnect()
		Anim.Tween(layer, 0.28, { BackgroundTransparency = 1 })
		task.delay(0.3, function()
			layer:Destroy()
		end)
	end
	handle.layer = layer
	return handle
end

return BootPage
