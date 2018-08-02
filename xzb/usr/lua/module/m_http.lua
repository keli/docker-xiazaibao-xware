
local Base = require("XLMonitorBase")

local _xlog = require("xlog")
local xlog = _xlog:instance_get("monitor", nil, "monitor module\n")

local _consts = require("consts")
local CONSTS = _consts:instance_get()

local m_http = {}

local _M = m_http

setmetatable(_M, Base)

_M.__index = _M

function _M:new()
	local self = {}
	self = Base:new("nginx", "http")
	setmetatable(self, _M)

	local ip = "127.0.0.1"
	local port = 8800
	local f = nil
    local t = nil

	f = io.open("/tmp/nginx/conf/nginx.port", "r")
	if not f then
		xlog:xlog(xlog.error, "monitor: can not get nginx bind port address\n")
	else
        
		t = f:read("*number")
		if not t then
			xlog:xlog(xlog.error, "monitor: get nginx bind port return nil\n")
		else
            port = t
			xlog:xlog(xlog.warning, "monitor: get nginx bind port " .. port .. " \n")
		end
		
		f:close()
		f = nil
	end
  
	self.ip = ip
	self.port = port    
    
	return self
end

function _M:start()
	print("start module http")
	os.execute("${PLUGIN_ROOT}/etc/init.d/nginxsh start")
end

function _M:stop()
	print("stop module http")
	os.execute("${PLUGIN_ROOT}/etc/init.d/nginxsh stop")
end

function _M:get_file()
    local uri = "/"
	-- first try 127.0.0.1
    local ret, body, status_code, headers, status = self:http_low_get(self.ip, self.port, uri, nil)
    
    if ret ~= CONSTS.status_active then
        return ret
    end

	-- second, try lan ip if have
	local f = io.open("/tmp/nginx/conf/nginx.ip", "r")
	if not f then
		--xlog:xlog(xlog.debug, "monitor: can not get nginx bind ip address\n")
		return CONSTS.status_active
	else
		-- try to parse
		local ip = f:read("*line")
		f:close()
		f = nil
		if not ip then
			--xlog:xlog(xlog.error, "monitor: get nginx bind ip return nil\n")
		else
			-- try to get http
			ret, body, status_code, headers, status = self:http_low_get(ip, self.port, uri, nil)

    		if ret ~= CONSTS.status_active then
	    	    return ret
		    end
		end
	end

    --print("body is [" .. body .. "]")

	return ret
end

function _M:status()
	--print("check status module http ... ")
	local status = 0
	status = self:is_running(self.name)
	if status == CONSTS.status_stopped then
		--print("http not running")
		return status
	end
	
	status = self:get_file()
    --print("return is " .. status)
	if status ~= CONSTS.status_active then
		return status
	end

	return status
end

return _M
