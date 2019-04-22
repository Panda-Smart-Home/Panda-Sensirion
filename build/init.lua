if not pcall(node.flashindex("_init")) then
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
tmr_tab.ap     = tmr.create()
tmr_tab.sta    = tmr.create()
tmr_tab.udp    = tmr.create()
tmr_tab.cookie = tmr.create()

-- set ap timer, it will run forever until ap setup success
ap.setTimer(tmr_tab.ap)
tmr_tab.ap:alarm(
    3000,
    tmr.ALARM_AUTO,
    ap.setup
)

-- set sta timer, it will run forever until connect wifi success
sta.setTimer(tmr_tab.sta)
tmr_tab.sta:alarm(
    5000,
    tmr.ALARM_AUTO,
    sta.setup
)

-- set udp serve timer
udp.setSwitchPin(switch_pin)
tmr_tab.udp:alarm(
    6000,
    tmr.ALARM_AUTO,
    udp.setup
)

-- set cookie timer
tmr_tab.cookie:alarm(
    60000,
    tmr.ALARM_AUTO,
    helper.cookieTimer
)

-- require routes
dofile("routes.lua")
