--!strict

local Theme = {}

Theme.Bg = Color3.fromRGB(9, 11, 16)
Theme.BgElev = Color3.fromRGB(14, 17, 26)
Theme.Surface = Color3.fromRGB(20, 24, 36)
Theme.Surface2 = Color3.fromRGB(28, 33, 48)
Theme.Surface3 = Color3.fromRGB(36, 42, 60)
Theme.Text = Color3.fromRGB(244, 246, 251)
Theme.TextMuted = Color3.fromRGB(139, 147, 167)
Theme.TextDim = Color3.fromRGB(92, 100, 122)
Theme.Accent = Color3.fromRGB(124, 92, 255)
Theme.Accent2 = Color3.fromRGB(46, 230, 166)
Theme.AccentDeep = Color3.fromRGB(72, 48, 190)
Theme.Danger = Color3.fromRGB(255, 77, 106)
Theme.Warning = Color3.fromRGB(255, 200, 87)
Theme.Stroke = Color3.fromRGB(58, 66, 90)
Theme.Good = Color3.fromRGB(46, 230, 166)
Theme.Online = Color3.fromRGB(46, 230, 166)
Theme.Offline = Color3.fromRGB(92, 100, 122)
Theme.White = Color3.new(1, 1, 1)
Theme.Black = Color3.new(0, 0, 0)

Theme.Font = Enum.Font.Gotham
Theme.FontMed = Enum.Font.GothamMedium
Theme.FontBold = Enum.Font.GothamBold
Theme.FontBlack = Enum.Font.GothamBlack

local okBuilder, builder = pcall(function()
	return (Enum.Font :: any).BuilderSans
end)
if okBuilder and builder then
	Theme.Font = builder
	local okMed = pcall(function()
		Theme.FontMed = (Enum.Font :: any).BuilderSansMedium
	end)
	local okBold = pcall(function()
		Theme.FontBold = (Enum.Font :: any).BuilderSansBold
	end)
	local okBlack = pcall(function()
		Theme.FontBlack = (Enum.Font :: any).BuilderSansExtraBold
	end)
	if not okMed then
		Theme.FontMed = Theme.Font
	end
	if not okBold then
		Theme.FontBold = Enum.Font.GothamBold
	end
	if not okBlack then
		Theme.FontBlack = Enum.Font.GothamBlack
	end
end

Theme.Corner = 14
Theme.CornerSm = 10
Theme.CornerLg = 20
Theme.Pad = 16
Theme.TopBar = 64
Theme.NavWidth = 88
Theme.NavHeightMobile = 72

Theme.Rarity = {
	Common = Color3.fromRGB(160, 170, 188),
	Rare = Color3.fromRGB(80, 168, 255),
	Epic = Color3.fromRGB(188, 108, 255),
	Legendary = Color3.fromRGB(255, 184, 72),
}

function Theme.stroke(parent: Instance, thickness: number?, trans: number?, color: Color3?)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 1
	s.Transparency = trans or 0.55
	s.Color = color or Theme.Stroke
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

function Theme.corner(parent: Instance, px: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, px or Theme.Corner)
	c.Parent = parent
	return c
end

function Theme.pad(parent: Instance, l: number?, t: number?, r: number?, b: number?)
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, l or 12)
	p.PaddingTop = UDim.new(0, t or l or 12)
	p.PaddingRight = UDim.new(0, r or l or 12)
	p.PaddingBottom = UDim.new(0, b or t or l or 12)
	p.Parent = parent
	return p
end

function Theme.gradient(parent: Instance, a: Color3, b: Color3, rot: number?)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(a, b)
	g.Rotation = rot or 90
	g.Parent = parent
	return g
end

return Theme
