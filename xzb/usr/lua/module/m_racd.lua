
local Base = require("XLMonitorBase")

local _xlog = require("xlog")
local xlog = _xlog:instance_get("monitor", nil, "monitor module\n")

local _consts = require("consts")
local CONSTS = _consts:instance_get()

local m_racd = {}

local _M = m_racd

setmetatable(_M, Base)

_M.__index = _M

function _M:new()
	local self = {}
	self = Base:new("racd", "racd")
	setmetatable(self, _M)
	return self
end

function _M:start()
	print("start module racd")
	os.execute("${PLUGIN_ROOT}/etc/init.d/racdsh start")
end

function _M:stop()
	print("stop module racd")
	os.execute("${PLUGIN_ROOT}/etc/init.d/racdsh stop")
end

function _M:status()
	--print("check status module racd ... ")
	local status = 0
	status = self:is_running(self.name)
	if status == CONSTS.status_stopped then
		return status
	end

	return CONSTS.status_active
end

return _M
