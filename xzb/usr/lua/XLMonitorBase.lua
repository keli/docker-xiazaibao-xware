--[[
-- XunLei XiaZaiBao Base interface/class
-- all modules that be monitored should implement below interface:
-- start() the function to start the module
-- stop() the function to stop the module
-- restart() the function to restart the module
-- status() the function to query the module status
--
--]]

local http = require("socket.http")
local socket = require("socket")
--local ltn12 = require("ltn12")
local unixsocket = require("socket.unix")

local _xlog = require("xlog")
local xlog = _xlog:instance_get("monitor", nil, "monitor module\n")

local _consts = require("consts")
local CONSTS = _consts:instance_get()

socket.TIMEOUT = 10

local XLMonitorBase = {}

local _M = XLMonitorBase

_M.__index = _M

function _M:new(name, module)
	local self = {}
	setmetatable(self, _M)
	self.name = name
    self.module = module
    -- FIXME: change this filed to your platform   
    
	return self
end

-- the function to start the module
function _M:start()
	-- do nothing in abstract class
end

-- the function to stop the module
function _M:stop()
	-- do nothing in abstract class
end

-- the function to restart the module
function _M:restart()
    xlog:xlog(xlog.warning, "monitor: restart module [" .. self.name .. "]\n")
    self:stop()
    self:start()
end

--[[
-- the function to query module status
-- nil    the default return value, supper class return this
-- 0      the module is stopped
-- 1      the module is active
-- 2      the module is inactive but not dead/stopped
-- 3      the module is busy
-- 4      the module return error json message
-- other  all other value are reserved, do not use
--]]
function _M:status()
	-- do nothing in abstract class
	return nil
end

-- set the protocol type, default is http
function _M:set_uri(uri)
	self.uri = uri
end

--[[
-- check whether the module application is running or not
--
-- parameter description
-- @name the application name, which show in 'ps' command
--
-- return description
-- 0 stopped or not running
-- 1 running
-- -1 error, the status unknown
--]]
function _M:is_running(name)
	local ret = CONSTS.status_unknown
	local p = io.popen("pidof " .. name)
	if p ~= nil then
		local pids = p:read("*all")
		--print("pids of " .. name .. " [" .. pids .. "]")
		if pids ~= nil and pids ~= "" then
			--print("module " .. name .. " running")
			ret = CONSTS.status_running
		else
			--print("module " .. name .. " stopped")
            xlog:xlog(xlog.warning, "monitor: module stopped [" .. name .. "]\n")
			ret = CONSTS.status_stopped
		end
		
		p:close()
	else
		ret = CONSTS.status_unknown
	end

	return ret
end

--[[
-- the wrapper function for http get
-- nil    the default return value, supper class return this
-- -1     some error
-- 0      the module is stopped
-- 1      the module is active
--]]
function _M:http_low_get(ip, port, uri, timeout)
	--print("url is " .. url)
	if uri == nil or type(uri) ~= "string" or #uri == 0 then
		xlog:xlog(xlog.warning, "monitor: uri is error\n")
		return CONSTS.status_error
	end
    
    if ip == nil or type(ip) ~= "string" or #ip == 0 then
        xlog:xlog(xlog.warning, "monitor: ip is error\n")
        return CONSTS.status_error
    end
    
    if timeout == nil then
        timeout = 10 -- default timeout
    end     
    
    local http_sock = nil
    local ret = nil
    local err = nil
    
    local family = string.sub(ip, 1, 1)
    if family == "/" then
        -- unix domain, e.g /tmp/nginix/xxx.sock
        http_sock = unixsocket()
        if http_sock == nil then
            return CONSTS.status_error
        end
        http_sock:settimeout(timeout)
        
        ret, err = http_sock:connect(ip)        
    else
        -- inet
        if port == nil or type(port) ~= "number" or (port <= 0 or port >= 0xffff) then
            xlog:xlog(xlog.warning, "monitor: port is error\n")
            return CONSTS.status_error
        end
        http_sock = socket.tcp()
        if http_sock == nil then
            return CONSTS.status_error
        end
        http_sock:settimeout(timeout)
        
        ret, err = http_sock:connect(ip, port)
    end
      
    if ret == nil then
        http_sock:close()
        err = err or ""
        xlog:xlog(xlog_warning, "monitor: connect to " .. ip .. ":" .. port .. " failed, " .. err .. "\n")
        return CONSTS.status_error
    end
    
    local req = string.format(
        "GET %s HTTP/1.1\r\n" ..
        "Content-Length: 0\r\n" ..
        "Connection: close\r\n" ..
        "\r\n",
        uri
    )
    
    --print(req)
    
    ret, err = http_sock:send(req)
    
    if ret == nil then
        http_sock:close()
        err = err or ""
        xlog:xlog(xlog_warning, "monitor: send to tcp " .. ip .. ":" .. port .. " failed, " .. err .. "\n")
        return CONSTS.status_error
    end
    
    resp, err = http_sock:receive("*a")
    
    if resp == nil or type(resp) ~= "string" then
        print("failed resp")
        http_sock:close()
        err = err or ""
        xlog:xlog(xlog_warning, "monitor: recv from tcp " .. ip .. ":" .. port .. " failed, " .. err .. "\n")
        return CONSTS.status_error
    end
    
    http_sock:close()
    
    -- now response in resp
    -- HTTP/1.1 200 OK\r\n
    local status_code = nil
    local status_str = nil
    local str = string.sub(resp, 1, 9)

    if str ~= "HTTP/1.1 " then
        return CONSTS.status_error
    end
    
    str = string.sub(resp, 10, 3)
    if str ~= "200" then
        -- not 200 OK
        if type(str) ~= "string" then
            return CONSTS.status_error
        end
        status_code = tonumber(str)
        local i = string.find(resp, "\r\n", 13)
        if i == nil then
            return CONSTS.status_error
        end
        status_str = string.sub(resp, 13, i)
    else
        status_code = 200
        status_str = "OK"
    end
    
    local content_idx = string.find(resp, "\r\n\r\n")
    if content_idx == nil then
        return CONSTS.status_error
    end
    
    local head = string.sub(resp, 1, content_idx + 4)
    local content = string.sub(resp, content_idx + 4, -1)
    
    return CONSTS.status_active, content, status_code, head, status_str
end

--[[
-- the simpile wrapper function for http get
-- return description
-- @ret the CONST.status_xxx see consts.lua
-- @body return the http response body as string
--]]
function _M:http_simple_get(url)
	--print("url is " .. url)
  
   return nil  
--[[
	local body, status_code, headers, status = http.request(url)
   
    --print("status code " .. (status_code))
	--print("body " .. (body))
	--print("head " .. (headers))
	--print("status " .. (status))
    
    --print("body is [" .. body .. "]")
    
	if status_code == 200 then
        -- 200/OK
		ret = CONSTS.status_active
	elseif status_code == 404 then
        -- 404/Not Found
		ret = CONSTS.status_active
    elseif status_code == "closed" then
        ret = CONSTS.status_busy
	elseif status_code == "connection refused" then
		--print("server may not init")
        xlog:xlog(xlog.error, "connect URL " .. url .. "refused, server may not inited\n")
		ret = CONSTS.status_stopped
	elseif status_code == "timeout" then
		--print("connect timeout")
        xlog:xlog(xlog.error, "connect URL " .. url .. "timeout, server may busy\n")
		ret = CONSTS.status_busy
	else
		ret = CONSTS.status_unknown
	end    
    
	return ret, body, status_code, headers, status
--]]    
end


function _M:sleep(seconds)
    socket.sleep(seconds)
end

return _M

