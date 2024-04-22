local function create_parameter()
    local PARAM_TABLE_KEY = 100
    assert(param:add_table(PARAM_TABLE_KEY,"TARGET_",10),"Unable to add params!")
    param:add_param(PARAM_TABLE_KEY,1,"GET",0)
    param:add_param(PARAM_TABLE_KEY,2,"LAT",0)
    param:add_param(PARAM_TABLE_KEY,3,"LNG",0)
    param:add_param(PARAM_TABLE_KEY,5,"WAYPIONT_CHANGE",0)
end
local function target_location() --标靶信息传入模块
    if param:get("TARGET_GET") == 1 then
        itargetloc = {param:get("TARGET_LAT"),param:get("TARGET_LNG")} --{纬度,经度}
        return true
    else
        return false
    end
end
local function wait_for_waypoint_change() --等待飞机直线飞行
    if param:get("TARGET_WAYPOINT_CHANGE") == 1 then
        return true
    else
        return false
    end
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
    local loc = gps:location(pri_sensor) --(GPS获取位置与速度信息)
    local velocity_vec = gps:velocity(pri_sensor)
    local loch = ahrs:get_position()
    if loc == nil or velocity_vec == nil or loch ==nil then
        return false
    end
    loch:change_alt_frame(1)
    local distance = haversineDistance({x = loc:lat() / 1e7,y = loc:lng() / 1e7},{x = itargetloc[1],y = itargetloc[2]})
    local relative_height = loch:alt() / 100
    if relative_height < 0 then
        return false
    end
    local velocity = error_correction(velocity_vec:length())
    local displacement
    local g = 9.7997 --河北石家庄重力加速度
    local remaining_distance --如果现在投弹,落点与标靶的距离
    displacement = velocity * math.sqrt(2 * relative_height / g) --使用平抛运动计算
    remaining_distance = distance - displacement
    gcs:send_text(6,string.format("Remaning distance:%f",remaining_distance))
    if math.abs(remaining_distance) < 3 then --投弹决策范围3米
        return true
    else
        return false
    end
end
local function servo_output() --控制舵机函数
    local servo_output_function = 0
	SRV_Channels:set_output_pwm(servo_output_function, 2200)
	gcs:send_text(6, "channel5 output.")
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
            gcs:send_text(6,string.format("Recieve target location:%f,%f,%f",itargetloc[1],itargetloc[2]))
            target_get = true
        end
        if wait_for_waypoint_change() == true then --判断飞机是否直线飞行
            if waypoint_change == false then
                gcs:send_text(6,"Waypoint changed,ready to drop")
                waypoint_change = true
            end
            local time_to_drop = false
            time_to_drop = dropping_calculation()
            if time_to_drop == true then
                servo_output() --控制舵机执行投弹操作
                gcs:send_text(6,"Dropping complete!")
                param:set_and_save("TARGET_GET",0)
                param:set_and_save("WAYPIONT_CHANGE",0)
            else
                return update,500 --计算间隔毫秒数
            end
        else
            gcs:send_text(6,"Wait for waypoint change")
            return update,2000
        end
    else
        gcs:send_text(6,"Wait for target location")
        return update,2000
    end
end
return update,1000
