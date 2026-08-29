--!strict

export type Achievement = {
	Id: string,
	Name: string,
	Description: string,
	Icon: string,
}

local LIST: { Achievement } = {
	{ Id = "welcome", Name = "Welcome Aboard", Description = "Finish VOIDZ setup.", Icon = "★" },
	{ Id = "first_play", Name = "First Launch", Description = "Press Play on any game.", Icon = "▶" },
	{ Id = "explorer", Name = "Explorer", Description = "Launch 3 different games.", Icon = "▲" },
	{ Id = "customizer", Name = "Customizer", Description = "Save an avatar loadout.", Icon = "◈" },
	{ Id = "collector", Name = "Collector", Description = "Own 10 items.", Icon = "▤" },
	{ Id = "social", Name = "Social Spark", Description = "Add a VOIDZ friend.", Icon = "◎" },
	{ Id = "wealthy", Name = "Funded", Description = "Hold 1,000 VoidCoins at once.", Icon = "VC" },
	{ Id = "regular", Name = "Regular", Description = "Log in 5 times.", Icon = "◉" },
	{ Id = "first_win", Name = "First Win", Description = "Win a VOIDZ match.", Icon = "♛" },
	{ Id = "champion", Name = "Champion", Description = "Win 5 matches.", Icon = "◆" },
	{ Id = "survivor", Name = "Survivor", Description = "Survive a disaster or sky match.", Icon = "▲" },
	{ Id = "speed_demon", Name = "Speed Demon", Description = "Finish a race or obby first.", Icon = "»" },
	{ Id = "brain_banker", Name = "Brain Banker", Description = "Bank 10 Brains across matches.", Icon = "◎" },
	{ Id = "untouchable", Name = "Untouchable", Description = "Win Hideout as a hider.", Icon = "◌" },
}

local byId: { [string]: Achievement } = {}
for _, a in LIST do
	byId[a.Id] = a
end

local Achievements = {}

function Achievements.GetAll(): { Achievement }
	return LIST
end

function Achievements.Get(id: string): Achievement?
	return byId[id]
end

return Achievements
