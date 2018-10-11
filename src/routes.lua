webserver.clearRoutes()

webserver.addRoute("GET", "/",
    function (headers, body, conn)
        if helper.isLogin(headers["Cookie"]) then
            local config = helper.getConfig();
            local time = "0"
            local switch = ""
            local info = {
                config.id,
                config.name,
                config.chip,
                switch,
                time,
                config.ap.ssid,
                config.ap.hidden,
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
        helper.log("username: " .. input_username .. " password: " .. input_password)

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
