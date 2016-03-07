local CRITICAL = 50
local FATAL = CRITICAL
local ERROR = 40
local WARNING = 30
local WARN = WARNING
local INFO = 20
local DEBUG = 10
local NOTSET = 0


local levelNames = {
   [CRITICAL]   =   "CRITICAL",
   [ERROR]      =   "ERROR",
   [WARNING]    =   "WARNING",
   [INFO]       =   "INFO",
   [DEBUG]      =   "DEBUG",
   [NOTSET]     =   "NOTSET",
   ["CRITICAL"] =   CRITICAL,
   ["ERROR"]    =   ERROR,
   ["WARN"]     =   WARNING,
   ["WARNING"]  =   WARNING,
   ["INFO"]     =   INFO,
   ["DEBUG"]    =   DEBUG,
   ["NOTSET"]   =   NOTSET
}

function getTime()
   -- to do

   -- return " - "..year.."."..month.."."..day.."-"..hour..":"..minute..":"..second.."\n"
end

local function checkLevel(level)
   assert(level, tostring(level))

   local argType = type(level)

   if argType == "number" then
      return level
   elseif paramType == "string" then
      if not levelNames[level] then
	 error("Unknown level: " .. level)
      end
      
      return levelNames[level]
   else
      error("Level is not an integer or a valid string: " .. level)
   end
end

local function getLevelName(level)
   return levelNames[level]
end

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
   self.levelname = getLevelName(level)
   self.func      = func or "no func"

   return self
end

function LogRecord:getMessage()
   return string.format("<LogRecord>: %s %s %s %s %s",
			self.name, self.msg, self.levelname,
			self.levelno, self.func)
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
   self.fileName = fileName or "log.txt"
   self.mode     = mode or "a+"
   self.level    = checkLevel(level) or NOTSET

   return self
end

function FileHandler:handle(record)
   local fh, errMsg = io.open(self.fileName, self.mode)
   if fh == nil then
      io.stderr:write("File opening error: " .. errMsg)
      return
   else
      fh:write(record:getMessage() .. getTime())
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
   self.level    = checkLevel(level)
   self.handlers = {}
   self.disabled = false

   return self
end

function Logger:setLevel(level)
   self.level = checkLevel(level)
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

function Logger:debug(msg)
   if self:isEnabledFor(DEBUG) then
      self:log(msg, DEBUG)
   end
end

function Logger:info(msg)
   if self:isEnabledFor(INFO) then
      self:log(msg, INFO)
   end
end

function Logger:warning(msg)
   if self:isEnabledFor(WARNING) then
      self:log(msg, WARNING)
   end
end

function Logger:error(msg)
   if self:isEnabledFor(ERROR) then
      self:log(msg, ERROR)
   end
end

function Logger:critical(msg)
   if self:isEnabledFor(CRITICAL) then
      self:log(msg, CRITICAL)
   end
end

function Logger:log(msg, level)
   local record = self:makeRecord(self.name, msg, level,
				  debug.getinfo(3, "n").name)
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
