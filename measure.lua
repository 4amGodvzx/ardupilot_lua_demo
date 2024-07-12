local last_time = 0
local update_interval = 1000  -- 设置为1秒钟

function update()
    local current_time = millis()
    local delta_time = current_time - last_time

    if last_time > 0 then
        local gps_data = gps:location()
        if gps_data then
            gcs:send_text(6, "GPS Data: lat=" .. tostring(gps_data:lat()) .. ", lon=" .. tostring(gps_data:lng()))
            gcs:send_text(6, "Time delta: " .. tostring(delta_time) .. " ms")
        end
    end

    last_time = current_time
    return update_interval  -- 设置下一次调用的时间间隔
end
