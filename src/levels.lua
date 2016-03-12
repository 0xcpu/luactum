local levelNames = {
   CRITICAL = 50,
   ERROR    = 40,
   WARNING  = 30,
   INFO     = 20,
   DEBUG    = 10,
   NOTSET   = 0
}

for k, v in pairs(levelNames) do
   levelNames[v] = k
end

local function getLevelName(level)
   assert(level, "argument value is: " .. tostring(level))

   return levelNames[level]
end

local levelFuncs = {'debug', 'info', 'warning', 'error', 'critical'}

local function getLevelFuncs()
   return levelFuncs
end

local function checkLevel(level)
   local argType = type(level)

   if argType == "number" then
      return level
   elseif argType == "string" then
      return levelNames[level] and levelNames[level] or nil
   else
      return nil
   end
end

local function getLevelName(level)
   assert(level, "argument value is: " .. tostring(level))

   return levelNames[level]
end

local levels = {
   checkLevel    = checkLevel,
   getLevelName  = getLevelName,
   getLevelFuncs = getLevelFuncs
}

return levels
