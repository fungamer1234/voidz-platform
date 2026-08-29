--!strict
--[[
	Stable navigation API. App binds the implementation at startup.
	Pages should go through App.open; this exists so extra systems can
	request a route without importing App (avoids require cycles).
]]

local Navigation = {}

local impl: { open: (string) -> (), back: () -> () }? = nil

function Navigation.Bind(open: (string) -> (), back: () -> ())
	impl = { open = open, back = back }
end

function Navigation.Open(name: string)
	if impl then
		impl.open(name)
	end
end

function Navigation.Back()
	if impl then
		impl.back()
	end
end

return Navigation
