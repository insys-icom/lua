-----LUA-----

-----START CONFIGURABLE PARAMETERS-----
-- used Port
sfp_port = "5.1"

-- number of Ping checks
try = 4

-- Ping addresses/destinations
ping_addresses = {"192.168.5.1", "192.168.6.1"}

-- alternative if you need to set up sfp-ports with desired interface
-- Net = "desired net"
-- Ports.set_port_net -> goes below require
-----END CONFIGURABLE PARAMETERS-----

-- initialisation of classes and globals
C = require("Classes")
Ports = C.Ports
Con = C.Connectivity
sfp_ports = Ports.get_sfp_ports()
_, net_of_sfp_port = Ports.get_port_net(sfp_port)
slot, port = sfp_port:match("(%d)%.(%d)")

-- test connection #Try times
-- if Ping to one address was successfull, script ends
-- if Ping to all addresses was unsuccessfull, device will be restarted
function main()
    -- check if SFP port exists and has a module, end script if thats not the case
    if not (sfp_ports[sfp_port] and Ports.get_port_has_sfp_module(sfp_port)) then
        lua_log("ERROR: Sfp port does not exist or has not a (recognized) Sfp module")
        lua_log(string.format("SFP-Port: %s, module exists: %s", sfp_ports[sfp_port].port, sfp_ports[sfp_port].has_module))
        return
    end

    -- check if link of SFP Port is up
    if not Ports.get_link(sfp_port) then
        lua_log("ERROR: Link of SFP-Port " .. sfp_port ..  " is not up")
        cli("help.debug.reboot.submit")
        return
    end

    -- check if SFP Port has an assigned interface
    if net_of_sfp_port == "---" then
        lua_log("ERROR: No interface is assigned to Port " .. sfp_port)
        return
    end

    lua_log("SFP module in PORT " .. sfp_port .. " detected and up")

    for i = 1, try do
        for _, target in ipairs(ping_addresses) do
            local success = Con.ping(target, net_of_sfp_port)
            if success then
                lua_log("Pint at run: " .. i .. " to Address " .. target .. " was successfull")
                return
            end
        end
        lua_log("Ping at run: " .. i .. " failed for all addresses")
    end
    lua_log("Ping failed after " .. try .. " tries, restarting device...")
    cli("help.debug.reboot.submit")
end

lua_log("Connectivity test of SFP Port start")
main()
lua_log("Connectivity test of SFP Port end")
-----LUA-----
