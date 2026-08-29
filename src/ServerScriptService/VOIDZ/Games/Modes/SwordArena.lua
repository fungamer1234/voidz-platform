--!strict

local MapUtil = require(script.Parent.Parent.MapUtil)
local CombatUtil = require(script.Parent.Parent.CombatUtil)
local AIUtil = require(script.Parent.Parent.AIUtil)

local Mode = {
	Id = "sword_arena",
	LobbySeconds = 5,
	MatchSeconds = 120,
	Respawn = 3,
	Actions = { "attack", "block", "dodge" },
	Objective = "Server-checked melee. Highest kills at the horn wins.",
	Tips = { "Block chips damage.", "Dodge has a cooldown.", "Bots swing too." },
}

function Mode.Build(rt)
	local o = rt.origin
	MapUtil.arena(rt.folder, o, 100, 100, 12, Color3.fromRGB(36, 36, 44))
	for i = 1, 6 do
		MapUtil.part(rt.folder, {
			Name = "Pillar",
			Size = Vector3.new(4, 10, 4),
			CFrame = CFrame.new(o + Vector3.new(math.cos(i) * 22, 6, math.sin(i) * 22)),
			Color = Color3.fromRGB(70, 70, 82),
		})
	end
	rt.spawns = MapUtil.ringSpawns(rt.folder, o, 12, 32, 2)
	rt.extra.bots = {}
	rt.extra.blockUntil = {}
	rt.extra.dodge = {}
	for i = 1, math.max(1, 4 - #rt.players) do
		local bot = AIUtil.dummy(rt.folder, "SparringBot", CFrame.new(o + Vector3.new(i * 6, 4, 10)), Color3.fromRGB(160, 80, 80), 1)
		local hum = bot:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = 13
			hum.DisplayName = "Bot"
		end
		table.insert(rt.extra.bots, { model = bot, next = 0 })
	end
end

function Mode.OnCharacter(rt, player, char)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = 18
	end
end

function Mode.Begin(rt)
	rt.announce("Blades out.")
	for _, p in rt.players do
		rt.scores[p.UserId] = 0
	end
end

function Mode.Tick(rt, dt)
	for _, bot in rt.extra.bots do
		if not bot.model.Parent then
			continue
		end
		local root = bot.model.PrimaryPart
		if not root then
			continue
		end
		local ply, pos = AIUtil.nearestPlayer(root.Position, rt.players, 50)
		if ply and pos then
			if os.clock() >= bot.next then
				bot.next = os.clock() + 0.9
				AIUtil.pathTo(bot.model, pos)
			end
			if (root.Position - pos).Magnitude < 7 then
				local hum = CombatUtil.humanoid(ply)
				if hum and os.clock() > (bot.swing or 0) then
					bot.swing = os.clock() + 1.1
					if ply:GetAttribute("VOIDZ_Block") then
						hum:TakeDamage(4)
					else
						hum:TakeDamage(10)
					end
				end
			end
		end
	end
	rt.publicExtra.kills = rt.kills
end

function Mode.OnAction(rt, player, action)
	if action == "block" then
		player:SetAttribute("VOIDZ_Block", true)
		task.delay(0.7, function()
			player:SetAttribute("VOIDZ_Block", false)
		end)
		return { ok = true }
	elseif action == "dodge" then
		if os.clock() < (rt.extra.dodge[player.UserId] or 0) then
			return { ok = false, error = "Dodge cooling down." }
		end
		rt.extra.dodge[player.UserId] = os.clock() + 1.6
		local hrp = CombatUtil.hrp(player)
		if hrp then
			hrp.AssemblyLinearVelocity = hrp.CFrame.LookVector * -38 + Vector3.new(0, 10, 0)
		end
		return { ok = true }
	elseif action == "attack" then
		local ok, hit = CombatUtil.swing(player, rt.players, { range = 8.5, damage = 22, cooldown = 0.48, knockback = 26 })
		if ok and hit then
			local char = hit.Character
			if char then
				CombatUtil.tagKill(char, player)
			end
			local hum = CombatUtil.humanoid(hit)
			if hum and hum.Health <= 0 then
				rt.kills[player.UserId] = (rt.kills[player.UserId] or 0) + 1
				rt.scores[player.UserId] = rt.kills[player.UserId]
				local QuestService = require(script.Parent.Parent.Parent.Services.QuestService)
				QuestService.Add(player, "kills", 1)
			else
				rt.scores[player.UserId] = (rt.scores[player.UserId] or 0) + 1
			end
		end
		return { ok = ok, hit = hit and hit.UserId }
	end
	return { ok = false }
end

function Mode.OnDied(rt, player)
	rt.kills[player.UserId] = rt.kills[player.UserId]
end

return Mode
