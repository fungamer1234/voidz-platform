--!strict

local UserInputService = game:GetService("UserInputService")
local AvatarCatalog = require(script.Parent.Parent.Parent.Shared.AvatarCatalog)
local Constants = require(script.Parent.Parent.Parent.Shared.Constants)
local Config = require(script.Parent.Parent.Parent.Shared.Config)
local Theme = require(script.Parent.Parent.Theme)
local UI = require(script.Parent.Parent.UIKit)
local ViewportAvatar = require(script.Parent.Parent.ViewportAvatar)
local Utility = require(script.Parent.Parent.Parent.Shared.Utility)

local AvatarPage = {}

function AvatarPage.mount(parent: Instance, deps: any)
	local root = UI.create("Frame", {
		Parent = parent,
		Name = "Avatar",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	})

	local data0 = deps.getData()
	local equipped = Utility.deepCopy(data0.inventory.equipped)
	local skinTone = Utility.deepCopy(data0.avatar.skinTone)
	local slot = "hair"
	local yaw = 20
	local vp

	UI.text({
		Parent = root,
		Text = "Avatar",
		Font = Theme.FontBlack,
		TextSize = 28,
		Size = UDim2.new(1, 0, 0, 32),
	})

	local preview = UI.create("Frame", {
		Parent = root,
		Position = UDim2.fromOffset(0, 44),
		Size = UDim2.new(0.38, -8, 1, -100),
		BackgroundColor3 = Theme.Surface,
		Corner = 18,
		Stroke = true,
	})
	vp = ViewportAvatar.Attach(preview, equipped, skinTone)

	local rot = UI.create("Frame", {
		Parent = preview,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 3,
	})
	local dragging = false
	local lastX = 0
	local conns = {}
	table.insert(conns, rot.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			lastX = i.Position.X
		end
	end))
	table.insert(conns, UserInputService.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			yaw += (i.Position.X - lastX) * 0.5
			lastX = i.Position.X
			vp.setYaw(yaw)
		end
	end))
	table.insert(conns, UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))

	local zoomRow = UI.create("Frame", {
		Parent = preview,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 8, 1, -44),
		Size = UDim2.new(1, -16, 0, 36),
		ZIndex = 4,
	})
	UI.button({
		Parent = zoomRow,
		Text = "Reset view",
		Ghost = true,
		Size = UDim2.fromOffset(110, 32),
		TextSize = 13,
		OnClick = function()
			yaw = 20
			vp.setYaw(yaw)
		end,
	})

	local slots = UI.scroll({
		Parent = root,
		Position = UDim2.new(0.38, 8, 0, 44),
		Size = UDim2.new(0.62, -8, 0, 52),
		ScrollingDirection = Enum.ScrollingDirection.X,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
	})
	UI.list(slots, 8, Enum.FillDirection.Horizontal)

	local items = UI.scroll({
		Parent = root,
		Position = UDim2.new(0.38, 8, 0, 104),
		Size = UDim2.new(0.62, -8, 1, -160),
	})
	UI.grid(items, Vector2.new(150, 96), 10)

	local function owned(id: string): boolean
		local rec = deps.getData().inventory.items[id]
		return rec ~= nil
	end

	local paintItems
	local function paintSlots()
		for _, ch in slots:GetChildren() do
			if ch:IsA("GuiButton") then
				ch:Destroy()
			end
		end
		for _, s in Constants.SLOTS do
			UI.button({
				Parent = slots,
				Text = Constants.SLOT_LABELS[s],
				Accent = slot == s,
				Ghost = slot ~= s,
				Size = UDim2.fromOffset(108, 36),
				TextSize = 13,
				OnClick = function()
					slot = s
					paintSlots()
					paintItems()
				end,
			})
		end
	end

	paintItems = function()
		for _, ch in items:GetChildren() do
			if ch:IsA("GuiButton") or ch:IsA("TextLabel") then
				ch:Destroy()
			end
		end
		for _, it in AvatarCatalog.GetSlot(slot) do
			local has = owned(it.Id)
			local eq = equipped[slot] == it.Id
			local btn = UI.create("TextButton", {
				Parent = items,
				Text = "",
				AutoButtonColor = false,
				BackgroundColor3 = if eq then Theme.AccentDeep else Theme.Surface2,
				Size = UDim2.fromOffset(150, 96),
				Corner = 12,
				Stroke = true,
				BorderSizePixel = 0,
			})
			UI.text({
				Parent = btn,
				Text = it.Name,
				Font = Theme.FontBold,
				TextSize = 14,
				Position = UDim2.fromOffset(8, 8),
				Size = UDim2.new(1, -16, 0, 20),
			})
			UI.text({
				Parent = btn,
				Text = if not has then it.Price .. " VC" elseif eq then "Equipped" else it.Rarity,
				TextColor3 = if has then AvatarCatalog.RarityColor(it.Rarity) else Theme.Warning,
				TextSize = 12,
				Position = UDim2.fromOffset(8, 32),
				Size = UDim2.new(1, -16, 0, 18),
			})
			btn.Activated:Connect(function()
				if not has then
					deps.toast("Buy this in Inventory → Shop.")
					return
				end
				equipped[slot] = it.Id
				if slot == "skin" then
					skinTone = { it.Color[1], it.Color[2], it.Color[3] }
				end
				vp.set(equipped, skinTone)
				paintItems()
			end)
		end
	end

	local actions = UI.create("Frame", {
		Parent = root,
		Position = UDim2.new(0.38, 8, 1, -48),
		Size = UDim2.new(0.62, -8, 0, 44),
		BackgroundTransparency = 1,
	})
	UI.list(actions, 10, Enum.FillDirection.Horizontal)
	UI.button({
		Parent = actions,
		Text = "Save",
		Accent = true,
		Size = UDim2.fromOffset(120, 40),
		OnClick = function()
			deps.saveAvatar({ equipped = equipped, skinTone = skinTone })
		end,
	})
	UI.button({
		Parent = actions,
		Text = "Reset",
		Ghost = true,
		Size = UDim2.fromOffset(120, 40),
		OnClick = function()
			deps.resetAvatar()
		end,
	})
	UI.button({
		Parent = actions,
		Text = "Unequip slot",
		Ghost = true,
		Size = UDim2.fromOffset(140, 40),
		OnClick = function()
			local fallback = Config.DefaultEquipped[slot]
			if type(fallback) == "string" then
				equipped[slot] = fallback
				vp.set(equipped, skinTone)
				paintItems()
			end
		end,
	})

	paintSlots()
	paintItems()

	return {
		refresh = function()
			local d = deps.getData()
			equipped = Utility.deepCopy(d.inventory.equipped)
			skinTone = Utility.deepCopy(d.avatar.skinTone)
			vp.set(equipped, skinTone)
			paintItems()
		end,
		destroy = function()
			for _, c in conns do
				c:Disconnect()
			end
			vp.destroy()
			root:Destroy()
		end,
		root = root,
	}
end

return AvatarPage
