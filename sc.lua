--[[
Note that for apps like Waterfox and iTerm, separate windows do not
register as separate applications. If we have 3 windows open for
Waterfox for example, moving :mainWindow() (whatever window it
refers to) will move all 3 of them to the target space.
]]
-- need to escape hyphens with %

JSON = require('JSON')

local open = io.open
local function read_file(path)
    local file = open(path, "rb") -- r read mode and b binary mode
    if not file then return nil end
    local content = file:read "*a" -- *a or *all reads the whole file
    file:close()
    return content
end

local function extract_max_idx(dict)
   buf = {}
   for key,val in pairs(dict) do
      table.insert(buf,val)
   end
   return math.max(table.unpack(buf))
end

if #_cli.args ~= 3 then
   print("usage: hs ./sc.lua -- <path to json file>")
   return
end

local MAPPING = JSON:decode(read_file(_cli.args[3]))
print(hs.inspect(MAPPING))

print("args: " .. hs.inspect(_cli.args))
--print(hs.spoons.scriptPath())

-- a dict mapping screens (monitors) to spaces (ints)
screen2spaces = hs.spaces.allSpaces()
-- https://www.hammerspoon.org/docs/hs.screen.html#find

--print(hs.inspect(screens))
local tgt_uuid = nil
-- For each screen (monitor))
for screenname,screendict in pairs(MAPPING) do
  local this_screen = hs.screen.find(screenname)
  print(this_screen:name() .. " with id: " .. this_screen:getUUID())
  local tgt_uuid = this_screen:getUUID()
  local this_spaces = screen2spaces[tgt_uuid]
  print("  --> space ids: " .. hs.inspect(this_spaces))

  local max_screen_idx = extract_max_idx(screendict)
  if #this_spaces < max_screen_idx then
     -- if we have less spaces than the max idx, we need to
     -- add some spaces to make it possible
     local delta = max_screen_idx - #this_spaces
     print("  --> add " .. delta .. " many extra spaces")
     for j=1,delta do hs.spaces.addSpaceToScreen(this_screen) end
  end

  for appname,screenidx in pairs(screendict) do

     local this_app = hs.application.find(appname)
     if this_app ~= nil then
	if this_app:mainWindow() ~= nil then
	   local pprint_str = this_app:name() .. "(title=" .. this_app:mainWindow():title() .. ")"
	   print("  --> assign " .. pprint_str .. " to space: " .. screenidx .. "(id=" .. this_spaces[screenidx] .. ")")
	   local this_window = this_app:mainWindow()
	   -- todo: also maximise it
	   hs.spaces.moveWindowToSpace(this_window, this_spaces[screenidx])
	else
	   print("  --> " .. this_app:name() .. " exists but cannot find mainWindow, maybe focus it?")
	end
     else
	print("  --> could not find app: " .. appname)
     end
  end

end

--[[
Originally I wanted to get all window ids for a specific space,
and then move them to a 'dump' space. However, windowsForSpace
will also return non-visible / irrelevant windows and I wouldn't
be able to identify them anyway with `window.find` since it only
takes into account windows in the active space. I could maybe
blindly move them all anyway to the dump space but I don't know
if that will have any side effects.

So I will use the 'dumb' algorithm which will simply move target
apps to their corresponding spaces, even if those spaces are
occupied with other applications. So I may still have to do some
manual labour after the script has run.
--]]

-- Do we have enough spaces?
--if 
