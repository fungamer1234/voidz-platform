--!strict

local Config = require(script.Parent.Parent.Parent.Shared.Config)
local Theme = require(script.Parent.Parent.Theme)
local UI = require(script.Parent.Parent.UIKit)

local SettingsPage = {}

function SettingsPage.mount(parent: Instance, deps: any)
	local root = UI.scroll({
		Parent = parent,
		Name = "Settings",
		Size = UDim2.fromScale(1, 1),
		Pad = 4,
	})
	UI.list(root, 10)

	local function header(t: string)
		UI.text({
			Parent = root,
			Text = t,
			Font = Theme.FontBold,
			TextSize = 18,
			Size = UDim2.new(1, 0, 0, 28),
		})
	end

	local function refresh()
		for _, ch in root:GetChildren() do
			if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then
				ch:Destroy()
			end
		end
		local s = deps.getData().settings
		UI.text({
			Parent = root,
			Text = "Settings",
			Font = Theme.FontBlack,
			TextSize = 28,
			Size = UDim2.new(1, 0, 0, 32),
		})
		UI.text({
			Parent = root,
			Text = Config.Name .. "  v" .. Config.Version,
			TextColor3 = Theme.TextDim,
			Size = UDim2.new(1, 0, 0, 20),
		})

		header("General")
		UI.toggle(root, "Reduce motion", s.reduceMotion, function(v)
			deps.patchSettings({ reduceMotion = v })
		end)
		UI.toggle(root, "Notifications", s.notificationsEnabled, function(v)
			deps.patchSettings({ notificationsEnabled = v })
		end)
		UI.slider(root, "UI scale", (s.uiScale - 0.75) / 0.6, function(t)
			deps.patchSettings({ uiScale = 0.75 + t * 0.6 })
		end)

		header("Audio")
		UI.slider(root, "Master", s.masterVolume, function(t)
			deps.patchSettings({ masterVolume = t })
		end)
		UI.slider(root, "Music", s.musicVolume, function(t)
			deps.patchSettings({ musicVolume = t })
		end)
		UI.slider(root, "UI sounds", s.uiVolume, function(t)
			deps.patchSettings({ uiVolume = t })
		end)
		UI.slider(root, "Game sounds", s.gameVolume, function(t)
			deps.patchSettings({ gameVolume = t })
		end)

		header("Graphics")
		UI.toggle(root, "Effects", s.effects, function(v)
			deps.patchSettings({ effects = v })
		end)
		UI.toggle(root, "Particles", s.particles, function(v)
			deps.patchSettings({ particles = v })
		end)
		UI.toggle(root, "Performance mode", s.performanceMode, function(v)
			deps.patchSettings({ performanceMode = v })
		end)

		header("Gameplay")
		UI.toggle(root, "Camera shake", s.cameraShake, function(v)
			deps.patchSettings({ cameraShake = v })
		end)
		UI.toggle(root, "Shift lock preference", s.shiftLock, function(v)
			deps.patchSettings({ shiftLock = v })
		end)

		header("Accessibility")
		UI.toggle(root, "High contrast", s.highContrast, function(v)
			deps.patchSettings({ highContrast = v })
		end)
		UI.toggle(root, "Larger text", s.largeText, function(v)
			deps.patchSettings({ largeText = v })
		end)
		UI.toggle(root, "Color-blind friendly accents", s.colorblindFriendly, function(v)
			deps.patchSettings({ colorblindFriendly = v })
		end)

		header("Session")
		UI.text({
			Parent = root,
			Text = if deps.fallback() then "DataStores are unavailable. Progress is session-only until API access is enabled." else "Progress saves automatically and when you leave.",
			TextColor3 = Theme.TextMuted,
			TextWrapped = true,
			Size = UDim2.new(1, 0, 0, 40),
		})
		if deps.isDeveloper() then
			header("Developer")
			UI.button({
				Parent = root,
				Text = "Server stats",
				Ghost = true,
				Size = UDim2.fromOffset(160, 36),
				OnClick = function()
					deps.admin({ action = "stats" })
				end,
			})
		end
	end

	refresh()
	return {
		refresh = refresh,
		destroy = function()
			root:Destroy()
		end,
		root = root,
	}
end

return SettingsPage
