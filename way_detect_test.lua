function update()
    local index = mission:get_current_nav_index()
    if index ~= nil then
        gcs:send_text(0,string.format("index:%f",index))
        if index >= 18 then
            param:set_and_save("TARGET_WAYPOINT",1)
        else
            return update,1000
        end
    end
end
return update,1000