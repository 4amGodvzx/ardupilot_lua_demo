function update()
    local file = io.open("output.txt","a")
    local pri_sensor = gps:primary_sensor()
    local loc = gps:location(pri_sensor)
    local loch = ahrs:get_position()
    if loch ~= nil and loc ~= nil then
        loch:change_alt_frame(1)
        loc:change_alt_frame(1)
        file:write(string.format("GPS: lat:%f,lng:%f,alt:%.2f,AHRS: lat:%f,lng:%f,alt:%.2f\n",loc:lat()/1e7,loc:lng()/1e7,loc:alt()/100,loch:lat()/1e7,loch:lng()/1e7,loch:alt()/100))
    end
    file:close()
    return update,500
end
return update,1000