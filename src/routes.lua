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

        return helper.redirectResponse("http://192.168.1.1/login.html?status=fail")
    end
)
