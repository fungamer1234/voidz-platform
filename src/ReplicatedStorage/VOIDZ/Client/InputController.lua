--!strict

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local InputController = {}

function InputController.IsMobile(viewport: Vector2): boolean
	if viewport.X <= 720 then
		return true
	end
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and viewport.X < 1100
end

function InputController.Bind(opts: {
	onBack: () -> (),
	onToggleLobby: () -> (),
	onSearch: () -> (),
})
	local function back(_name, state)
		if state == Enum.UserInputState.Begin then
			opts.onBack()
		end
		return Enum.ContextActionResult.Sink
	end
	ContextActionService:BindAction("VOIDZ_Back", back, false, Enum.KeyCode.Escape, Enum.KeyCode.ButtonB)
	ContextActionService:BindAction("VOIDZ_Lobby", function(_n, state)
		if state == Enum.UserInputState.Begin then
			opts.onToggleLobby()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.F1)
	ContextActionService:BindAction("VOIDZ_Search", function(_n, state)
		if state == Enum.UserInputState.Begin then
			opts.onSearch()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.Slash)

	if UserInputService.GamepadEnabled then
		GuiService.AutoSelectGuiEnabled = true
	end
end

function InputController.Unbind()
	ContextActionService:UnbindAction("VOIDZ_Back")
	ContextActionService:UnbindAction("VOIDZ_Lobby")
	ContextActionService:UnbindAction("VOIDZ_Search")
end

return InputController
