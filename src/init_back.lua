if not pcall(node.flashindex("_init")) then
    return nil;
end

require("helper")
require("ap")
require("sta")
require("udp")
require("webserver")

-- set dht11 pin
dht_pin = 4
dht_info = {}
dht_info.temp = nil
dht_info.humi = nil

-- set wifi mode
wifi.setmode(wifi.STATIONAP)

-- set egc mode
node.egc.setmode(node.egc.ALWAYS, 4096)

--set timer id and ms for each moudle
tmr_tab = {}
tmr_tab.ap     = tmr.create()
tmr_tab.sta    = tmr.create()
tmr_tab.dht    = tmr.create()
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

-- get temperature and humidity
tmr_tab.dht:alarm(
    1000,
    tmr.ALARM_AUTO,
    function()
        status, temp, humi, temp_dec, humi_dec = dht.read(dht_pin)
        if status == dht.OK then
            print("DHT Temperature:"..temp..";".."Humidity:"..humi)
            dht_info.temp = temp
            dht_info.humi = humi
        elseif status == dht.ERROR_CHECKSUM then
            print( "DHT Checksum error." )
        elseif status == dht.ERROR_TIMEOUT then
            print( "DHT timed out." )
        end
    end
)

-- set udp serve timer
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
