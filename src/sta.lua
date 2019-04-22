require("helper")

sta = {}

local sta_tmr

local change = true

function sta.setTimer(input_tmr)
    sta_tmr = input_tmr
end

function sta.setChange(val)
    change = val
end

function sta.setup()
    if  change then
        wifi.sta.config(helper.getConfig().sta)
        change = false
    elseif wifi.sta.getip() ~= nil then
        if sta_tmr ~= nil then
            sta_tmr:stop()
        end
        helper.log("sta ip :" .. wifi.sta.getip())
    end
end

return sta
