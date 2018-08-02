
local ltn12 = require("ltn12")
local json = require("dkjson")

local Base = require("XLMonitorBase")

local _xlog = require("xlog")
local xlog = _xlog:instance_get("monitor", nil, "monitor module\n")

local _consts = require("consts")
local CONSTS = _consts:instance_get()

local m_etm = {}

local _M = m_etm

setmetatable(_M, Base)

_M.__index = _M

function _M:new()
	local self = {}
	self = Base:new("etm", "etm")
	setmetatable(self, _M)
	return self
end

function _M:start()
	print("start module etm")
	os.execute("${PLUGIN_ROOT}/etc/init.d/etmsh start")
end

function _M:stop()
	print("stop module etm")
	os.execute("${PLUGIN_ROOT}/etc/init.d/etmsh stop")
end

function _M:status()
	--print("check status module etm ...")
	local status = 0
	status = self:is_running(self.name)
	if status == CONSTS.status_stopped then
		print("etm not running")
        xlog:xlog(xlog.warning, self.name .. ": etm is not running\n")
		return status
	end   
    
	return CONSTS.status_active
end

return _M
