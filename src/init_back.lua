require("helper")
require("webserver")
require("ap")
-- set wifi mode
wifi.setmode(wifi.STATIONAP)
-- set egc mode
node.egc.setmode(node.egc.ALWAYS, 4096)

-- require routes
dofile("routes.lua")

--set timer id and ms for each moudle
tmr_tab = {}
tmr_tab.ap     = {id=0, ms=3000}
tmr_tab.cookie = {id=1, ms=60000}

-- set ap timer, it will run forever until ap setup success
ap.setTimerId(tmr_tab.ap.id)
tmr.alarm(
    tmr_tab.ap.id,
    tmr_tab.ap.ms,
    tmr.ALARM_AUTO,
    ap.setup
)

-- set cookie timer
tmr.alarm(
    tmr_tab.cookie.id,
    tmr_tab.cookie.ms,
    tmr.ALARM_AUTO,
    helper.cookieTimer
)

ap_clients = {}

ap_staconnected = function(T)
    helper.log("AP - STATION CONNECTED" .. "\n\tMAC: " .. T.MAC .."\n\tAID: " .. T.AID)
    ap_clients = wifi.ap.getclient()
    helper.log("now clients:")
    helper.log(ap_clients)
end

wifi.eventmon.register(wifi.eventmon.AP_STACONNECTED, ap_staconnected)
