--!strict

local CombatUtil = {}

local lastSwing: { [number]: number } = {}

function CombatUtil.clear(userId: number?)
	if userId then
		lastSwing[userId] = nil
	else
		table.clear(lastSwing)
	end
end

function CombatUtil.hrp(player: Player): BasePart?
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

function CombatUtil.humanoid(player: Player): Humanoid?
	local char = player.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

function CombatUtil.alive(player: Player): boolean
	local h = CombatUtil.humanoid(player)
	return h ~= nil and h.Health > 0
end

function CombatUtil.swing(attacker: Player, targets: { Player }, opts: {
	range: number,
	damage: number,
	cooldown: number,
	knockback: number?,
}): (boolean, Player?)
	if not CombatUtil.alive(attacker) then
		return false, nil
	end
	local now = os.clock()
	if (lastSwing[attacker.UserId] or 0) + opts.cooldown > now then
		return false, nil
	end
	local aHrp = CombatUtil.hrp(attacker)
	if not aHrp then
		return false, nil
	end
	if attacker:GetAttribute("VOIDZ_Block") == true then
		return false, nil
	end
	lastSwing[attacker.UserId] = now
	local look = aHrp.CFrame.LookVector
	local hit: Player? = nil
	local hitDist = opts.range
	for _, t in targets do
		if t ~= attacker and CombatUtil.alive(t) then
			local th = CombatUtil.hrp(t)
			if th then
				local off = th.Position - aHrp.Position
				local dist = off.Magnitude
				if dist <= opts.range and dist > 0 then
					local dir = off.Unit
					if dir:Dot(look) > 0.15 and dist < hitDist then
						hit = t
						hitDist = dist
					end
				end
			end
		end
	end
	if not hit then
		return true, nil
	end
	if hit:GetAttribute("VOIDZ_Block") == true then
		opts = table.clone(opts)
		-- blocked: chip damage only
		local hum = CombatUtil.humanoid(hit)
		if hum then
			hum:TakeDamage(math.max(1, opts.damage * 0.25))
		end
		return true, hit
	end
	local hum = CombatUtil.humanoid(hit)
	local th = CombatUtil.hrp(hit)
	if hum and th then
		hum:TakeDamage(opts.damage)
		local kb = opts.knockback or 18
		th.AssemblyLinearVelocity = look * kb + Vector3.new(0, 12, 0)
	end
	return true, hit
end

function CombatUtil.tagKill(char: Model, attacker: Player)
	char:SetAttribute("VOIDZ_LastHitter", attacker.UserId)
	char:SetAttribute("VOIDZ_LastHitAt", os.clock())
end

return CombatUtil
