helper = {}

local config = nil

function helper.getConfig(from_file)
    from_file = from_file or false

    if config ~= nil and from_file == false then
        return config
    end

    local fd = file.open("config.json", "r")
    if fd then
        -- read the config file content
        -- max 4096 bytes
        local config = fd:read(4096)
        -- close file
        fd:close();fd = nil
        -- decode the json content to table and return
        config = sjson.decode(config)
        return config
    end

    return nil
end

function helper.setConfig(config)
    local fd = file.open("config.json", "w")
    if fd then
        local ok
        local json
        -- encode config table to json
        ok, json = pcall(sjson.encode, config)
        if not ok then return nil end
        -- write config json to file
        ok = fd:write(json)
        -- close file
        fd:close();fd = nil
        -- load new config
        if ok then
            helper.getConfig(true)
        end
        return ok
    end

    return nil
end

function helper.log(...)
    for i, info in ipairs{...} do
        local info_type = type(info)
        if info_type == "table" then
            for k, v in pairs(info) do
                print(k, v)
            end
        else
            print("mem: " .. tostring(node.heap()) .. " | " .. info)
        end
    end
end

function helper.isLogin(table, cookie)
    if cookie == nil then
        return false
    end
    
    cookie = cookie:match("PANDA_ID=(.+)")
    if cookie ~= nil and table[cookie] ~= nil then
        return true, cookie
    end

    return false
end

function helper.cookie(len)
    len = len or 32

    local val = ""
    for i=1, len do  
        val = val .. string.char(node.random(65, 90))
    end

    return val
end

function helper.okHeader(content_type, max_age, cookie)
    content_type = content_type or "text/html"
    max_age = max_age or 0
    if cookie then
        cookie = "\r\nSet-Cookie: PANDA_ID=" .. cookie
    else
        cookie = ""
    end
    local response = "HTTP/1.1 200 OK\r\nConnection: close\r\nContent-Type: %s\r\nCache-Control: max-age=%s%s\r\n\r\n"
    response = string.format(response, content_type, max_age, cookie)
    return response
end

function helper.redirectResponse(url, cookie)
    if cookie then
        cookie = "\r\nSet-Cookie: PANDA_ID=" .. cookie
    else
        cookie = ""
    end
    local response = "HTTP/1.0 302 Moved Temporarily\r\nLocation: %s%s\r\n\r\n"
    response = string.format(response, url, cookie)
    return response
end

function helper.badRequestResponse()
    return "HTTP/1.0 400 Bad Request\r\n\r\n<h1>400 Bad Request!</h1>"
end

function helper.notFoundResponse()
    return "HTTP/1.0 404 Not Found\r\n\r\n<h1>404 Not Found!</h1>"
end

return helper
