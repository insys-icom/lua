-----LUA-----

-----START CONFIGURABLE PARAMETERS-----
-- set all ports of M3card SWM to this net
net_to_set = "net5"
-----END CONFIGURABLE PARAMETERS-----

-- Initialisation of Classes
C = require("Classes")
Ports = C.Ports
Help = C.Helper
Interfaces = C.Interfaces
ipnets = Interfaces.get_ip_net_interfaces()


-- set the ports to the specified net and activate profile
function main()
    -- check if parameter (IPnet) and required tables exist/filled
    cards_with_ports = Help.get_cards()
    if not (cards_with_ports["M3SWM"] and ipnets[net_to_set]) then
        lua_log("Check if parameters are correct and tables exist (true == correct, false == error)")
        lua_log(string.format("Interface: %s \n M3SWM: %s", ipnets[net_to_set].net , cards_with_ports["M3SWM"]))
        return
    end

    sleep(5)
    for k, v in pairs(Ports.get_ethernet_ports()) do
        if cards_with_ports["M3SWM"] == v.card then
            print(1)
            Ports.set_port_net(k, net_to_set)
        end
    end
    cli("administration.profiles.activate")
end

lua_log("Started detection for MRcards M3SWM")
main()
lua_log("Finished detection and set ports of M3SWM to " .. net_to_set)

-----LUA-----
