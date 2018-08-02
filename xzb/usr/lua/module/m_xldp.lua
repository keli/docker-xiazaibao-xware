
local ltn12 = require("ltn12")
local json = require("dkjson")

local Base = require("XLMonitorBase")

local _xlog = require("xlog")
local xlog = _xlog:instance_get("monitor", nil, "monitor module\n")

local _consts = require("consts")
local CONSTS = _consts:instance_get()

local m_xldp = {}

local _M = m_xldp

setmetatable(_M, Base)

_M.__index = _M

function _M:new()
	local self = {}
	self = Base:new("xldp", "xldp")
	setmetatable(self, _M)
	--self:set_uri("http://localhost:8200")
	return self
end

function _M:start()
	print("start module xldp")
	os.execute("${PLUGIN_ROOT}/etc/init.d/xldpsh start")
end

function _M:stop()
	print("stop module xldp")
	os.execute("${PLUGIN_ROOT}/etc/init.d/xldpsh stop")
end

function _M:status()
	--print("check status module xldp ...")
	local status = 0
	status = self:is_running(self.name)
	if status == CONSTS.status_stopped then
		print("xldp not running")
        xlog:xlog(xlog.warning, self.name .. ": xldp is not running\n")
		return status
	end  
    
	return CONSTS.status_active
end

return _M
