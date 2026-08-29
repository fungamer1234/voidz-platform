--!strict

local TweenService = game:GetService("TweenService")

local Anim = {}
Anim.ReduceMotion = false

local function info(t: number, style: Enum.EasingStyle?, dir: Enum.EasingDirection?): TweenInfo
	return TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
end

function Anim.Tween(inst: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?): Tween?
	if Anim.ReduceMotion then
		for k, v in props do
			(inst :: any)[k] = v
		end
		return nil
	end
	local tw = TweenService:Create(inst, info(t, style, dir), props)
	tw:Play()
	return tw
end

function Anim.FadeIn(gui: GuiObject, t: number?)
	gui.Visible = true
	if gui:IsA("Frame") or gui:IsA("TextButton") or gui:IsA("ImageButton") then
		gui.BackgroundTransparency = 1
		Anim.Tween(gui, t or 0.18, { BackgroundTransparency = gui:GetAttribute("BaseBg") or 0 })
	end
end

function Anim.Press(gui: GuiObject)
	local orig = gui.Size
	Anim.Tween(gui, 0.08, { Size = UDim2.new(orig.X.Scale, orig.X.Offset, orig.Y.Scale, orig.Y.Offset) })
end

function Anim.Info(t: number, style: Enum.EasingStyle?, dir: Enum.EasingDirection?): TweenInfo
	return info(t, style, dir)
end

return Anim
