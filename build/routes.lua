webserver.clearRoutes()

webserver.addRoute("GET", "/", true,
    function (headers, body, conn)
        local config = helper.getConfig();
        local switch = ""
        if gpio.read(switch_pin) == 1 then
            switch = "checked"
        end
        local hidden = ""
        if config.ap.hidden then
            hidden = "checked"
        end
        local sta_ip = wifi.sta.getip() or "0.0.0.0"
        local info = {
            config.id,
            config.name,
            config.chip,
            switch,
            config.ap.ssid,
            hidden,
            sta_ip,
            config.sta.ssid,
            config.username
        }
        -- free config
        config = nil
        local fd = file.open("manage.html", "r")
        local rep = table.remove(info, 1)
        local pos = 0
        local send_line = function (conn)
            local line
            local chunk = ""
            for i=1, 5 do
                line = fd:readline()
                if line ~= nil then
                    if #info > 0 or rep ~= nil then
                        line, pos = line:gsub("%$", rep)
                        if pos > 0 then 
                            rep = table.remove(info, 1)
                        end
                    end
                    chunk = chunk .. line
                elseif chunk == "" then
                    fd:close()
                    fd = nil
                    info = nil
                    conn:close()
                    return nil
                end
            end
            conn:send(chunk)
        end
        conn:on("sent", send_line)
        conn:send(helper.okHeader())
        return nil
    end
)

webserver.addRoute("GET", "/logout", false,
    function (headers, body)
        local status, cookie = helper.isLogin(headers["Cookie"])
        if cookie ~= nil then
            helper.clearCookie(cookie)
        end
        return helper.redirectResponse("http://192.168.26.1/login.html")
    end
)

webserver.addRoute("POST", "/login", false,
    function (headers, body)
        local input_username, input_password = body:match("username=([^%s]+)&password=([^%s]+)")
        local username = helper.getConfig().username
        local password = helper.getConfig().password

        if username == input_username and password == input_password then
            local cookie = helper.setCookie()
            helper.log("set cookie: " .. cookie)
            return helper.redirectResponse("http://192.168.26.1/", cookie)
        end

        return helper.redirectResponse("http://192.168.26.1/login.html?status=fail")
    end
)

webserver.addRoute("GET", "/control/on", true,
    function (headers, body)
        gpio.mode(switch_pin, gpio.OUTPUT)
        gpio.write(switch_pin, gpio.HIGH)
        if gpio.read(switch_pin) == 1 then
            return helper.okHeader() .. "OK"
        end
        return helper.badRequestResponse()
    end
)

webserver.addRoute("GET", "/control/off", true,
    function (headers, body)
        gpio.mode(switch_pin, gpio.OUTPUT)
        gpio.write(switch_pin, gpio.LOW)
        if gpio.read(switch_pin) == 0 then
            return helper.okHeader() .. "OK"
        end
        return helper.badRequestResponse()
    end
)

webserver.addRoute("POST", "/config/ap", true,
    function (headers, body)
        local ssid, pwd = body:match("ssid=([^%s]+)&pwd=([^%s&]+)")
        local hidden = body:match("[^%s]+&hidden=([^%s]+)")
        if hidden ~= "on" then
            hidden = false
        else
            hidden = true
        end

        if helper.minString(ssid) and helper.minString(pwd, 8) then
            local config = helper.getConfig()
            config.ap["ssid"]   = ssid
            config.ap["pwd"]    = pwd
            config.ap["hidden"] = hidden
            
            if helper.setConfig(config) then
                tmr_tab.ap:start()
                return helper.redirectResponse("http://192.168.26.1/?ap=ok")
            end
        end

        return helper.redirectResponse("http://192.168.26.1/?ap=fail")
    end
)

webserver.addRoute("POST", "/config/sta", true,
    function (headers, body)
        local ssid, pwd = body:match("ssid=([^%s]+)&pwd=([^%s&]+)")

        local config = helper.getConfig()
        config.sta["ssid"] = ssid
        config.sta["pwd"]  = pwd

        if helper.setConfig(config) then
            sta.setChange(true)
            tmr_tab.sta:start()
            udp.reset()
            return helper.redirectResponse("http://192.168.26.1/?sta=ok")
        end

        return helper.redirectResponse("http://192.168.26.1/?sta=fail")
    end
)

webserver.addRoute("POST", "/config/user", true,
    function (headers, body)
        local old_username, old_password, new_username, new_password = body:match("old_username=([^%s]+)&old_password=([^%s]+)&new_username=([^%s]+)&new_password=([^%s]+)")
        if (old_username ~= helper.getConfig().username)
            or (old_password ~= helper.getConfig().password)
            or not helper.minString(new_username)
            or not helper.minString(new_password, 8)
        then
            return helper.redirectResponse("http://192.168.26.1/?user=fail")
        end

        local config = helper.getConfig()
        config.username = new_username
        config.password = new_password
        if helper.setConfig(config) then
            return helper.redirectResponse("http://192.168.26.1/?user=ok")
        end
        return helper.redirectResponse("http://192.168.26.1/?user=fail")
    end
)

webserver.addRoute("GET", "/reboot", true,
    function (headers, body, conn)
        conn:send(helper.okHeader() .. "OK",
            function (conn)
                conn:close()
                node.restart()
            end
        )
    end
)

webserver.addRoute("GET", "/reset", true,
    function (headers, body, conn)
        if helper.resetConfig() then 
            conn:send(helper.okHeader() .. "OK",
                function (conn)
                    conn:close()
                    node.restart()
                end
            )
        else
            return helper.badRequestResponse()
        end
    end
)
