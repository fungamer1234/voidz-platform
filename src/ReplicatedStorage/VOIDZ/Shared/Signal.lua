--!strict

local Signal = {}
Signal.__index = Signal

export type Connection = {
	Disconnect: (self: Connection) -> (),
}

export type Signal = {
	Connect: (self: Signal, fn: (...any) -> ()) -> Connection,
	Fire: (self: Signal, ...any) -> (),
	Destroy: (self: Signal) -> (),
}

function Signal.new(): Signal
	return setmetatable({ _c = {} :: { [any]: (...any) -> () } }, Signal) :: any
end

function Signal:Connect(fn: (...any) -> ()): Connection
	local id = {}
	self._c[id] = fn
	return {
		Disconnect = function()
			self._c[id] = nil
		end,
	}
end

function Signal:Fire(...: any)
	for _, fn in self._c do
		task.spawn(fn, ...)
	end
end

function Signal:Destroy()
	table.clear(self._c)
end

return Signal
