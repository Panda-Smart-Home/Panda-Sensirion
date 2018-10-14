webserver.clearRoutes()

webserver.addRoute("GET", "/",
    function (headers, body, conn)
        if helper.isLogin(headers["Cookie"]) then
            local config = helper.getConfig();
            local time = "0"
            local switch = ""
            local hidden = ""
            if config.ap.hidden then
                hidden = "checked"
            end
            local info = {
                config.id,
                config.name,
                config.chip,
                switch,
                time,
                config.ap.ssid,
                hidden,
                config.sta.ssid,
                config.master,
                config.username
            }
            local fd = file.open("manage.html", "r")
            local rep = table.remove(info, 1)
            local s = 0
            local send_line = function (conn)
                local line = fd:readline()
                if line ~= nil then
                    if #info > 0 or rep ~= nil then
                        line, s = line:gsub("%$", rep)
                        if s > 0 then 
                            rep = table.remove(info, 1)
                        end
                    end
                    conn:send(line)
                else
                    conn:close()
                end
            end
            conn:on("sent", send_line)
            conn:send(helper.okHeader())
            return nil
        end
        return helper.redirectResponse("http://192.168.1.1/login.html")
    end
)

webserver.addRoute("GET", "/logout",
    function (headers, body)
        status, cookie = helper.isLogin(headers["Cookie"])
        if cookie ~= nil then
            helper.clearCookie(cookie)
        end
        return helper.redirectResponse("http://192.168.1.1/login.html")
    end
)

webserver.addRoute("POST", "/login",
    function (headers, body)
        local input_username
        local input_password
        
        input_username, input_password = body:match("username=([^%s]+)&password=([^%s]+)")

        local username = helper.getConfig().username
        local password = helper.getConfig().password

        if username == input_username and password == input_password then
            local cookie = helper.setCookie()
            helper.log("set cookie: " .. cookie)
            return helper.redirectResponse("http://192.168.1.1/", cookie)
        end

        return helper.redirectResponse("http://192.168.1.1/login.html?status=fail")
    end
)

webserver.addRoute("POST", "/config/ap",
    function (headers, body)
        if not helper.isLogin(headers["Cookie"]) then
            return helper.badRequestResponse()
        end

        local ssid
        local pwd
        local hidden
        ssid, pwd = body:match("ssid=([^%s]+)&pwd=([^%s&]+)")
        hidden = body:match("[^%s]+&hidden=([^%s]+)")
        if hidden ~= "on" then
            hidden = false
        else
            hidden = true
        end
        helper.log("ap ssid: " .. ssid .. " pwd: " .. pwd .. " hidden: ")
        helper.log(hidden)

        if helper.minString(ssid) and helper.minString(pwd, 8) then
            local config = helper.getConfig()
            config.ap["ssid"]   = ssid
            config.ap["pwd"]    = pwd
            config.ap["hidden"] = hidden
            
            if helper.setConfig(config) then
                tmr.start(tmr_tab.ap.id)
                return helper.redirectResponse("http://192.168.1.1/?ap=ok")
            end
        end

        return helper.redirectResponse("http://192.168.1.1/?ap=fail")
    end
)

webserver.addRoute("POST", "/config/sta",
    function (headers, body)
        if not helper.isLogin(headers["Cookie"]) then
            return helper.badRequestResponse()
        end

        local ssid
        local pwd
        local mac
        ssid, pwd, mac = body:match("ssid=([^%s]+)&pwd=([^%s&]+)&mac=([^%s]+)")
        helper.log("sta ssid: " .. ssid .. " pwd: " .. pwd .. " mac: " .. mac)

        local config = helper.getConfig()
        config.sta["ssid"] = ssid
        config.sta["pwd"]  = pwd
        config["master"]   = mac

        if helper.setConfig(config) then
            sta.setChange(true)
            tmr.start(tmr_tab.sta.id)
            return helper.redirectResponse("http://192.168.1.1/?sta=ok")
        end

        return helper.redirectResponse("http://192.168.1.1/?sta=fail")
    end
)

webserver.addRoute("POST", "/config/user",
    function (headers, body)
        if not helper.isLogin(headers["Cookie"]) then
            return helper.badRequestResponse()
        end

        local old_username
        local old_password
        local new_username
        local new_password

        old_username, old_password, new_username, new_password = body:match("old_username=([^%s]+)&old_password=([^%s]+)&new_username=([^%s]+)&new_password=([^%s]+)")
        if (old_username ~= helper.getConfig().username) 
            or (old_password ~= helper.getConfig().password) 
            or not helper.minString(new_username)
            or not helper.minString(new_password, 8)
        then
            return helper.redirectResponse("http://192.168.1.1/?user=fail")
        end

        helper.log("new username: " .. new_username .. " new_password: " .. new_password)

        local config = helper.getConfig()
        config.username = new_username
        config.password = new_password
        if helper.setConfig(config) then
            return helper.redirectResponse("http://192.168.1.1/?user=ok")
        end
        return helper.redirectResponse("http://192.168.1.1/?user=fail")
    end
)
