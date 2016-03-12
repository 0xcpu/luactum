local utils  = require "utils"
local levels = require "levels"

local LogRecord = {}
LogRecord.__index = LogRecord

setmetatable(LogRecord, {
		__call = function(cls, ...)
		   return cls.new(...)
		end,
})

function LogRecord.new(name, msg, level, func)
   local self     = setmetatable({}, LogRecord)
   self.name      = name
   self.msg       = msg
   self.levelno   = level
   self.levelname = levels.getLevelName(level)
   self.func      = func or "no func"

   return self
end

function LogRecord:getMessage()
   return string.format('<LogRecord>: %s %s %s %s %s',
			self.name, self.msg, self.levelno,
			self.levelname, self.func)
end

local FileHandler = {}
FileHandler.__index = FileHandler

setmetatable(FileHandler, {
		__call = function(cls, ...)
		   return cls.new(...)
		end,
})

function FileHandler.new(fileName, mode, level)
   local self    = setmetatable({}, FileHandler)
   self.fileName = fileName or 'log.txt'
   self.mode     = mode or 'a+'
   self.level    = levels.checkLevel(level) or 0

   return self
end

function FileHandler:handle(record)
   local fh, errMsg = io.open(self.fileName, self.mode)
   if fh == nil then
      io.stderr:write("File opening error: " .. errMsg)
      return
   else
      fh:write(table.concat({record:getMessage(), ' ', utils.getTime(), '\n'}))
      fh:close()
   end
end

local Logger = {}
Logger.__index = Logger

setmetatable(Logger, {
		__call = function(cls, ...)
		   return cls.new(...)
		end,
})

function Logger.new(name, level)
   local self    = setmetatable({}, Logger)
   self.name     = name or "MainLogger"
   self.level    = levels.checkLevel(level) or 0
   self.handlers = {FileHandler()}
   self.disabled = false

   return self
end

function Logger:setLevel(level)
   self.level = levels.checkLevel(level)
end

function Logger:makeRecord(name, msg, level)
   return LogRecord(name, msg, level)
end

function Logger:callHandlers(record)
   for i, h in pairs(self.handlers) do
      if record.levelno >= h.level then
	 h:handle(record)
      end
   end
end

function Logger:handle(record)
   if not self.disabled then
      self:callHandlers(record)
   end
end

function Logger:isEnabledFor(level)
   return level >= self.level
end

function Logger:log(msg, level)
   local record = self:makeRecord(self.name, msg, level,
				  debug.getinfo(3, 'n').name)
   self:handle(record)
end

function Logger:addHandler(hdlr)
   if not self.handlers[hdlr] then
      table.insert(self.handlers, hdlr)
   end
end

function Logger:removehandler(hdlr)
   if self.handlers[hdlr] then
      self.handlers[hdlr] = nil
   end
end

local levelFuncs = levels.getLevelFuncs()
for k, v in pairs(levelFuncs) do
   Logger[v] = function(self, msg)
      local level = levels.getLevelName(v:upper())
      assert(level)
      
      if self:isEnabledFor(level) then
	 self:log(msg, level)
      end
   end
end

local logging = {
   FileHandler = FileHandler,
   Logger      = Logger
}

return logging
