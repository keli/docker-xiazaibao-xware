
local ltn12 = require("ltn12")
local json = require("dkjson")

local Base = require("XLMonitorBase")

local _xlog = require("xlog")
local xlog = _xlog:instance_get("monitor", nil, "monitor module\n")

local _consts = require("consts")
local CONSTS = _consts:instance_get()

local m_xctl = {}

local _M = m_xctl

setmetatable(_M, Base)

_M.__index = _M

function _M:new()
	local self = {}
	self = Base:new("xctl", "xctl")
	setmetatable(self, _M)
	self.unix = "/tmp/nginx/socket/xctl.sock"
	return self
end

function _M:start()
	print("start module xctl")
	os.execute("${PLUGIN_ROOT}/etc/init.d/xctlsh start")
end

function _M:stop()
	print("stop module xctl")
	os.execute("${PLUGIN_ROOT}/etc/init.d/xctlsh stop")
end

function _M:get_heartbeat()
    self.heartbeat = 0

    local uri = "/dlna.csp?fname=dlna&opt=heartbeat&client="
    
    local ret, body, status_code, headers, status = self:http_low_get(self.unix, self.port, uri, nil)
    
    if ret ~= CONSTS.status_active then
        print("get heartbeat not active")
        return ret
    end

    -- e.g. {"rtn":0,"status":"0x41"}
    -- decode the json message
    --print("body ", body)
    local obj, pos, err = json.decode(body)
     
    if err then
        print("request error, ", err)
        xlog:xlog(xlog.error, self.name .. ": decode hearbeat json response failed\n")
        return CONSTS.status_error
    end
    
    --print("obj rtn", obj.rtn)
    if obj.rtn ~= 0 then
        -- return failed
        xlog:xlog(xlog.error, self.name .. ": heartbeat failed, rtn = " .. obj.rtn)
        return CONSTS.status_error
    end
    --print("obj status", obj.status)
    
    self.heartbeat = tonumber(obj.status)
    
	return CONSTS.status_active
end

function _M:get_usbinfo()
    local uri = "/dlna.csp?fname=dlna&opt=getusbinfo&userid="
    local ret, body, status_code, headers, status = self:http_low_get(self.unix, self.port, uri, nil)
    
    if ret ~= CONSTS.status_active then
        return ret
    end
    
    --[[
    -- getusbinfo response example
    {
        "rtn":0,"disklist":
        [
        {"brand":"XunLei","sn":"20140820010004","Partitionlist":
            [
            {
                "key":"201408200100041",
                "path":"/data/UsbDisk1/Volume1",
                "name":"移动磁盘-C(ha)",
                "letter":"C:",
                "volume":"ha",
                "type":"NTFS",
                "size":1000202039296,
                "used":937083043840,
                "encrypt":0
            }
            ]
        }
        ]
    }
    --]]
    --print("body [" .. body .. "]")
    
    local obj, pos, err = json.decode(body)
     
    if err then
        print("request error, ", err)
        xlog:xlog(xlog.error, self.name .. ": decode getusbinfo json response failed\n")
        return CONST.status_error
    end
    
    --print("obj rtn", obj.rtn)
    if obj.rtn ~= 0 and obj.rtn ~= 1 then
        -- return failed
        xlog:xlog(xlog.error, self.name .. ": getusbinfo failed, rtn = " .. obj.rtn)
        return CONST.status_error
    end  
    
	return CONSTS.status_active
end

function _M:status()
	--print("check status module xctl ...")
	local status = 0
	status = self:is_running(self.name)
	if status == CONSTS.status_stopped then
		print("xctl not running")
        xlog:xlog(xlog.warning, self.name .. ": xctl is not running\n")
		return status
	end
	
	status = self:get_heartbeat()
	if status ~= CONSTS.status_active then
        print("heartbeat failed")
        xlog:xlog(xlog.warning, self.name .. ": get heartbeat failed\n")
		return status
	end

	status = self:get_usbinfo()
	if status ~= CONSTS.status_active then
        print("get usbinfo failed")
        xlog:xlog(xlog.warning, self.name .. ": get usbinfo failed\n")
		return status
	end    
    
	return CONSTS.status_active
end

return _M
