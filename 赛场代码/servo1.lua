--此脚本用于在飞机准备起飞时锁定投弹舵机
function update()
    if vehicle:get_mode() == 5 then --当飞行模式为FBWA时锁定舵机
        local servo_output_function = 0
	    SRV_Channels:set_output_pwm(servo_output_function, 1170)
        gcs:send_text(0,"servo locked")
    end
    return update,1000
end
return update,1000
