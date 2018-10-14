require("helper")
require("ap")
require("sta")
require("webserver")

-- set wifi mode
wifi.setmode(wifi.STATIONAP)
-- set egc mode
node.egc.setmode(node.egc.ALWAYS, 4096)

--set timer id and ms for each moudle
tmr_tab = {}
tmr_tab.ap     = {id=0, ms=3000}
tmr_tab.sta    = {id=1, ms=5000}
tmr_tab.cookie = {id=2, ms=60000}

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

-- set cookie timer
tmr.alarm(
    tmr_tab.cookie.id,
    tmr_tab.cookie.ms,
    tmr.ALARM_AUTO,
    helper.cookieTimer
)

-- require routes
dofile("routes.lua")

-- ap_clients = {}

-- ap_staconnected = function(T)
--     helper.log("AP - STATION CONNECTED" .. "\n\tMAC: " .. T.MAC .."\n\tAID: " .. T.AID)
--     ap_clients = wifi.ap.getclient()
--     helper.log("now clients:")
--     helper.log(ap_clients)
-- end

-- wifi.eventmon.register(wifi.eventmon.AP_STACONNECTED, ap_staconnected)
