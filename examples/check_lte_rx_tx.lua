-----LUA-----
-- check transcieved and received pacekts of lte modem

-- get objects of class
C = require("Classes")
Help = C.Helper
Con = C.Connectivity
IOs = C.Ios
Interfaces = C.Interfaces
wan_interfaces = Interfaces.get_wan_interfaces()

-- checks for lte modems and returns first found modem (usefull if more than one lte modem exists)
for k in Help.sort_table(wan_interfaces) do
    if k:find("lte") then
        modem = k
    end
end

-- if not lte modem was detected on device -> error
if not modem then
    lua_log("No LTE modem inserted")
    return false
end

-- if lte_serial was found, then extract only lte and slot number
if modem:find("serial") then
    lte, slot = modem:match("^(lte)_serial(%d)$")
    modem = lte..slot
end

-- index of modem
ret, lte2_index = Help.get_index_by_name("status.sysdetail.ip_addresses", modem)
-- check if any index was found
if not ret then
    lua_log(modem .. "is not listed in IP addresses")
    return false
end

-- check if current wan chain has lte2 as interface, if not -> switch to that
for i = 1, cli("wan.wans.wan_chain.size") do
    ret = Help.get_index_by_name("wan.wans.wan_chain[" .. i .. "]", modem)
    if ret then
        Help.set_wan_chain(cli("wan.wans.wan_chain[" .. i .. "].name"))
    end
end

-- if no such wan chain exists, create one and set it
if not ret then
    cli("wan.wans.wan_chain.add")
    cli("wan.wans.wan_chain[last].description=LTE-Test")
    cli("wan.wans.wan_chain[last].interface.add")
    cli("wan.wans.wan_chain[last].interface[last].interface=" .. modem)
    cli("administration.profiles.activate")
    current_wan_chain = cli("wan.wans.wan_chain[last].name")
    Help.set_wan_chain(current_wan_chain)
end


-- initialise variables and wait for 10 seconds
rx_old = 0
tx_old = 0
digital_output = "2.1" -- output on lte for example
sleep(10)

-- check RX/TX packets
while true do
    rx_current = cli("status.sysdetail.ip_addresses.interface[" .. lte2_index .. "].packets_rx")
    tx_current = cli("status.sysdetail.ip_addresses.interface[" .. lte2_index .. "].packets_tx")

    rx = rx_current - rx_old
    tx = tx_current - tx_old

    -- restart modem if nothing changed
    if rx == 0 and tx == 0 then
        Con.restart_modem(modem)
    -- make pulses from output if nothing received
    elseif rx == 0 and tx ~= 0 then
        IOs.set_digital_output("2.1", "pulses", 20, 1000)
    -- restart modem if nothing transcieved
    elseif rx ~= 0 and tx == 0 then
        Help.set_wan_chain(current_wan_chain)
    end
    rx_old = rx_current
    tx_old = tx_current
    sleep(360)
end

-----LUA-----