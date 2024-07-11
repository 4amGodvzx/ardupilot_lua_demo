function update()
    local index = mission:get_current_nav_index()
    if index ~= nil then
        if param:get("TARGET_GET") == 1 then
            if index == 5 then
                param:set_and_save("TARGET_WAYPOINT",1)
            end
        end
        if param:get("TARGET_NUM") == 5 then
            if index == 6 then
                param:set_and_save("TARGET_REMEDY",1)
            end
        end
    end
    return update,1000
end
return update,1000