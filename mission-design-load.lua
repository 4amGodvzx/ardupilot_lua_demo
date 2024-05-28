local function control_exchange() --收到靶标后的动作
   return true
end
local function haversineDistance(a, b) --Haversine经纬度换算法
   local earthRadius = 6371000 -- 地球半径
   local lat1Rad = a.x * math.pi / 180
   local lat2Rad = b.x * math.pi / 180
   local diffLat = (b.x - a.x) * math.pi / 180
   local diffLon = (b.y - a.y) * math.pi / 180
   local a = math.sin(diffLat / 2) * math.sin(diffLat / 2) + math.cos(lat1Rad) * math.cos(lat2Rad) * math.sin(diffLon / 2) * math.sin(diffLon / 2)
   local c = 2 * math.atan(math.sqrt(a), math.sqrt(1 - a))
   local distance = earthRadius * c
   return distance
end
local function file_write()
   local file = io.open("mission.waypoints","a")
   local loce = ahrs:get_home()
   if loce ~= nil then
      file:write(string.format("QGC WPL 110\n0   0   0   16   0.000000    0.000000    0.000000    0.000000    %.6f    %.6f    %.6f   1\n1   0   3   16   0.000000    0.000000    0.000000    0.000000    %.6f    %.6f    100.000000   1",loce:lat(),loce:lng(),loce:alt(),mtargetloc[1],mtargetloc[2])) --高度待定
      file:close()
   end
end
local function read_mission(file_name) --从文件中读取航点
   -- Open file
   file = assert(io.open(file_name), 'Could not open :' .. file_name)
   -- check header
   assert(string.find(file:read('l'),'QGC WPL 110') == 1, file_name .. ': incorrect format')
   -- clear any existing mission
   assert(mission:clear(), 'Could not clear current mission')
   -- read each line and write to mission
   local item = mavlink_mission_item_int_t()
   local index = 0
   local fail = false
   while true and not fail do
      local data = {}
      local line = file:read()
      if not line then
         break
      end
      local ret, _, seq, curr, frame, cmd, p1, p2, p3, p4, x, y, z, autocont = string.find(line, "^(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+([-.%d]+)%s+([-.%d]+)%s+([-.%d]+)%s+([-.%d]+)%s+([-.%d]+)%s+([-.%d]+)%s+([-.%d]+)%s+(%d+)")
      if not ret then
         fail = true
         break
      end
      if tonumber(seq) ~= index then
         fail = true
         break
      end
      item:seq(tonumber(seq))
      item:frame(tonumber(frame))
      item:command(tonumber(cmd))
      item:param1(tonumber(p1))
      item:param2(tonumber(p2))
      item:param3(tonumber(p3))
      item:param4(tonumber(p4))
      if mission:cmd_has_location(tonumber(cmd)) then
         item:x(math.floor(tonumber(x)*10^7))
         item:y(math.floor(tonumber(y)*10^7))
      else
         item:x(math.floor(tonumber(x)))
         item:y(math.floor(tonumber(y)))
      end
      item:z(tonumber(z))
      if not mission:set_item(index,item) then
         mission:clear() -- clear part loaded mission
         fail = true
         break
      end
      index = index + 1
   end
   if fail then
      mission:clear()  --clear anything already loaded
      error(string.format('failed to load mission at seq num %u', index))
   end
   gcs:send_text(0, string.format("Loaded %u mission items", index))
end
function update()
   if param:get("TARGET_GET") == 1 then
      mtargetloc = {param:get("TARGET_LAT"),param:get("TARGET_LNG")} --{纬度,经度}
   else
      return update,1000
   end
   control_exchange()
   local loc = ahrs:get_position()
   local distance
   distance = haversineDistance({x = loc:lat() / 1e7,y = loc:lng() / 1e7},{x = mtargetloc[1],y = mtargetloc[2]})
   if distance < 200 then --决断距离待定
      return update,500
   end
   file_write()
   read_mission('mission.waypoints')
   --考虑在靶标后再添加一个航点
   --可能与remedy()存在冲突
   param:set_and_save("TARGET_WAYPIONT_CHANGE",1)
end
return update,5000
