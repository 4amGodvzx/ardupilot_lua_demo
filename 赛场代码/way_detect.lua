--此脚本用于判断飞机是否从RTL模式改出
function update()
    local index = mission:get_current_nav_index() --获取当前正在前往的航点编号
    if index ~= nil then
        if param:get("TARGET_GET") == 1 then
            gcs:send_text(6,string.format("index:%f",index))
            if index >= 1 then
                param:set_and_save("TARGET_WAYPOINT",1) --与核心脚本文件通讯，启动投弹
            end
        end
    end
    return update,1000
end
return update,1000
