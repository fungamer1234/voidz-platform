--!strict

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local Shared = script.Parent.Parent.Shared
local Config = require(Shared.Config)
local Constants = require(Shared.Constants)
local GameRegistry = require(Shared.GameRegistry)
local Utility = require(Shared.Utility)

local UI = require(script.Parent.UIKit)
local Net = require(script.Parent.Net)
local Audio = require(script.Parent.AudioController)
local Anim = require(script.Parent.AnimationController)
local InputController = require(script.Parent.InputController)
local Chrome = require(script.Parent.Chrome)
local Navigation = require(script.Parent.NavigationController)

local BootPage = require(script.Parent.Pages.BootPage)
local ErrorPage = require(script.Parent.Pages.ErrorPage)
local OnboardingPage = require(script.Parent.Pages.OnboardingPage)
local HomePage = require(script.Parent.Pages.HomePage)
local DiscoverPage = require(script.Parent.Pages.DiscoverPage)
local GamePage = require(script.Parent.Pages.GamePage)
local AvatarPage = require(script.Parent.Pages.AvatarPage)
local InventoryPage = require(script.Parent.Pages.InventoryPage)
local FriendsPage = require(script.Parent.Pages.FriendsPage)
local ProfilePage = require(script.Parent.Pages.ProfilePage)
local SettingsPage = require(script.Parent.Pages.SettingsPage)
local SearchPage = require(script.Parent.Pages.SearchPage)
local MatchClient = require(script.Parent.GameRuntime.MatchClient)

local App = {}

local player = Players.LocalPlayer
local playerGui: PlayerGui
local gui: ScreenGui
local peekGui: ScreenGui
local chrome
local boot
local contentHost: Frame
local history: { string } = {}
local currentPage = "Home"
local gameId: string? = nil
local searchQuery = ""
local playerResults: { any } = {}
local notifOpen = false
local discoverCategory = "All"
local cache: { [string]: any } = {}
local session = {
	data = nil :: any,
	live = {} :: any,
	fallback = false,
	isDeveloper = false,
	robloxName = "",
	userId = 0,
	announcement = nil :: any,
}

local lobbyHidden = false
local charBound = false

local function setHubMovement(locked: boolean)
	local char = player.Character
	if not char then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	if locked then
		hum.WalkSpeed = 0
		pcall(function()
			hum.JumpPower = 0
			hum.JumpHeight = 0
		end)
	else
		hum.WalkSpeed = 16
		pcall(function()
			hum.JumpPower = 50
			hum.JumpHeight = 7.2
		end)
	end
end

local function unread(): number
	local n = 0
	if session.data then
		for _, it in session.data.notifications or {} do
			if not it.read then
				n += 1
			end
		end
	end
	return n
end

local function applyGraphics()
	if not session.data then
		return
	end
	local s = session.data.settings
	Anim.ReduceMotion = s.reduceMotion == true
	Audio.ApplySettings(s)
	local scale = s.uiScale or 1
	if s.largeText then
		scale += 0.08
	end
	local uiScale = gui:FindFirstChildOfClass("UIScale")
	if uiScale then
		local cam = workspace.CurrentCamera
		local vs = if cam then cam.ViewportSize else Vector2.new(1280, 720)
		local base = math.clamp(vs.Y / 900, 0.72, 1.2)
		uiScale.Scale = base * scale
	end
	local bloom = Lighting:FindFirstChild("VOIDZ_Bloom")
	local dof = Lighting:FindFirstChild("VOIDZ_DoF")
	local perf = s.performanceMode == true or s.effects == false
	if bloom and bloom:IsA("BloomEffect") then
		bloom.Enabled = not perf
	end
	if dof and dof:IsA("DepthOfFieldEffect") then
		dof.Enabled = not perf
	end
	for _, inst in CollectionService:GetTagged("VOIDZGamePad") do
		-- no-op
	end
	if s.particles == false then
		for _, d in workspace:GetDescendants() do
			if d:IsA("ParticleEmitter") then
				d.Enabled = false
			end
		end
	end
	if s.highContrast then
		local cc = Lighting:FindFirstChild("VOIDZ_CC")
		if cc and cc:IsA("ColorCorrectionEffect") then
			cc.Contrast = 0.22
			cc.Saturation = 0.2
		end
	end
	if s.shiftLock then
		pcall(function()
			player.DevEnableMouseLock = true
		end)
	end
