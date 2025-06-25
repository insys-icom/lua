-----LUA-----

-----START CONFIGURABLE PARAMETERS-----
-- Ping addresses/destinations
ping_addresses = {"192.168.6.1", "192.168.5.1", "8.8.8.8"}

-- number of tries if ping was unsuccessfull
try = 5

-- modem to restart
lte_modem = "lte2"
-----END CONFIGURABLE PARAMETERS-----

-- Initialisation of classes
C = require("Classes")
Con = C.Connectivity
Interfaces = C.Interfaces
wan_interfaces = Interfaces.get_wan_interfaces()

-- tests connection #Try-times over all ping_addresses
-- if ping to one address was successful, the script ends
-- if after #Try-times ping check is still unsuccessfull, then restart the lte modem
function ping_check()
    for i = 1, try do
        for _, target in ipairs(ping_addresses) do
            local Success = Con.ping(target, lte_modem)
            if Success then
                lua_log("LUA ping - " .. i .. ". check to target " .. target .. " successful")
                return true
            end
        end
        lua_log("LUA pings - " .. i .. ". check, both failed")
    end
    return false
end

function lte_connection()
    -- check if modem is valid
    if not wan_interfaces[lte_modem] then
        lua_log("ERROR: LTE Modem " .. lte_modem .. " does not exist")
        return false
    end
    local ret, state = Con.lte_check_state(lte_modem)
    if not ret then
        return false
    elseif state == 0 or state == -1 then
        lua_log("ERROR: LTE Modem " .. lte_modem .. " has no internet connection")
        return false
    end
    return true
end

function main()
    if not (lte_connection() and ping_check()) then
        -- restart modem after #Try loops because no ping was successful
        lua_log("Pings to all addresses was unsuccessfull after " .. try .. " tries, restarting lte modem")
        Con.restart_modem(lte_modem)
    end
end

lua_log("Start Pingtest")
main()
lua_log("End Pingtest")
-----LUA-----
