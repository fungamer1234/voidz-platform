--!strict

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VOIDZ = ReplicatedStorage:WaitForChild("VOIDZ")
local Config = require(VOIDZ.Shared.Config)

local Audio = {}

local groups: { [string]: SoundGroup } = {}
local cache: { [string]: Sound } = {}
local settings = {
	masterVolume = Config.DefaultSettings.masterVolume,
	musicVolume = Config.DefaultSettings.musicVolume,
	uiVolume = Config.DefaultSettings.uiVolume,
	gameVolume = Config.DefaultSettings.gameVolume,
}
local music: Sound? = nil
local hoverGate = 0

local function group(name: string): SoundGroup
	local g = groups[name]
	if g then
		return g
	end
	g = Instance.new("SoundGroup")
	g.Name = "VOIDZ_" .. name
	g.Parent = SoundService
	groups[name] = g
	return g
end

local function apply()
	local m = settings.masterVolume
	group("ui").Volume = m * settings.uiVolume
	group("music").Volume = m * settings.musicVolume
	group("game").Volume = m * settings.gameVolume
end

function Audio.Init()
	apply()
	for name, id in Config.Sounds do
		if name ~= "Music" and type(id) == "string" and id ~= "" then
			local s = Instance.new("Sound")
			s.Name = name
			s.SoundId = id
			s.SoundGroup = group("ui")
			s.Volume = 0.6
			s.Parent = SoundService
			cache[name] = s
		end
	end
	if Config.Sounds.Music ~= "" then
		music = Instance.new("Sound")
		music.Name = "VOIDZ_Music"
		music.SoundId = Config.Sounds.Music
		music.Looped = true
		music.Volume = 0.4
		music.SoundGroup = group("music")
		music.Parent = SoundService
	end
end

function Audio.ApplySettings(s: any)
	if type(s) ~= "table" then
		return
	end
	if type(s.masterVolume) == "number" then
		settings.masterVolume = s.masterVolume
	end
	if type(s.musicVolume) == "number" then
		settings.musicVolume = s.musicVolume
	end
	if type(s.uiVolume) == "number" then
		settings.uiVolume = s.uiVolume
	end
	if type(s.gameVolume) == "number" then
		settings.gameVolume = s.gameVolume
	end
	apply()
end

function Audio.Play(name: string, pitch: number?)
	local s = cache[name]
	if not s then
		return
	end
	local clone = s:Clone()
	clone.Parent = SoundService
	clone.PlaybackSpeed = pitch or 1
	clone:Play()
	clone.Ended:Once(function()
		clone:Destroy()
	end)
	task.delay(4, function()
		if clone.Parent then
			clone:Destroy()
		end
	end)
end

function Audio.Click()
	Audio.Play("Click", 1)
end

function Audio.Hover()
	local now = os.clock()
	if now - hoverGate < 0.05 then
		return
	end
	hoverGate = now
	Audio.Play("Hover", 1.15)
end

function Audio.Success()
	Audio.Play("Success", 1.05)
end

function Audio.Error()
	Audio.Play("Error", 0.9)
end

function Audio.Reward()
	Audio.Play("Reward", 1)
end

function Audio.Notify()
	Audio.Play("Notification", 1.1)
end

function Audio.Boot()
	Audio.Play("Boot", 0.85)
end

function Audio.StartMusic()
	if music and not music.IsPlaying then
		music:Play()
	end
end

function Audio.StopMusic()
	if music then
		music:Stop()
	end
end

return Audio
