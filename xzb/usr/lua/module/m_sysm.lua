
local Base = require("XLMonitorBase")

local _xlog = require("xlog")
local xlog = _xlog:instance_get("monitor", nil, "monitor module\n")

local _consts = require("consts")
local CONSTS = _consts:instance_get()

local m_sysm = {}

local _M = m_sysm

setmetatable(_M, Base)

_M.__index = _M

function _M:new()
	local self = {}
	self = Base:new("sysmonitor", "sysmonitor")
	setmetatable(self, _M)
	return self
end

function _M:start()
	print("start module sysmonitor")
	os.execute("${PLUGIN_ROOT}/etc/init.d/sysmsh start")
end

function _M:stop()
	print("stop module sysmonitor")
	os.execute("${PLUGIN_ROOT}/etc/init.d/sysmsh stop")
end

function _M:status()
	local status = 0
	status = self:is_running(self.name)
	if status == CONSTS.status_stopped then
		print("sysmonitor not running")
        xlog:xlog(xlog.warning, self.name .. ": sysmonitor is not running\n")
		return status
	end  
    
	return CONSTS.status_active
end

return _M
