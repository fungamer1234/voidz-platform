--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VOIDZ = ReplicatedStorage:WaitForChild("VOIDZ")
local Constants = require(VOIDZ.Shared.Constants)
local NotificationService = require(script.Parent.NotificationService)

local PartyService = {}

type Party = { leader: number, members: { number } }
local parties: { [number]: Party } = {} -- keyed by leader
local ofPlayer: { [number]: number } = {} -- userId -> leaderId
local pending: { [number]: { from: number, at: number } } = {}

local function partyOf(userId: number): Party?
	local leader = ofPlayer[userId]
	if not leader then
		return nil
	end
	return parties[leader]
end

function PartyService.Members(player: Player): { Player }
	local list = { player }
	local p = partyOf(player.UserId)
	if not p then
		return list
	end
	for _, id in p.members do
		local pl = Players:GetPlayerByUserId(id)
		if pl and pl ~= player then
			table.insert(list, pl)
		end
	end
	return list
end

function PartyService.Snapshot(player: Player): any
	local p = partyOf(player.UserId)
	if not p then
		return { ok = true, party = { leader = player.UserId, members = { { userId = player.UserId, name = player.Name } } } }
	end
	local members = {}
	for _, id in p.members do
		local pl = Players:GetPlayerByUserId(id)
		table.insert(members, {
			userId = id,
			name = if pl then pl.Name else "Player",
			online = pl ~= nil,
		})
	end
	return { ok = true, party = { leader = p.leader, members = members } }
end

function PartyService.Invite(from: Player, targetId: any): any
	if type(targetId) ~= "number" or targetId == from.UserId then
		return { ok = false, error = Constants.ERRORS.INVALID }
	end
	local target = Players:GetPlayerByUserId(targetId)
	if not target then
		return { ok = false, error = "That player isn't in this server." }
	end
	pending[targetId] = { from = from.UserId, at = os.time() }
	NotificationService.Push(target, "Friend", "Party invite", from.DisplayName .. " wants you in their party.")
	return { ok = true }
end

function PartyService.Respond(player: Player, accept: any): any
	local pend = pending[player.UserId]
	if not pend then
		return { ok = false, error = "No invite." }
	end
	pending[player.UserId] = nil
	if accept ~= true then
		return { ok = true, declined = true }
	end
	local leaderId = pend.from
	if ofPlayer[leaderId] then
		leaderId = ofPlayer[leaderId]
	end
	local p = parties[leaderId]
	if not p then
		p = { leader = leaderId, members = { leaderId } }
		parties[leaderId] = p
		ofPlayer[leaderId] = leaderId
	end
	if #p.members >= 6 then
		return { ok = false, error = "Party is full." }
	end
	if not table.find(p.members, player.UserId) then
		table.insert(p.members, player.UserId)
	end
	ofPlayer[player.UserId] = leaderId
	return PartyService.Snapshot(player)
end

function PartyService.Leave(player: Player): any
	local p = partyOf(player.UserId)
	if not p then
		return { ok = true }
	end
	local idx = table.find(p.members, player.UserId)
	if idx then
		table.remove(p.members, idx)
	end
	ofPlayer[player.UserId] = nil
	if p.leader == player.UserId then
		parties[p.leader] = nil
		for _, id in p.members do
			ofPlayer[id] = nil
		end
	end
	return { ok = true }
end

function PartyService.Clear(player: Player)
	PartyService.Leave(player)
	pending[player.UserId] = nil
end

return PartyService
