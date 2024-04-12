local function target_location() --标靶信息传入模块(待定)
    itargetloc = {0,0,0} --target_location{纬度,经度,海拔}(要确定海拔的参考系)
    return true
end
local function wait_for_waypoint_change() --等待飞机直线飞行(待定)
    return true
end
local function unit_conversion(pos1,pos2) --经纬度换算
    local upos1 = {math.rad(pos1[1]/1e7),math.rad(pos1[2]/1e7)}
    local upos2 = {math.rad(pos2[1]/1e7),math.rad(pos2[2]/1e7)}
    local r = 6371393 --地球半径
    local udistance = r * math.acos(math.sin(upos1[1]) * math.sin(upos2[1]) + math.cos(upos1[1]) * math.cos(upos2[1]) * math.cos(upos1[2] - upos2[2])) --换算公式
    return udistance
end
local function dropping_calculation() --投弹计算
    local loc = ahrs:get_position() --(获取位置与速度信息有AHRS和GPS两种方案)
    local velocity_vec = ahrs:groundspeed_vector()
    if loc == nil or velocity_vec == nil then
        return false
    end
    local distance = unit_conversion({loc:lat(),loc:lng()},{itargetloc[1],itargetloc[2]})
    local relative_height = (loc:alt() - itargetloc[3])/100
    local velocity = velocity_vec:length()
    local displacement
    local g = 9.8
    local remaining_distance
    displacement = velocity * math.sqrt(2 * relative_height / g) --使用理想状态下的平抛运动计算
    remaining_distance = distance - displacement
    gcs:send_text(6,string.format("Remaing distance:%f",remaining_distance))
    if math.abs(remaining_distance) < 3 then --投弹决策范围3米
        return true
    else
        return false
    end
end
local target_get = false --记录是否收到标靶坐标
local waypoint_change = false --记录飞机是否直线飞行
function update()
    if target_location() == true then --判断是否收到标靶坐标
        if target_get == false then
            gcs:send_text(6,string.format("Recieve target location:%f,%f,%f",itargetloc[1],itargetloc[2],itargetloc[3]))
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
                --servo.set_output(function_number,PWM) --控制舵机执行投弹操作(待定)
                gcs:send_text(6,"Dropping complete!")
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