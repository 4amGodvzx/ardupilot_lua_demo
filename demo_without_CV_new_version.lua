local function create_parameter()
    local PARAM_TABLE_KEY = 100
    assert(param:add_table(PARAM_TABLE_KEY,"TARGET_",10),"Unable to add params!")
    param:add_param(PARAM_TABLE_KEY,1,"GET",0)
    param:add_param(PARAM_TABLE_KEY,2,"LAT",0)
    param:add_param(PARAM_TABLE_KEY,3,"LNG",0)
    param:add_param(PARAM_TABLE_KEY,5,"WAYPIONT_CHANGE",0)
    param:add_param(PARAM_TABLE_KEY,6,"NUM",0)
end
local lastdis = {10000,10000,10000} --记录飞机最近三个距离数据
local function target_location() --标靶信息传入模块
    itargetloc = {-35.357954,149.167033} --{纬度,经度}
    return true
end
local function wait_for_waypoint_change() --等待飞机直线飞行
    return true
end
local function error_correction(init_velocity) --速度误差修正函数,用于处理飞机速度与水瓶速度的统计关系(待定)
    return init_velocity
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
local function dropping_calculation() --投弹计算
    local pri_sensor = gps:primary_sensor()
    local velocity_vec = gps:velocity(pri_sensor)
    local loch = ahrs:get_position()
    local locs = ahrs:get_position()
    if velocity_vec == nil or loch == nil or locs == nil then
        return false
    end
    loch:change_alt_frame(1)
    local relative_height = loch:alt() / 100
    if relative_height <= 0 or velocity_vec:length() < 0 then
        return false
    end
    local g = 9.7997 --河北石家庄重力加速度
    local time = math.sqrt(2 * relative_height / g)
    local xoff = time * error_correction(velocity_vec:x())
    local yoff = time * error_correction(velocity_vec:y())
    locs:offset(xoff,yoff)
    local remaining_distance --如果现在投弹,落点与标靶的距离
    remaining_distance = haversineDistance({x = locs:lat() / 1e7,y = locs:lng() / 1e7},{x = itargetloc[1],y = itargetloc[2]})
    gcs:send_text(6,string.format("Remaning distance:%f",remaining_distance))
    lastdis[1] = lastdis[2]
    lastdis[2] = lastdis[3]
    lastdis[3] = remaining_distance
    if math.abs(remaining_distance) < 3 then --投弹决策范围3米
        return true
    else
        return false
    end
end
local function remedy()
    if lastdis[1] < lastdis[2] and lastdis[2] < lastdis[3] then
        return true
    end
end
local function servo_output() --控制舵机函数
    return true
end
local target_get = false --记录是否收到标靶坐标
local waypoint_change = false --记录飞机是否直线飞行
function update()
    if param:get("TARGET_GET") == nil then
        create_parameter()
    end
    if target_get == false then
        param:set_and_save("TARGET_GET",0)
        param:set_and_save("WAYPIONT_CHANGE",0)
    end
    if target_location() == true then --判断是否收到标靶坐标
        if target_get == false then
            gcs:send_text(6,string.format("Recieve target location:%f,%f",itargetloc[1],itargetloc[2]))
            target_get = true
        end
        if wait_for_waypoint_change() == true then --判断飞机是否直线飞行
            if waypoint_change == false then
                gcs:send_text(6,"Waypoint changed,ready to drop")
                waypoint_change = true
            end
            local time_to_drop = false
            time_to_drop = dropping_calculation()
            remedy_drop = remedy()
            if time_to_drop == true or remedy_drop == true then
                servo_output() --控制舵机执行投弹操作
                gcs:send_text(6,"Dropping complete!")
                param:set_and_save("TARGET_GET",0)
                param:set_and_save("WAYPIONT_CHANGE",0)
            else
                return update,300 --计算间隔毫秒数
            end
        else
            gcs:send_text(6,"Wait for waypoint change")
            return update,3000
        end
    else
        gcs:send_text(6,"Wait for target location")
        return update,2000
    end
end
return update,1000
