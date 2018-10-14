require("helper")

sta = {}

local tmr_id = 1

local change = true

function sta.setTimerId(input_tmr_id)
    tmr_id = input_tmr_id
end

function sta.setChange(val)
    change = val
end

function sta.setup()
    if  change then
        wifi.sta.config(helper.getConfig().sta)
        change = false
    elseif wifi.sta.getip() ~= nil then
        tmr.stop(tmr_id)
        helper.log("sta ip :" .. wifi.sta.getip())
    end
end

return sta
