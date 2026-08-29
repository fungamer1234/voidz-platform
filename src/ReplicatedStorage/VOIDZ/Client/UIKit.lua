--!strict

local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Theme)
local Anim = require(script.Parent.AnimationController)
local Audio = require(script.Parent.AudioController)

local UI = {}

function UI.create(className: string, props: { [string]: any }?): any
	local inst = Instance.new(className)
	props = props or {}
	local parent = props.Parent
	local corner = props.Corner
	local pad = props.Pad
	local stroke = props.Stroke
	local children = props.Children
	local grad = props.Gradient
	props.Parent = nil
	props.Corner = nil
	props.Pad = nil
	props.Stroke = nil
	props.Children = nil
	props.Gradient = nil
	for k, v in props do
		(inst :: any)[k] = v
	end
	if corner then
		Theme.corner(inst, if corner == true then Theme.Corner else corner)
	end
	if pad then
		if type(pad) == "number" then
			Theme.pad(inst, pad)
		else
			Theme.pad(inst, pad[1], pad[2], pad[3], pad[4])
		end
	end
	if stroke then
		if stroke == true then
			Theme.stroke(inst)
		else
			Theme.stroke(inst, stroke.Thickness, stroke.Transparency, stroke.Color)
		end
	end
	if grad then
		Theme.gradient(inst, grad[1], grad[2], grad[3])
	end
	if children then
		for _, ch in children do
			ch.Parent = inst
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

function UI.text(props: { [string]: any }): TextLabel
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.Font = props.Font or Theme.Font
	props.TextColor3 = props.TextColor3 or Theme.Text
	props.TextSize = props.TextSize or 16
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	props.TextTruncate = props.TextTruncate or Enum.TextTruncate.AtEnd
	props.BorderSizePixel = 0
	return UI.create("TextLabel", props)
end

function UI.button(props: { [string]: any }): TextButton
	local onClick = props.OnClick
	local ghost = props.Ghost
	local danger = props.Danger
	local accent = props.Accent
	props.OnClick = nil
	props.Ghost = nil
	props.Danger = nil
	props.Accent = nil
	local bg = Theme.Surface2
	local fg = Theme.Text
	if accent then
		bg = Theme.Accent
		fg = Theme.White
	elseif danger then
		bg = Theme.Danger
		fg = Theme.White
	elseif ghost then
		bg = Theme.Surface
		fg = Theme.Text
	end
	props.AutoButtonColor = false
	props.Text = props.Text or "OK"
	props.Font = props.Font or Theme.FontBold
	props.TextSize = props.TextSize or 16
	props.TextColor3 = props.TextColor3 or fg
	props.BackgroundColor3 = props.BackgroundColor3 or bg
	props.BorderSizePixel = 0
	props.Corner = props.Corner or Theme.CornerSm
	local btn = UI.create("TextButton", props) :: TextButton
	local base = btn.BackgroundColor3
	btn.MouseEnter:Connect(function()
		if UserInputService.MouseEnabled then
			Audio.Hover()
			Anim.Tween(btn, 0.12, { BackgroundColor3 = base:Lerp(Theme.White, 0.12) })
		end
	end)
	btn.MouseLeave:Connect(function()
		Anim.Tween(btn, 0.12, { BackgroundColor3 = base })
	end)
	btn.MouseButton1Down:Connect(function()
		Anim.Tween(btn, 0.08, { BackgroundColor3 = base:Lerp(Theme.Black, 0.12) })
	end)
	btn.MouseButton1Up:Connect(function()
		Anim.Tween(btn, 0.12, { BackgroundColor3 = base:Lerp(Theme.White, 0.12) })
	end)
	local last = 0
	btn.Activated:Connect(function()
		local now = os.clock()
		if now - last < 0.18 then
			return
		end
		last = now
		Audio.Click()
		if onClick then
			onClick()
		end
	end)
	return btn
end

function UI.iconButton(props: { [string]: any }): TextButton
	props.TextSize = props.TextSize or 20
	props.Font = Theme.FontBold
	props.Corner = props.Corner or 12
	return UI.button(props)
end

function UI.input(props: { [string]: any }): TextBox
	props.ClearTextOnFocus = props.ClearTextOnFocus == true
	props.Font = props.Font or Theme.Font
	props.TextSize = props.TextSize or 16
	props.TextColor3 = props.TextColor3 or Theme.Text
	props.PlaceholderColor3 = Theme.TextDim
	props.BackgroundColor3 = props.BackgroundColor3 or Theme.Surface2
	props.BorderSizePixel = 0
	props.Corner = props.Corner or Theme.CornerSm
	props.Stroke = props.Stroke == nil and true or props.Stroke
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	if not props.Pad then
		props.Pad = { 12, 0, 12, 0 }
	end
	return UI.create("TextBox", props)
end

function UI.scroll(props: { [string]: any }): ScrollingFrame
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.BorderSizePixel = 0
	props.ScrollBarThickness = props.ScrollBarThickness or 4
	props.ScrollBarImageColor3 = Theme.Stroke
	props.CanvasSize = props.CanvasSize or UDim2.new()
	props.AutomaticCanvasSize = props.AutomaticCanvasSize or Enum.AutomaticSize.Y
	props.ScrollingDirection = props.ScrollingDirection or Enum.ScrollingDirection.Y
	return UI.create("ScrollingFrame", props)