end

local function isMobile(): boolean
	local cam = workspace.CurrentCamera
	local vs = if cam then cam.ViewportSize else Vector2.new(1280, 720)
	return InputController.IsMobile(vs)
end

local refreshCurrent

local function depsFor(page: string): any
	return {
		getData = function()
			return session.data
		end,
		getLive = function()
			return session.live
		end,
		robloxName = function()
			return session.robloxName
		end,
		lobbyPlayers = function()
			return session.live and session.live._lobbyPlayers or #Players:GetPlayers()
		end,
		fallback = function()
			return session.fallback
		end,
		isDeveloper = function()
			return session.isDeveloper
		end,
		gameId = gameId,
		getQuery = function()
			return searchQuery
		end,
		getPlayerResults = function()
			return playerResults
		end,
		initialCategory = discoverCategory,
		openPage = function(name: string)
			App.open(name)
		end,
		openGame = function(id: string)
			App.openGame(id)
		end,
		openDiscover = function(cat: string)
			discoverCategory = cat or "All"
			App.open("Discover")
			if cache.Discover and cache.Discover.setCategory then
				cache.Discover.setCategory(discoverCategory)
			end
		end,
		playGame = function(id: string)
			App.play(id)
		end,
		toggleFavorite = function(id: string)
			App.toggleFavorite(id)
		end,
		toggleLike = function(id: string)
			App.toggleLike(id)
		end,
		saveAvatar = function(payload: any)
			App.saveAvatar(payload)
		end,
		resetAvatar = function()
			App.resetAvatar()
		end,
		purchase = function(id: string)
			App.purchase(id)
		end,
		equip = function(id: string)
			App.equip(id)
		end,
		unequip = function(slot: string)
			App.unequip(slot)
		end,
		setDisplayName = function(name: string)
			App.setDisplayName(name)
		end,
		patchSettings = function(patch: any)
			App.patchSettings(patch)
		end,
		toast = function(msg: string)
			if chrome then
				chrome.toast("VOIDZ", msg)
			end
		end,
		loadFriends = function()
			return Net.Invoke("GetFriends")
		end,
		friendRequest = function(id: number)
			local res = Net.Invoke("FriendRequest", id)
			if chrome then
				chrome.toast(if res.ok then "Request sent" else "Couldn't add", res.error or "Pending.")
			end
			if cache.Friends then
				cache.Friends.refresh()
			end
		end,
		friendRespond = function(id: number, acc: boolean)
			local res = Net.Invoke("FriendRespond", id, acc)
			if cache.Friends then
				cache.Friends.apply(res)
			end
		end,
		removeFriend = function(id: number)
			local res = Net.Invoke("RemoveFriend", id)
			if cache.Friends then
				cache.Friends.apply(res)
			end
		end,
		searchPlayers = function(q: string)
			local res = Net.Invoke("SearchPlayers", q)
			if cache.Friends and res then
				cache.Friends.apply(res)
			end
		end,
		viewProfile = function(userId: number)
			local res = Net.Invoke("GetPublicProfile", userId)
			if res and res.ok and chrome then
				local p = res.profile
				chrome.toast(p.displayName, "@" .. p.robloxName .. " · " .. Utility.formatNumber(p.currency) .. " VC")
			elseif chrome then
				chrome.toast("Profile", (res and res.error) or "Unavailable")
			end
		end,
		admin = function(cmd: any)
			local res = Net.Invoke("AdminCommand", cmd)
			if chrome then
				chrome.toast("Admin", if res.ok then "OK" else (res.error or "Failed"))
			end
		end,
		claimDaily = function()
			local res = Net.Invoke("ClaimDaily")
			if chrome then
				if res and res.ok then
					chrome.toast("Daily drop", "+" .. tostring(res.amount) .. " VC · streak " .. tostring(res.streak))
				else
					chrome.toast("Daily", (res and res.error) or "Not yet.")
				end
			end
		end,
		partyInvite = function(userId: number)
			local res = Net.Invoke("PartyInvite", userId)
			if chrome then
				chrome.toast("Party", if res.ok then "Invite sent" else (res.error or "Failed"))
			end
		end,
		partyRespond = function(accept: boolean)
			Net.Invoke("PartyRespond", accept)
		end,
		getQuests = function()
			return Net.Invoke("GetQuests")
		end,
		getLeaderboard = function(id: string)
			return Net.Invoke("GetLeaderboard", id)
		end,
	}
