require("helper")

webserver = {}

local server

-- first alpha is upper and others are lower
local want_headers = {}
want_headers["Host"] = true
want_headers["Cookie"] = true
want_headers["Content-Length"] = true

-- files can't be read
local denny_list = {}
denny_list["config.json"] = true
denny_list["config_back.json"] = true

local routes = {}

local function tryFileResponse(uri, conn)
    -- get file name
    local filename = uri:sub(2)
    if filename == nil then
        return helper.notFoundResponse()
    end
    helper.log("request filename: " .. filename)
    
    -- protect private file
    if denny_list[filename] then
        return helper.badRequestResponse()
    end
    -- send file content
    if file.exists(filename) then
        -- for css or js file
        local type = "text/html"
        local max_age = "0"
        if filename:find(".css") ~= nil then
            type = "text/css"
            max_age = "3600"
        elseif filename:find(".js") ~= nil then
            type = "application/javascript"
            max_age = "3600"
        end
        local fd = file.open(filename, "r")
        local send_part = function (conn)
            local part = fd:read(512)
            if part ~= nil then
                conn:send(part)
            else
                conn:close()
            end
        end
        conn:on("sent", send_part)
        conn:send(helper.okHeader(type, max_age))
        return nil
    end
    -- error response
    helper.log("file not found or can not read:" .. filename)
    return helper.notFoundResponse()
end

local function routing(method, uri, headers, body, conn)
    helper.log("Routing ...")
    helper.log(method, uri, headers)
    helper.log(body)
    for k, route in pairs(routes) do
        if method == route.method and uri == route.uri then
            if route.needLogin and not helper.isLogin(headers["Cookie"]) then
                return helper.redirectResponse("http://192.168.26.1/login.html")
            end
            return route.action(headers, body, conn)
        end
    end
    if method == "GET" then
        return tryFileResponse(uri, conn)
    end
    return helper.notFoundResponse()
end

local parseHeader = function(conn, playload)
    local request_end = playload:find("\r\n")
    local headers_end = playload:find("\r\n\r\n")

    if request_end == nil or headers_end == nil then
        conn:send(helper.badRequestResponse(), helper.closeConn)
        return nil
    end

    local request = playload:sub(1, request_end - 1)
    local headers = playload:sub(request_end + 2, headers_end + 1)
    local body    = playload:sub(headers_end+4) or ""
    -- free playload
    playload = nil

    local method, uri, version = request:match("([^%s]+) ([^%s]+) ([^%s]+)")
    --uri without query string
    uri = uri:match("(.-)%?.*") or uri
    -- get header value to headers_table
    local headers_table = {}
    for line in headers:gmatch("(.-)\r\n") do
        local key, val = line:match("(.-): (.+)")
        if key ~= nil and val ~= nil and want_headers[key] ~= nil then
            headers_table[key] = val
        end
    end
    
    local body_len = 0
    if headers_table["Content-Length"] ~= nil then
        body_len = tonumber(headers_table["Content-Length"]) or 0
    end

    return method, uri, headers_table, body, body_len
end

function webserver.start()
    if server ~= nil then
        helper.log("webserver already started!")
        return
    end

    server = net.createServer(net.TCP)
    server:listen(
        80,
        function(conn)
            local isHeader = true
            local method
            local uri
            local headers
            local body = ""
            local body_len = 0
            local response
            conn:on("receive",
                function (conn, playload)
                    if isHeader then
                        method, uri, headers, body, body_len = parseHeader(conn, playload)
                        -- free playload
                        playload = nil
                        if body_len ~= 0 and #body ~= body_len then
                            isHeader = false
                        else
                            response = routing(method, uri, headers, body, conn)
                            -- free
                            playload = nil
                            headers = nil
                            body = ""
                            if response ~= nil then
                                conn:send(response, helper.closeConn)
                            end
                        end
                    else
                        body = body .. playload
                        -- free playload
                        playload = nil
                        if #body == body_len then
                            response = routing(method, uri, headers, body, conn)
                            -- free
                            headers = nil
                            body = ""
                            if response ~= nil then
                                conn:send(response, helper.closeConn)
                            end
                        end
                    end
                end
            )
        end
    )

    if server ~= nil then
        helper.log("webserver start success.")
    else
        helper.log("fail to start webserver.")
    end
end

function webserver.stop()
    helper.log("stop webserver.")
    if server ~= nil then
        server:close()
        server = nil
    end
end

function webserver.restart()
    webserver.stop()
    webserver.start()
end

function webserver.addRoute(method, uri, needLogin, action)
    local route = {}
    route.method    = method
    route.uri       = uri
    route.needLogin = needLogin
    route.action    = action

    table.insert(routes, route)
end

function webserver.clearRoutes()
    routes = {}
end

return webserver