end

function UI.list(parent: Instance, pad: number?, dir: Enum.FillDirection?): UIListLayout
	local l = Instance.new("UIListLayout")
	l.FillDirection = dir or Enum.FillDirection.Vertical
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Padding = UDim.new(0, pad or 10)
	l.Parent = parent
	return l
end

function UI.grid(parent: Instance, cell: Vector2, pad: number?): UIGridLayout
	local g = Instance.new("UIGridLayout")
	g.CellSize = UDim2.fromOffset(cell.X, cell.Y)
	g.CellPadding = UDim2.fromOffset(pad or 12, pad or 12)
	g.SortOrder = Enum.SortOrder.LayoutOrder
	g.Parent = parent
	return g
end

function UI.aspect(parent: Instance, ratio: number)
	local a = Instance.new("UIAspectRatioConstraint")
	a.AspectRatio = ratio
	a.Parent = parent
	return a
end

function UI.badge(parent: Instance, text: string, color: Color3?): TextLabel
	return UI.text({
		Parent = parent,
		Text = text,
		Font = Theme.FontBold,
		TextSize = 12,
		TextColor3 = Theme.White,
		BackgroundColor3 = color or Theme.Accent,
		BackgroundTransparency = 0,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromOffset(88, 22),
		Corner = 8,
	})
end

function UI.empty(parent: Instance, title: string, body: string): Frame
	local f = UI.create("Frame", {
		Parent = parent,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 160),
	})
	UI.list(f, 8)
	UI.text({
		Parent = f,
		Size = UDim2.new(1, 0, 0, 28),
		Text = title,
		Font = Theme.FontBold,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	UI.text({
		Parent = f,
		Size = UDim2.new(1, 0, 0, 40),
		Text = body,
		TextColor3 = Theme.TextMuted,
		TextSize = 14,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	return f
end

function UI.divider(parent: Instance): Frame
	return UI.create("Frame", {
		Parent = parent,
		BackgroundColor3 = Theme.Stroke,
		BackgroundTransparency = 0.5,
		Size = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0,
	})
end

function UI.toggle(parent: Instance, label: string, value: boolean, onChange: (boolean) -> ()): Frame
	local row = UI.create("Frame", {
		Parent = parent,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 44),
	})
	UI.text({
		Parent = row,
		Text = label,
		Size = UDim2.new(1, -72, 1, 0),
		TextSize = 16,
	})
	local knobOn = value
	local track = UI.create("TextButton", {
		Parent = row,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromOffset(52, 28),
		Position = UDim2.new(1, -52, 0.5, -14),
		BackgroundColor3 = if knobOn then Theme.Accent else Theme.Surface3,
		Corner = 14,
		BorderSizePixel = 0,
	})
	local knob = UI.create("Frame", {
		Parent = track,
		Size = UDim2.fromOffset(22, 22),
		Position = if knobOn then UDim2.fromOffset(26, 3) else UDim2.fromOffset(4, 3),
		BackgroundColor3 = Theme.White,
		Corner = 11,
		BorderSizePixel = 0,
	})
	track.Activated:Connect(function()
		Audio.Click()
		knobOn = not knobOn
		Anim.Tween(track, 0.14, { BackgroundColor3 = if knobOn then Theme.Accent else Theme.Surface3 })
		Anim.Tween(knob, 0.14, { Position = if knobOn then UDim2.fromOffset(26, 3) else UDim2.fromOffset(4, 3) })
		onChange(knobOn)
	end)
	return row
end

function UI.slider(parent: Instance, label: string, value: number, onChange: (number) -> ()): Frame
	local row = UI.create("Frame", {
		Parent = parent,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 58),
	})
	local title = UI.text({
		Parent = row,
		Text = label,
		Size = UDim2.new(1, -48, 0, 22),
		TextSize = 16,
	})
	local val = UI.text({
		Parent = row,
		Text = tostring(math.floor(value * 100)),
		Size = UDim2.fromOffset(40, 22),
		Position = UDim2.new(1, -40, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = Theme.TextMuted,
	})
	local bar = UI.create("TextButton", {
		Parent = row,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, 10),
		Position = UDim2.fromOffset(0, 34),
		BackgroundColor3 = Theme.Surface3,
		Corner = 5,
		BorderSizePixel = 0,
	})
	local fill = UI.create("Frame", {
		Parent = bar,
		Size = UDim2.new(value, 0, 1, 0),
		BackgroundColor3 = Theme.Accent,
		Corner = 5,
		BorderSizePixel = 0,
	})
	local function setFromX(x: number)
		local abs = bar.AbsoluteSize.X
		if abs <= 0 then
			return
		end
		local t = math.clamp((x - bar.AbsolutePosition.X) / abs, 0, 1)
		fill.Size = UDim2.new(t, 0, 1, 0)
		val.Text = tostring(math.floor(t * 100))
		onChange(t)
	end
	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			setFromX(input.Position.X)
			local move, up
			move = UserInputService.InputChanged:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
					setFromX(i.Position.X)
				end
			end)
			up = UserInputService.InputEnded:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
					move:Disconnect()
					up:Disconnect()
				end
			end)
		end
	end)
	return row
end

return UI