end

local factories = {
	Home = HomePage,
	Discover = DiscoverPage,
	Game = GamePage,
	Avatar = AvatarPage,
	Inventory = InventoryPage,
	Friends = FriendsPage,
	Profile = ProfilePage,
	Settings = SettingsPage,
	Search = SearchPage,
}

refreshCurrent = function()
	if cache[currentPage] and cache[currentPage].refresh then
		cache[currentPage].refresh()
	end
	if chrome and session.data then
		chrome.setCoins(session.data.currency.VoidCoins or 0)
		chrome.setUnread(unread())
		chrome.paintNotifs(session.data.notifications or {})
		chrome.setActive(currentPage)
	end
	applyGraphics()
end

function App.open(name: string, skipHistory: boolean?)
	if not contentHost or not session.data then
		return
	end
	if not skipHistory and currentPage and currentPage ~= name then
		table.insert(history, currentPage)
		while #history > 16 do
			table.remove(history, 1)
		end
	end
	for pageName, ctrl in cache do
		if ctrl.root then
			ctrl.root.Visible = false
		end
	end
	currentPage = name
	if not cache[name] then
		local fac = factories[name]
		if not fac then
			return
		end
		cache[name] = fac.mount(contentHost, depsFor(name))
	else
		if cache[name].refresh then
			cache[name].refresh()
		end
		if name == "Discover" and cache[name].setCategory then
			cache[name].setCategory(discoverCategory)
		end
	end
	if cache[name].root then
		cache[name].root.Visible = true
	end
	if chrome then
		chrome.setActive(name)
	end
end

function App.back()
	if notifOpen then
		notifOpen = false
		if chrome then
			chrome.setPanel(false)
		end
		return
	end
	if currentPage == "Game" or currentPage == "Search" then
		App.open("Discover")
		return
	end
	local prev = table.remove(history)
	if prev then
		App.open(prev, true)
	else
		App.open("Home", true)
	end
end

function App.openGame(id: string)
	if not GameRegistry.Get(id) then
		if chrome then
			chrome.toast("Missing", "That game isn't registered.")
		end
		return
	end
	gameId = id
	if cache.Game then
		cache.Game.destroy()
		cache.Game = nil
	end
	App.open("Game")
end

function App.play(id: string)
	local res = Net.Invoke("PlayGame", id)
	if res and res.ok then
		if res.inPlace then
			return
		end
		if chrome then
			chrome.toast("Launching", "Taking you in...")
		end
		return
	end
	if res and res.comingSoon then
		if chrome then
			chrome.toast("Coming Soon", (res.name or "This game") .. " isn't open yet.")
		end
		refreshCurrent()
		return
	end
	if chrome then
		chrome.toast("Couldn't play", (res and res.error) or Constants.ERRORS.COMING_SOON)
	end
	Audio.Error()
end

