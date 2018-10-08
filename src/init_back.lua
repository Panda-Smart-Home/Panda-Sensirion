require("helper")
require("webserver")

local cookie_table = {}

webserver.clearRoutes()

webserver.addRoute("GET", "/",
    function (headers, body)
        if helper.isLogin(cookie_table, headers["Cookie"]) then
            return helper.okResponse(helper.getFile("manage.html"))
        end
        return helper.redirectResponse("http://192.168.1.1/login.html")
    end
)

webserver.addRoute("POST", "/login",
    function (headers, body)
        local input_username
        local input_password
        
        input_username, input_password = body:match("username=([^%s]+)&password=([^%s]+)")
        helper.log("username: " .. input_username .. " password: " .. input_password)

        local username = helper.getConfig().username
        local password = helper.getConfig().password

        if username == input_username and password == input_password then
            local cookie = helper.cookie()
            helper.log("set cookie: " .. cookie)
            cookie_table[cookie] = 60
            return helper.redirectResponse("http://192.168.1.1/", cookie)
        end

        return helper.redirectResponse("http://192.168.1.1/login.html")
    end
)

setup_ap = function()
    -- get api config
    local config = helper.getConfig().ap
    helper.log(config)
    -- setup ap
    local status = wifi.ap.config(helper.getConfig().ap)
    -- check status
    if status then
        helper.log("success setup ap.")
        wifi.ap.deauth()
        tmr.stop(tmr_tab.ap.id)
        --set ip
        wifi.ap.setip({
            ip      = "192.168.1.1",
            netmask = "255.255.255.0",
            gateway = "192.168.1.1"
        })
        --start setup dhcp service
        tmr.alarm(
            tmr_tab.dhcp.id,
            tmr_tab.dhcp.ms,
            tmr.ALARM_AUTO,
            setup_dhcp
        )
        -- setup web server
        webserver.restart()
    else 
        helper.log("fail to setup ap!")
    end
end

setup_dhcp = function()
    -- make sure ap has been setup
    running, mode = tmr.state(tmr_tab.ap.id)
    if not (running == false) then
        helper.log("delay setup dhcp because ap not setup success.")
        return nil
    end
    wifi.ap.dhcp.stop()
    -- setup dhcp
    local config = {}
    config.start = "192.168.1.100"
    wifi.ap.dhcp.config(config)
    local status = wifi.ap.dhcp.start()
    -- check status
    if status then
        helper.log("success setup dhcp.")
        tmr.stop(tmr_tab.dhcp.id)
    else
        helper.log("fail to setup dhcp!")
    end
end

wifi.setmode(wifi.STATIONAP)

--set timer id and ms for each moudle
tmr_tab = {}
tmr_tab.ap   = {id=0, ms=3000}
tmr_tab.dhcp = {id=1, ms=2000}


-- set ap timer, it will run forever until ap setup success
tmr.alarm(
    tmr_tab.ap.id,
    tmr_tab.ap.ms,
    tmr.ALARM_AUTO,
    setup_ap
)

ap_clients = {}

ap_staconnected = function(T)
    helper.log("AP - STATION CONNECTED" .. "\n\tMAC: " .. T.MAC .."\n\tAID: " .. T.AID)
    ap_clients = wifi.ap.getclient()
    helper.log("now clients:")
    helper.log(ap_clients)
end

wifi.eventmon.register(wifi.eventmon.AP_STACONNECTED, ap_staconnected)
