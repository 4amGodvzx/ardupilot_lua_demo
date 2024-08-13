function  update()
    if param:get("SCR_USER1") == 1 then
        vehicle:set_mode(10)
        gcs:send_text(0,"ok")
    else
        return update,500
    end
end
return update,1000
