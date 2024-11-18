--这是投弹代码的核心，用延时法计算投弹，也是最后比赛时选择的方法
--同一个飞控上传了四个脚本，脚本之间独立运行，利用ardupilot变量进行信息交互
local function create_parameter() --创建与投弹相关的ardupilot变量，各变量作用见new_version分支的README
    local PARAM_TABLE_KEY = 100
    assert(param:add_table(PARAM_TABLE_KEY,"TARGET_",10),"Unable to add params!")
    param:add_param(PARAM_TABLE_KEY,1,"GET",0)
    param:add_param(PARAM_TABLE_KEY,5,"WAYPOINT",0)
    param:add_param(PARAM_TABLE_KEY,6,"NUM",0)
    param:add_param(PARAM_TABLE_KEY,7,"REMEDY",0)
    param:add_param(PARAM_TABLE_KEY,8,"AUTO",0)
end
local function servo_output() --控制舵机输出
    local servo_output_function = 0
	SRV_Channels:set_output_pwm(servo_output_function, 1900) --控制function为0的pwm输出为1900(舵机处于投弹状态)，舵机的function值在ardupilot变量里设置
	gcs:send_text(6, "channel5 output.")
    return true
end
local delay = 0 --延迟计数器
local lastdis = {10000,10000,10000} --记录飞机最近三个距离数据
local remedy_drop = 0 --紧急投弹标识，变量为3执行紧急投弹
local function remedy() --紧急投弹
    if lastdis[1] < lastdis[2] and lastdis[2] < lastdis[3] and remain_out <= 20 then --当飞机已经距离靶标不足20米，且最近三个距离越来越远，开始紧急投弹
        remedy_drop = 3
        gcs:send_text(0,"Remedy Drop")
    end
end
local function target_location() --标靶信息传入模块
    if param:get("TARGET_GET") == 1 then
        local target_num = param:get("TARGET_NUM")
        if target_num == 1 then
            itargetloc = {31.8569994,106.8963264} --{纬度,经度}
        elseif target_num == 2 then
            itargetloc = {31.8568510,106.8964598}
        elseif target_num == 3 then
            itargetloc = {31.8569945,106.8965299}
        end
        return true
    else
        return false
    end
end
local function wait_for_waypoint_change() --等待飞机从盘旋状态改出
    if param:get("TARGET_WAYPOINT") == 1 then
        return true
    else
        return false
    end
end
local function vec_correction(init_velocity,t_in) --速度修正
    return init_velocity - 1.6 * 1.3 * init_velocity * init_velocity * t_in / 700
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
    local velocity_vec = ahrs:groundspeed_vector()
    local loch = ahrs:get_position()
    local locs = ahrs:get_position() --调用飞控API的代码
    if velocity_vec == nil or loch == nil or locs == nil then --防御性代码，从飞控调用的很多数据很容易出现nil值使程序出错
        return false
    end
    loch:change_alt_frame(1) --将高度数据改为相对高度
    local relative_height = loch:alt() / 100
    if relative_height <= 0 or velocity_vec:length() < 2 then --防御性代码，防止飞机在地面上接近或小于0的高度、速度数据使程序报错
        return false
    end
    local g = 9.7913 --成都重力加速度
    local a = g - 1.6 * 1.3 * g * relative_height / 1400 --近似下落加速度
    local time = math.sqrt(2 * relative_height / a) --投弹的近似数学模型
    local xoff = time * vec_correction(velocity_vec:length(),time) * velocity_vec:x() / velocity_vec:length()
    local yoff = time * vec_correction(velocity_vec:length(),time) * velocity_vec:y() / velocity_vec:length()
    locs:offset(xoff,yoff)
    local remaining_distance --如果现在投弹,落点与标靶的距离
    remaining_distance = haversineDistance({x = locs:lat() / 1e7,y = locs:lng() / 1e7},{x = itargetloc[1],y = itargetloc[2]}) + velocity_vec:length() * (0.05 / 2 + 0.15) --距离修正
    remain_out = remaining_distance --将当前距离复制一份到global
    gcs:send_text(6,string.format("Remaning distance:%f",remaining_distance))
    lastdis[1] = lastdis[2]
    lastdis[2] = lastdis[3]
    lastdis[3] = remaining_distance --记录最近的距离数据
    if delay >= 1 then --延迟投弹，当距离10m时倒计时4*50ms后投弹
        if delay >= 4 then
            gcs:send_text(0,"delay finished!")
            return true
        else
            delay = delay + 1
            gcs:send_text(0,"delaying")
            return false
        end
    end
    if math.abs(remaining_distance) < 10 then --延迟开始距离
        delay = 1
        return false
    else
        return false
    end
end
local target_get = false --记录是否收到标靶坐标
local waypoint_change = false --记录飞机是否直线飞行
function update()
    if param:get("TARGET_GET") == nil then
        create_parameter()
    end
    if target_location() == true then --判断是否收到标靶坐标
        if target_get == false then
            gcs:send_text(6,string.format("Recieve target location:%.6f,%.6f",itargetloc[1],itargetloc[2])) --用ardupilot变量交换信息
            target_get = true
        end
        if wait_for_waypoint_change() == true then --判断飞机是否直线飞行
            if waypoint_change == false then
                gcs:send_text(6,"Waypoint changed,ready to drop")
                waypoint_change = true
            end
            local time_to_drop = false
            if remedy_drop == 0 then
                time_to_drop = dropping_calculation() --调用投弹计算函数
            end
            remedy()
            if time_to_drop == true or remedy_drop == 3 then --当投弹计算函数输出为true或进入紧急投弹时执行投弹
                servo_output() --控制舵机执行投弹操作
                gcs:send_text(6,"Dropping complete!")
                param:set_and_save("TARGET_GET",0)
                param:set_and_save("TARGET_WAYPOINT",0)
                param:set_and_save("TARGET_AUTO",0) --变量重置
            else
                return update,50 --计算间隔毫秒数
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