function App.toggleFavorite(id: string)
	local res = Net.Invoke("ToggleFavorite", id)
	if res and res.ok then
		session.data.favorites = res.favorites
		if res.live then
			session.live = res.live
		end
		refreshCurrent()
	end
end

function App.toggleLike(id: string)
	local res = Net.Invoke("ToggleLike", id)
	if res and res.ok then
		session.data.likes = res.likes
		if res.live then
			session.live = res.live
		end
		refreshCurrent()
	end
end

function App.saveAvatar(payload: any)
	local res = Net.Invoke("SaveAvatar", payload)
	if res and res.ok then
		session.data.inventory.equipped = res.equipped
		session.data.avatar = res.avatar
		if chrome then
			chrome.toast("Avatar saved", "Your look is stored on this profile.")
		end
		Audio.Success()
		refreshCurrent()
	else
		if chrome then
			chrome.toast("Save failed", (res and res.error) or "")
		end
		Audio.Error()
	end
end

function App.resetAvatar()
	local res = Net.Invoke("ResetAvatar")
	if res and res.ok then
		session.data.inventory.equipped = res.equipped
		session.data.avatar = res.avatar
		refreshCurrent()
	end
end

function App.purchase(id: string)
	local res = Net.Invoke("PurchaseItem", id)
	if res and res.ok then
		session.data.inventory = res.inventory
		session.data.currency = res.currency
		Audio.Reward()
		if chrome then
			chrome.toast("Purchased", "Added to your inventory.")
		end
		refreshCurrent()
	else
		Audio.Error()
		if chrome then
			chrome.toast("Purchase failed", (res and res.error) or "")
		end
	end
end

function App.equip(id: string)
	local res = Net.Invoke("EquipItem", id)
	if res and res.ok then
		session.data.inventory.equipped = res.equipped
		if res.avatar then
			session.data.avatar = res.avatar
		end
		refreshCurrent()
	else
		if chrome then
			chrome.toast("Can't equip", (res and res.error) or "")
		end
	end
end

function App.unequip(slot: string)
	local res = Net.Invoke("UnequipItem", slot)
	if res and res.ok then
		session.data.inventory.equipped = res.equipped
		refreshCurrent()
	end
end

function App.setDisplayName(name: string)
	local res = Net.Invoke("SetDisplayName", name)
	if res and res.ok then
		session.data.profile.displayName = res.displayName
		if chrome then
			chrome.toast("Name updated", res.displayName)
		end
		refreshCurrent()
	else
		if chrome then
			chrome.toast("Name rejected", (res and res.error) or "")
		end
		Audio.Error()
	end
end

local settingsDirtyAt = 0
function App.patchSettings(patch: any)
	if not session.data then
		return
	end
	for k, v in patch do
		session.data.settings[k] = v
	end
	applyGraphics()
	settingsDirtyAt = os.clock()
	local stamp = settingsDirtyAt
	task.delay(0.35, function()
		if stamp ~= settingsDirtyAt then
			return
		end
		local res = Net.Invoke("SaveSettings", session.data.settings)
		if res and res.ok then
			session.data.settings = res.settings
		end
	end)
	if cache.Settings then
		-- don't full remount sliders while dragging
	end
end

local function mergeData(data: any)
	if type(data) ~= "table" then
		return
	end
	session.data = data
	refreshCurrent()
end

