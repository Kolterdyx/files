require("table_saver")

monitor = peripheral.wrap("left")
modem = peripheral.wrap("top")
modem.open(23)
monitor.clear()

door_state = table.load("door_state.lua")


-- type to the monitor
function screen(text, x, y)
    monitor.setCursorPos(x, y)
    monitor.clearLine()
    monitor.write(text)
end

function save_door_state()
    table.save(door_state, "door_state.lua")
end

-- execute the commands recieved
function execute(cmd, args)
    monitor.setTextColor(colors.green)
    screen("Recieved command: " .. cmd, 1, 2)
    screen("Arguments:", 1, 3)
    print(textutils.serialize(args))
    for k,v in pairs(args) do
        screen("  "..v,1,3+k)
    end
    if cmd == "door" then
        if args[1] == "main" then
            if args[2] == "open" then
                if door_state.main == "closed" then
                    modem.transmit(22, 23, "toggle")
                    door_state.main = "open"
                    save_door_state()
                end
            elseif args[2] == "close" then
                if door_state.main == "open" then
                    modem.transmit(22, 23, "toggle")
                    door_state.main = "closed"
                    save_door_state()
                end
            end
        end
    elseif cmd == "test" then
    elseif cmd == "reboot" then
        os.reboot()
    end
end
-- recieve messages
function message()
    while true do
        local events = table.pack(os.pullEvent())
        if events[1] == "modem_message" then
            local commandMain = events[5]
            local command = commandMain[1]
            commandMain[1] = nil
            commandMain[0] = nil
            local commandArgs = {}
            for k,v in pairs(commandMain) do
                table.insert(commandArgs, v)
            end
            execute(command, commandArgs)
        end
    end
end


function main()
    while true do
        -- display the date and time
        timeH = tostring(math.floor(os.time()))
        timeM = math.floor((os.time() - math.floor(os.time()))*60)
        if math.floor(os.time()) < 10 then
            timeH = "0" .. timeH
        end
        if timeM < 10 then
            timeM = "0" .. tostring(timeM)
        end
        tostring(timeM)
        day = tostring(math.floor(os.day()))
        monitor.setTextColor(colors.blue)
        screen("Day " .. day .. ", " .. timeH .. ":" .. timeM, 1, 1)

        sleep(0.1)
    end
end


parallel.waitForAll(main, message)
