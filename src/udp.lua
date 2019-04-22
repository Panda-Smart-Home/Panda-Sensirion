require("helper")

udp = {}

local socket = nil
local master_ip = nil
local switch_pin = nil
local live_count = 3

function udp.setSwitchPin(pin)
    switch_pin = pin
end

local function onReceive(s, playload, port, ip)
    if master_ip ~= nil and ip ~= master_ip then
        return nil
    end

    local data, mark = playload:match("^(.-)|(.-)$");
    -- free playload
    playload = nil

    -- ignore bad request
    if data == nil or mark == nil then
        return nil
    end

    -- ignore request without handshake
    if master_ip == nil and data ~= "master" then
        return nil
    end

    -- set master live
    live_count = 3

    local response
    if data == "master" then

        master_ip = ip
        response = "online"

    elseif data == "status" then

        if gpio.read(switch_pin) == 1 then
            response = "on"
        else
            response = "off"
        end

    elseif data == "on" then

        gpio.mode(switch_pin, gpio.OUTPUT)
        gpio.write(switch_pin, gpio.HIGH)
        if gpio.read(switch_pin) == 1 then
            response = "ok"
        else
            response = "fail"
        end

    elseif data == "off" then

        gpio.mode(switch_pin, gpio.OUTPUT)
        gpio.write(switch_pin, gpio.LOW)
        if gpio.read(switch_pin) == 0 then
            response = "ok"
        else
            response = "fail"
        end

    else
        return nil
    end

    s:send(9527, ip, mark .. "|" ..helper.getConfig().id .. "|" .. response)
end

function udp.reset()
    if socket ~= nil then
        socket:close()
        socket = nil
    end
    master_ip = nil
    live_count = 3
end

function udp.setup()
    if wifi.sta.getip() == nil then
        udp.reset()
        return nil
    end
    if socket == nil then
        udp.reset()
        socket = net.createUDPSocket()
        socket:listen(9527)
        socket:on("receive", onReceive)
    end
    if master_ip == nil then
        socket:send(9527, wifi.sta.getbroadcast(), "alive|" .. helper.getConfig().id .. "|" .. helper.getConfig().type)
    else
        live_count = live_count - 1
        if live_count == 0 then
            master_ip = nil
            live_count = 3
        end
    end
end

return udp