local function showMain()
	if boot then
		boot.destroy()
		boot = nil
	end
	if not chrome then
		chrome = Chrome.mount(gui, {
			isMobile = isMobile,
			openPage = function(name: string)
				App.open(name)
			end,
			onSearch = function(text: string)
				searchQuery = text
				if text == "" then
					if currentPage == "Search" then
						App.open("Home")
					end
					return
				end
				task.spawn(function()
					local res = Net.Invoke("SearchPlayers", text)
					playerResults = if res and res.ok then (res.results or {}) else {}
					if currentPage == "Search" and cache.Search then
						cache.Search.refresh()
					end
				end)
				if cache.Search then
					cache.Search.destroy()
					cache.Search = nil
				end
				App.open("Search")
			end,
			toggleNotifs = function()
				notifOpen = not notifOpen
				chrome.setPanel(notifOpen)
				if notifOpen then
					Net.Invoke("MarkNotificationsRead", nil)
					if session.data then
						for _, n in session.data.notifications or {} do
							n.read = true
						end
						chrome.setUnread(0)
					end
				end
			end,
			clearNotifs = function()
				local res = Net.Invoke("ClearNotifications")
				if res and res.ok then
					session.data.notifications = {}
					chrome.paintNotifs({})
					chrome.setUnread(0)
				end
			end,
			markRead = function(id: string)
				Net.Invoke("MarkNotificationsRead", id)
			end,
			toggleLobby = function()
				App.toggleLobby()
			end,
		})
		contentHost = chrome.content
	end
	chrome.show()
	chrome.announce(session.announcement)
	chrome.setCoins(session.data.currency.VoidCoins or 0)
	chrome.setUnread(unread())
	chrome.paintNotifs(session.data.notifications or {})
	App.open("Home", true)
	applyGraphics()
	Audio.StartMusic()
	setHubMovement(true)
	if not charBound then
		charBound = true
		player.CharacterAdded:Connect(function()
			task.wait(0.15)
			if not lobbyHidden then
				setHubMovement(true)
			end
		end)
	end
end

function App.toggleLobby()
	lobbyHidden = not lobbyHidden
	gui.Enabled = not lobbyHidden
	peekGui.Enabled = lobbyHidden
	setHubMovement(not lobbyHidden)
end

local function bindPrompts()
	local function hook(inst: Instance)
		local prompt = inst:FindFirstChildOfClass("ProximityPrompt")
		if not prompt then
			return
		end
		prompt.Triggered:Connect(function()
			local id = inst:GetAttribute("GameId")
			if type(id) == "string" then
				if lobbyHidden then
					App.toggleLobby()
				end
				App.openGame(id)
			end
		end)
	end
	for _, inst in CollectionService:GetTagged("VOIDZGamePad") do
		hook(inst)
	end
	CollectionService:GetInstanceAddedSignal("VOIDZGamePad"):Connect(hook)
	for _, inst in CollectionService:GetTagged("VOIDZAvatarPad") do
		local prompt = inst:FindFirstChildOfClass("ProximityPrompt")
		if not prompt then
			prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Customize"
			prompt.ObjectText = "Avatar"
			prompt.HoldDuration = 0
			prompt.Parent = inst
		end
		prompt.Triggered:Connect(function()
			if lobbyHidden then
				App.toggleLobby()
			end
			App.open("Avatar")
		end)
	end
end

local function applySession(pkg: any): boolean
	if not pkg or not pkg.ok then
		return false
	end
	session.data = pkg.data
	session.live = pkg.live or {}
	session.fallback = pkg.fallback == true
	session.isDeveloper = pkg.isDeveloper == true
	session.robloxName = pkg.robloxName or player.Name
	session.userId = pkg.userId or player.UserId
	session.announcement = pkg.announcement
	return true
end

