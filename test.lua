function  update()
    gcs:send_text(1,string.format("num of sensor:%f",gps:num_sensors()))
    local pri_sensor = gps:primary_sensor()
    local loc = gps:location(pri_sensor)
    local loch = ahrs:get_position()
    if loc ~= nil and loch ~= nil then
        loch:change_alt_frame(1)
        gcs:send_text(3,string.format("Recieve:%f,%f,%f",loc:lat(),loc:lng(),loch:alt()))
    end
    return update,1000
end
return update,1000
