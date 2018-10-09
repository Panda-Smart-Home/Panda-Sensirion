require("helper")
require("webserver")
require("ap")

-- require routes
dofile("routes.lua")
-- set wifi mode
wifi.setmode(wifi.STATIONAP)

--set timer id and ms for each moudle
tmr_tab = {}
tmr_tab.ap = {id=0, ms=3000}

-- set ap timer, it will run forever until ap setup success
ap.setTimerId(tmr_tab.ap.id)
tmr.alarm(
    tmr_tab.ap.id,
    tmr_tab.ap.ms,
    tmr.ALARM_AUTO,
    ap.setup
)

ap_clients = {}

ap_staconnected = function(T)
    helper.log("AP - STATION CONNECTED" .. "\n\tMAC: " .. T.MAC .."\n\tAID: " .. T.AID)
    ap_clients = wifi.ap.getclient()
    helper.log("now clients:")
    helper.log(ap_clients)
end

wifi.eventmon.register(wifi.eventmon.AP_STACONNECTED, ap_staconnected)