local function startSession()
	if boot then
		boot.setStatus("Loading profile...")
		boot.setProgress(0.35)
	end
	local pkg = Net.Invoke("GetSession")
	if not pkg or not pkg.ok then
		if boot then
			boot.destroy()
			boot = nil
		end
		ErrorPage.create(gui, (pkg and pkg.error) or Constants.ERRORS.LOAD_FAILED, function()
			for _, ch in gui:GetChildren() do
				if ch.Name == "Error" then
					ch:Destroy()
				end
			end
			boot = BootPage.create(gui)
			task.spawn(startSession)
		end)
		return
	end
	if boot then
		boot.setStatus("Preparing avatar...")
		boot.setProgress(0.7)
	end
	applySession(pkg)
	if boot then
		boot.setStatus("Loading games...")
		boot.setProgress(0.85)
		task.wait()
		boot.setStatus("Almost ready...")
		boot.setProgress(1)
	end
	if pkg.isNew then
		if boot then
			boot.destroy()
			boot = nil
		end
		OnboardingPage.create(gui, session.robloxName, function(name, avatar)
			local res = Net.Invoke("CompleteOnboarding", name, avatar)
			if not res or not res.ok then
				return (res and res.error) or "Try another name."
			end
			applySession(res)
			session.live = res.live or session.live
			for _, ch in gui:GetChildren() do
				if ch.Name == "Onboarding" then
					ch:Destroy()
				end
			end
			showMain()
			return nil
		end)
		return
	end
	showMain()
end

function App.start()
	playerGui = player:WaitForChild("PlayerGui") :: PlayerGui
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
	end)
	Audio.Init()
	MatchClient.start()
	Navigation.Bind(function(name: string)
		App.open(name)
	end, function()
		App.back()
	end)

	gui = Instance.new("ScreenGui")
	gui.Name = "VOIDZ"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 100
	gui.Parent = playerGui
	local scale = Instance.new("UIScale")
	scale.Parent = gui

	peekGui = Instance.new("ScreenGui")
	peekGui.Name = "VOIDZ_Peek"
	peekGui.IgnoreGuiInset = true
	peekGui.ResetOnSpawn = false
	peekGui.Enabled = false
	peekGui.DisplayOrder = 120
	peekGui.Parent = playerGui
	local openBtn = UI.button({
		Parent = peekGui,
		Text = "Open VOIDZ",
		Accent = true,
		Size = UDim2.fromOffset(160, 44),
		Position = UDim2.new(0.5, -80, 0, 16),
		OnClick = function()
			App.toggleLobby()
		end,
	})

	boot = BootPage.create(gui)
	boot.setStatus("Initializing...")
	boot.setProgress(0.12)

	InputController.Bind({
		onBack = function()
			App.back()
		end,
		onToggleLobby = function()
			App.toggleLobby()
		end,
		onSearch = function()
			if chrome then
				chrome.focusSearch()
			end
		end,
	})

	Net.Event("DataUpdate").OnClientEvent:Connect(function(data)
		mergeData(data)
	end)
	Net.Event("Notification").OnClientEvent:Connect(function(n)
		if session.data then
			session.data.notifications = session.data.notifications or {}
			table.insert(session.data.notifications, 1, n)
		end
		Audio.Notify()
		if chrome then
			if session.data and session.data.settings.notificationsEnabled ~= false then
				chrome.toast(n.title, n.body)
			end
			chrome.setUnread(unread())
			chrome.paintNotifs(session.data.notifications or {})
		end
	end)
	Net.Event("CurrencyDelta").OnClientEvent:Connect(function(payload)
		if session.data and payload then
			session.data.currency.VoidCoins = payload.balance
			if chrome then
				chrome.setCoins(payload.balance)
				if payload.amount > 0 then
					chrome.toast("+" .. payload.amount .. " VC", payload.reason or Config.CurrencyName)
				end
			end
		end
	end)
	Net.Event("Announcement").OnClientEvent:Connect(function(payload)
		session.announcement = payload and payload.text
		if chrome then
			chrome.announce(session.announcement)
		end
	end)
	Net.Event("SoftError").OnClientEvent:Connect(function(payload)
		ErrorPage.create(gui, (payload and payload.error) or Constants.ERRORS.LOAD_FAILED, function()
			for _, ch in gui:GetChildren() do
				if ch.Name == "Error" then
					ch:Destroy()
				end
			end
			startSession()
		end)
	end)

	bindPrompts()
	task.spawn(startSession)

	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() end)
	local cam = workspace.CurrentCamera
	if cam then
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			applyGraphics()
		end)
	end
end

return App
