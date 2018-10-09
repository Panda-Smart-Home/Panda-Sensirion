require("helper")

webserver = {}

local server

-- first alpha is upper and others are lower
local want_headers = {}
want_headers["Host"] = true
want_headers["Cookie"] = true

-- files can't be read
local denny_list = {}
denny_list["config.json"] = true

local routes = {}

local function tryFileResponse(uri)
    -- get file name
    local filename = uri:match("/(.-)%?.*") or uri:match("/(.+)")
    if filename == nil then
        return helper.notFoundResponse()
    end
    helper.log("request filename: " .. filename)
    
    -- protect private file
    if denny_list[filename] then
        return helper.badRequestResponse()
    end
    -- return file content
    local content = helper.getFile(filename)
    if content ~= nil then
        -- for css or js file
        local type = "text/html"
        if filename:find(".css") ~= nil then
            type = "text/css"
        elseif filename:find(".js") ~= nil then
            type = "application/javascript"
        end

        return helper.okResponse(content, type)
    end
    -- error response
    helper.log("file not found or can not read:" .. filename)
    return helper.notFoundResponse()
end

local function routing(method, uri, headers, body)
    helper.log("Routing ...")
    helper.log(method, uri, headers)
    helper.log(body)
    for k, route in pairs(routes) do
        if method == route.method and uri == route.uri then
            return route.action(headers, body)
        end
    end
    if method == "GET" then
        return tryFileResponse(uri)
    end
    return helper.notFoundResponse()
end

local onReceive = function(conn, playload)

    local method  = nil
    local uri     = nil
    local version = nil
    local headers_table = {}

    local request_end = playload:find("\r\n")
    local headers_end = playload:find("\r\n\r\n")

    if request_end == nil or headers_end == nil then
        conn:send(helper.badRequestResponse, function (c) c:close() end)
        return nil
    end

    local request = playload:sub(1, request_end - 1)
    local headers = playload:sub(request_end + 2, headers_end + 1)
    local body    = playload:sub(headers_end+4)
    -- free playload
    playload = nil

    method, uri, version = request:match("([^%s]+) ([^%s]+) ([^%s]+)")
    -- get header value to headers_table
    for line in headers:gmatch("(.-)\r\n") do
        local key
        local val
        key, val = line:match("(.-): (.+)")
        if key ~= nil and val ~= nil and want_headers[key] ~= nil then
            headers_table[key] = val
        end
    end
    -- free headers
    headers = nil
    -- send response from routing
    conn:send(routing(method, uri, headers_table, body), function (c) c:close() end)
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
            conn:on("receive", onReceive)
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

function webserver.addRoute(method, uri, action)
    local route = {}
    route.method = method
    route.uri    = uri
    route.action = action

    table.insert(routes, route)
end

function webserver.clearRoutes()
    routes = {}
end

return webserver
