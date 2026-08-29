--!strict

local Maid = {}
Maid.__index = Maid

function Maid.new()
	return setmetatable({ _t = {} :: { any } }, Maid)
end

function Maid:Give(item: any)
	table.insert(self._t, item)
	return item
end

function Maid:GiveTask(fn: () -> ())
	table.insert(self._t, fn)
end

function Maid:_cleanOne(item: any)
	local ty = typeof(item)
	if ty == "RBXScriptConnection" then
		item:Disconnect()
	elseif ty == "Instance" then
		item:Destroy()
	elseif ty == "function" then
		item()
	elseif ty == "table" then
		if type(item.Destroy) == "function" then
			item:Destroy()
		elseif type(item.Disconnect) == "function" then
			item:Disconnect()
		elseif type(item.DoCleaning) == "function" then
			item:DoCleaning()
		end
	end
end

function Maid:DoCleaning()
	for _, item in self._t do
		self:_cleanOne(item)
	end
	table.clear(self._t)
end

function Maid:Destroy()
	self:DoCleaning()
end

return Maid
