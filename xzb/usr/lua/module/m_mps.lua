
local Base = require("XLMonitorBase")

local _xlog = require("xlog")
local xlog = _xlog:instance_get("monitor", nil, "monitor module\n")

local _consts = require("consts")
local CONSTS = _consts:instance_get()


local m_mps = {}

local _M = m_mps

setmetatable(_M, Base)

_M.__index = _M

function _M:new()
	local self = {}
	self = Base:new("mps", "mps")
	setmetatable(self, _M)
	self.unix = "/tmp/nginx/socket/mps.sock"
	return self
end

function _M:start()
	print("start module mps")
	os.execute("${PLUGIN_ROOT}/etc/init.d/mpssh start")
end

function _M:stop()
	print("stop module mps")
	os.execute("${PLUGIN_ROOT}/etc/init.d/mpssh stop")
end

function _M:get_version()
    local uri = "/upgrade.csp?opt=getversion"
    local ret, body, status_code, headers, status = self:http_low_get(self.unix, self.port, uri, nil)
    
    if ret ~= CONSTS.status_active then
        return ret
    end

	return ret
end

function _M:status()
	--print("check status module mps ... ")
	local status = 0
	status = self:is_running(self.name)
	if status == CONSTS.status_stopped then
		--print("mps not running")
		return status
	end
	
	status = self:get_version()
	if status ~= CONSTS.status_active then
		return status
	end

	return status
end

return _M
