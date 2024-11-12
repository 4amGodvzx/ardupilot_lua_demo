function update()
    if vehicle:get_mode() == 5 then
        local servo_output_function = 0
	    SRV_Channels:set_output_pwm(servo_output_function, 1170)
        gcs:send_text(0,"servo locked")
    end
    return update,1000
end
return update,1000