require("helper")

ap = {}

local ap_tmr

local function dhcp()
    wifi.ap.dhcp.stop()
    -- start dhcp
    local config = {}
    config.start = "192.168.26.100"
    wifi.ap.dhcp.config(config)
    local status = wifi.ap.dhcp.start()
    if status then
        return true
    end
    return false
end

function ap.setTimer(input_tmr)
    ap_tmr = input_tmr
end

function ap.setup()
    -- get api config
    local config = helper.getConfig().ap
    helper.log(config)
    -- reject all client
    wifi.ap.deauth()
    -- setup ap
    local status = wifi.ap.config(config)
    -- check ap status
    if status then
        helper.log("success setup ap.")
        --set ip
        status = wifi.ap.setip({
            ip      = "192.168.26.1",
            netmask = "255.255.255.0",
            gateway = "192.168.26.1"
        })
        -- check set ip status
        if status then
            helper.log("success set ip.")
            --setup dhcp service
            status = dhcp()
            -- check dhcp status
            if status then
                helper.log("success setup dhcp.")
                -- stop timer
                if ap_tmr ~= nil then
                    ap_tmr:stop()
                end
                -- setup web server
                webserver.restart()
            else
                helper.log("fail to setup dhcp!")
            end
        else
            helper.log("fail to set ip!")
        end
    else 
        helper.log("fail to setup ap!")
    end
end

return ap
