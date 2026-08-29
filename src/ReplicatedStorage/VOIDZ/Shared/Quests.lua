--!strict

export type Quest = {
	Id: string,
	Name: string,
	Description: string,
	Stat: string,
	Target: number,
	Reward: number,
}

local LIST: { Quest } = {
	{ Id = "play_1", Name = "Lace up", Description = "Finish 1 match.", Stat = "plays", Target = 1, Reward = 25 },
	{ Id = "play_5", Name = "Regular", Description = "Finish 5 matches.", Stat = "plays", Target = 5, Reward = 80 },
	{ Id = "win_1", Name = "Get on the board", Description = "Win 1 match.", Stat = "wins", Target = 1, Reward = 40 },
	{ Id = "win_3", Name = "Hot streak", Description = "Win 3 matches.", Stat = "wins", Target = 3, Reward = 120 },
	{ Id = "brains_10", Name = "Brain collector", Description = "Bank 10 Brains.", Stat = "brains", Target = 10, Reward = 90 },
	{ Id = "kills_10", Name = "Sharp", Description = "Record 10 combat takedowns.", Stat = "kills", Target = 10, Reward = 90 },
	{ Id = "survive_3", Name = "Still standing", Description = "Survive 3 disaster/sky rounds.", Stat = "survives", Target = 3, Reward = 80 },
	{ Id = "race_1", Name = "Checkered", Description = "Finish a race.", Stat = "races", Target = 1, Reward = 40 },
}

local Quests = {}

function Quests.GetAll(): { Quest }
	return LIST
end

function Quests.Get(id: string): Quest?
	for _, q in LIST do
		if q.Id == id then
			return q
		end
	end
	return nil
end

return Quests
