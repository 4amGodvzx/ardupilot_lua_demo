a=0
function  update()
    local servo_output_function = 0
    gcs:send_text(6, "wait")
    if a == 10 then
        SRV_Channels:set_output_pwm(servo_output_function, 800)
        gcs:send_text(6, "channel5 output.")
    end
    if a == 20 then
        SRV_Channels:set_output_pwm(servo_output_function, 2200)
        gcs:send_text(6, "channel5 output.")
    end
    a=a+1
    return update,1000
end
return update,1000
