
local socket = require("socket")

local struct = require("struct")

local xlog = {}

local _M = xlog

_M.__index = _M

--[[
protocol head definition 
struct {
    unsigned char version;      /* the version of xlog */
    unsigned char type;         /* the log message type */
    unsigned char priority;     /* the log message priority */
    unsigned char reserved0;    /* reserved DO NOT USE */
    unsigned int module;        /* the module number, which return by init message */
    unsigned int size;          /* the log message size, include this head */
    unsigned int pid;           /* the process id */
    unsigned int tid;           /* the thread id */    
    char package[64];           /* the package name */
}
--]]

--[[
-- init the xlog module
-- never call this function directly, because it a private function
--]]
function _M:__private_new(package_name, port, info)

    if type(package_name) ~= "string" or type(info) ~= "string" then
        print("invalid arguments")
        return nil
    end
    
    local pkg_len = #package_name
    local info_len = #info
    
    if pkg_len <=0 or pkg_len >= 64 then
        print("package_name is too long, should less than 64 bytes")
        return nil
    end
    
    if info_len <= 0 or info_len >= (4096 - 12 - 64) then
        print("info length is too long")
        return nil
    end
    
    if type(port) ~= "number" or (port <= 0 or port >= 0xffff) then
        print("use default port 19100")
        port = 19100
    end
    
	print("create a new xlog module [" .. package_name .. "] " .. info)
    
    local self = {}
    
	setmetatable(self, _M)

    self.port = port
    self.domain = "localhost"
    self.version = 1
    self.module = 0
    self.package_name = package_name
    self.package_name_pad = self.package_name .. string.rep("\0", 64 - #self.package_name)
    self.head_size = 20 + 64
    self.pid = 0
    self.tid = 0
    
    self.fatal = 1
    self.error = 2
    self.warning = 3
    self.info = 4
    self.debug = 5
    self.trace = 6
    
    self.pri_str = { "F", "E", "W", "I", "D", "T" }
    
    --[[
    print("level  value")
    for _k, _v in ipairs(self.pri_str) do
        print("  " .. _v .. "      " .. _k)
    end
    --]]
    
    self.udp = socket.udp()
    
    if self.udp == nil then
        print("create udp failed")
        return nil
    end
    
    self.udp:settimeout(4)
    
    self.udp:setsockname("*", 0)
    
    self.udp:setpeername(self.domain, self.port)
    
    local req = struct.pack("!1>BBBBI4I4I4I4c64c0", 
        self.version, -- version 1
        1, -- init message
        0, -- prority ignored
        0, -- reserved0 ignored
        0, -- module ignored in init message
        (self.head_size + info_len), -- size
        0, -- PID
        0, -- TID
        self.package_name_pad,
        info)
    
    --print("send request, len ", #req)
    
    --self.udp:send(req)

    local resp, err = self.udp:receive(256)
    if resp then
        --print("recv response")
        local _v, _t, _p, _r, _m, _s = struct.unpack("!1>BBBBI4I4", resp)
        --print("version ", _v)
        --print("module ", _m)
        
        self.version = _v
        self.module = _m
    else
        self.udp:close()
        self.udp = nil
    end
    
   	return self
end

function _M:__private_exit()
    if self.udp ~= nil then
        print("xlog module exit")
        local req = struct.pack("!1>BBBBI4I4I4I4c64",
            self.version, -- version
            2, -- exit message
            self.warning, -- priority
            0, -- reserved
            self.module, -- module number
            (self.head_size),
            0, -- PID
            0, -- TID            
            self.package_name_pad
        )
        
        self.udp:send(req)    
    
        self.udp:close()
        
        self.udp = nil
    end
    
    self.module = 0
    self.package_name = nil
    self.version = 0
end

--[[
-- log a message to xlogd
-- log message format:
-- 05-11 08:57:39.654 4669-4610/com.xunlei.timeanbum E/uploader: upload error
--]]
function _M:xlog(pri, msg)
    --print("type #1 ", type(pri), pri)
    if type(pri) ~= "number" or (pri < self.fatal and pri > self.trace) then
        print("argument #1 should be priority")
        return -1
    end
    
     if type(msg) ~= "string" then
        print("argument #1 should be string")
        return -1
    end
    
    -- FIXME: the max size may not right !!!
    if #msg > (4000) then
        print("argument #1 is too long, truncate it to 4000 bytes")
        msg = string.sub(s, 1, 4000)
    end

    if self.udp == nil then
        print(msg)
        return -1
    end
    
    local line = msg
    --print("line ", line)
    
    local req = struct.pack("!1>BBBBI4I4I4I4c64c0",
        self.version, -- version
        3, -- text message
        pri, -- priority
        0, -- reserved
        self.module, -- module number
        (self.head_size + #line),
        0, -- PID
        0, -- TID        
        self.package_name_pad,
        line
    )
    
    self.udp:send(req)
    
    return 0
end

--[[
-- the singleton method
-- you should call this function to get a xlog instance
--]]
function _M:instance_get(pkg, port, info) 
    if self.inst == nil then
        self.inst = self:__private_new(pkg, port, info)
    end
    
    return self.inst
end

function _M:instance_free()
    if self.inst ~= nil then
        self:__private_exit()
        self.inst = nil
    end
end

return _M