if not pcall(node.flashindex("_init")) then
    tmr.alarm(
        0,
        5000,
        tmr.ALARM_AUTO,
        function ()
            node.restart()
        end
    )
    return nil
end

require("helper")
require("ap")
require("sta")
require("udp")
require("webserver")

-- close a relay
gpio.mode(7, gpio.INPUT)

-- set switch pin
switch_pin = 6

-- set wifi mode
wifi.setmode(wifi.STATIONAP)

-- set egc mode
node.egc.setmode(node.egc.ALWAYS, 4096)

--set timer id and ms for each moudle
tmr_tab = {}
tmr_tab.ap     = {id=0, ms=3000}
tmr_tab.sta    = {id=1, ms=5000}
tmr_tab.udp    = {id=2, ms=6000}
tmr_tab.cookie = {id=3, ms=60000}

-- set ap timer, it will run forever until ap setup success
ap.setTimerId(tmr_tab.ap.id)
tmr.alarm(
    tmr_tab.ap.id,
    tmr_tab.ap.ms,
    tmr.ALARM_AUTO,
    ap.setup
)

-- set sta timer, it will run forever until connect wifi success
ap.setTimerId(tmr_tab.ap.id)
tmr.alarm(
    tmr_tab.sta.id,
    tmr_tab.sta.ms,
    tmr.ALARM_AUTO,
    sta.setup
)

-- set udp serve timer
udp.setSwitchPin(switch_pin)
tmr.alarm(
    tmr_tab.udp.id,
    tmr_tab.udp.ms,
    tmr.ALARM_AUTO,
    udp.setup
)

-- set cookie timer
tmr.alarm(
    tmr_tab.cookie.id,
    tmr_tab.cookie.ms,
    tmr.ALARM_AUTO,
    helper.cookieTimer
)

-- require routes
dofile("routes.lua")
