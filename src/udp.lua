require("helper")

udp = {}

local secret = nil
local socket = nil
local master_ip = nil

function udp.reset()
    local config = helper.getConfig()
    secret = crypto.toHex(crypto.hash("sha1", config.username .. config.password)):sub(1, 16)
    master_ip = nil
end

function udp.setup()
    if wifi.sta.getip() == nil then
        master_ip = nil
        secret = nil
        socket = nil
        return nil
    end
    if socket == nil then
        udp.reset()
        socket = net.createUDPSocket()
        socket:listen(9527)
        socket:on("receive",
            function(s, data, port, ip)
                s:send(port, ip, "echo: " .. data)
            end
        )
    end
    if master_ip == nil then
        helper.log("try to send", wifi.sta.getbroadcast())
        socket:send(9527, wifi.sta.getbroadcast(), helper.getConfig().id)
    end
end

return udp
