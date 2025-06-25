-----LUA-----

----- START CONFIGURABLE PARAMETERS -----
-- WAN chains (available WAN chains)
wan           = "wan1"
wan_lte       = "wan2"
wan_ipsec     = "wan3"
wan_lte_ipsec = "wan4"

-- ping destination
ping_dest = "8.8.8.8"

-- WAN port
wan_port = "1.5"

-- name of digital input to turn on/off IPsec tunnel
input_name = "3.4"

-- ping sources (available interfaces)
interface_wan   = "net3"
interface_ipsec = "net2"
----- END CONFIGURABLE PARAMETERS -----

-- Initialisation of classes and other important global variables
C = require("Classes")
Ios = C.Ios
Ports = C.Ports
Con = C.Connectivity
Interfaces = C.Interfaces
Help = C.Helper
ethernet_ports = Ports.get_ethernet_ports()
ret, port_net = Ports.get_port_net(wan_port)
port_mode = cli("interfaces.ip_nets.net[" .. ipnets[port_net].index .. "].mode")
inputs = Ios.get_digital_inputs()
vpns = Interfaces.get_vpn_interfaces()
ipnets = Interfaces.get_ip_net_interfaces()

-- switches between wan chains
--   switch between (VPN/without VPN) wans occures if I/O is (high/low)
--   switch to LTE wans occures if wan port is down
--   switch between (Ethernet/LTE) wans occures if ping was (successfull/unsuccessfull)
function main()
    -- verifying if any of those parameters do exist on the router
    wan_exist           = Help.get_index_by_name("wan.wans.wan_chain", wan)
    wan_lte_exist       = Help.get_index_by_name("wan.wans.wan_chain", wan_lte)
    wan_ipsec_exist     = Help.get_index_by_name("wan.wans.wan_chain", wan_ipsec)
    wan_lte_ipsec_exist = Help.get_index_by_name("wan.wans.wan_chain", wan_lte_ipsec)

    wans_exist = (wan_exist and wan_lte_exist and wan_ipsec_exist and wan_lte_ipsec_exist)
    interfaces_exist = (ipnets[interface_ipsec] and ipnets[interface_wan])
    port_exist = (Ports.get_port(wan_port) and port_mode == "wan")
    io_exist = Ios.get_input(input_name)

    -- stop script if any of those parameters do not exist
    if not (wans_exist and interfaces_exist and port_exist and io_exist) then
        lua_log("ERROR: Check if parameters are correct or tables exist (true == correct, false == error)")
        lua_log(string.format("WAN Chains: %s \nInterfaces: %s \n WAN Port: %s \n IO: %s", wans_exist, interfaces_exist, port_exist, io_exist))
        return
    end

    while true do
        -- give router time to update/set everything because working makes tired...sleepy router zZẑ
        sleep(10)

        -- log IO change, update current IO status
        Ios.get_io_state_change(input_name, 1)
        local _, io_status = Ios.get_io_state(input_name, 1)

        -- get currenttly used WAN chain
        local currwan = cli("status.sysstat.wan.name")

        -- check connectivity
        local success = Con.ping(ping_dest, interface_wan)

        -- get link status of port
        local _, port_link = Ports.get_port_link(wan_port)

        -- check if WAN chain has any connectivity over ethernet => switch to appropriate WAN chain
        if port_link == "down" or not success then
            if io_status == "high" and currwan ~= wan_lte_ipsec then
                _, currwan = Help.set_wan_chain(wan_lte_ipsec)
            elseif io_status == "low" and currwan ~= wan_lte then
                _, currwan = Help.set_wan_chain(wan_lte)
            end
            lua_log("WARNING: Port " .. wan_port .. " is down, switched to " .. currwan)
        else
            if io_status == "high" and currwan ~= wan_ipsec then
                _, currwan = Help.set_wan_chain(wan_ipsec)
            elseif io_status == "low" and currwan ~= wan then
                _, currwan = Help.set_wan_chain(wan)
            end
        end
    end
end

lua_log("Skript start")
main()
lua_log("Skript end")
-----LUA-----
