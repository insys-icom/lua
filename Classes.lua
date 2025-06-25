-----LUA-----

local function Classes()

    -- Utility functions shared across all classes, can also be used stand-alone
    local function Helper()
        local self = {}
        local _card_types = { "io", "lte_serial", "ethernet", "adio", "lte", "serial", "sio", "dsl", "sfp", "power" }
        local _cards = {}
        local _device_type = cli("status.device_info.device_type")

        -- Detect all inserted MR Cards and store them in _cards
        local function _cards_table()
            for _, b in pairs(_card_types) do
                for n = 1, 5 do
                    local exist = pcall(cli, "status." .. b .. n)
                    if exist then
                        _cards[cli("status.device_info.slot[" .. n .. "].board_type")] = b .. n
                    end
                end
            end
            return _cards
        end

        -- Scan cli list output and collect indices whose <entry> matches <pattern> (eg. entry: description, pattern: 'TCP')
        -- entry parameter: specifies by what the index is searched for (eg. name, description)
        -- pattern parameter: pattern inside the given the given entry (eg. inside description search for '123')
        local function get_indexes(cli_command, pattern, entry)
            local index_table = {}
            local _, bracket_count = cli_command:gsub("%[%d+%]", "")
            local cl = cli(cli_command)
            local lines = self.cli_commands_into_table(cl)
            entry = entry and entry:gsub("(%W)", "%%%1") or ""
            pattern = pattern and pattern:gsub("(%W)", "%%%1") or ""
            for _, v in ipairs(lines) do
                if bracket_count == 0 and v:find("%.[%w_]*" .. entry .. "[%w_]*=%s*[^%c]*" .. pattern) then
                    local index = v:match(".-%[(%d+)%].-=")
                    local matched_result = v:match(entry .. "=(.+)") -- test with string.format or use v:find(..., 1, true)
                    index_table[index] = matched_result
                elseif bracket_count == 1 and v:find("%[%d+%]%.[%w_]*" .. entry .. "[%w_]*=%s*[^%c]*" ..pattern) then
                    local index = v:match("%[%d+%]%.[%w_.]*%[(%d+)%].-=")
                    local matched_result = v:match(entry .. "=(.+)")
                    index_table[index] = matched_result
                end
            end
            if not next(index_table) then
                lua_log("ERROR: Indexes weren't found, because no entry contains " .. pattern)
                return false, nil
            end
            return true, index_table
        end

        _cards_table()

        -- convert a cli output into a table of lines
        function self.cli_commands_into_table(str)
            local t = {}
            for l in (str .. "\n"):gmatch("(.-)\n") do
                table.insert(t, l)
            end
            return t
        end

        -- Like above, but keeps only lines that match given patterns
        -- change content inside of 'l:match()' if you want another pattern to match/extract
        -- e.g %f[%a]input%f[%A] means character before and after input has to be a non letter
        -- for more specific matches just add an 'or l:match("pattern")'
        function self.cli_specifics_into_table(str)
            local t = {}
            for l in (str .. "\n"):gmatch("(.-)\n") do
                if l:match("%f[%a]input%f[%A]") or l:match("%f[%a]output%f[%A]") then
                    table.insert(t, l)
                end
            end
            return t
        end

        -- returns device type(eg. MRX3 or MIRO-L200)
        function self.get_device_type()
            return _device_type
        end

        -- returns table of MR-Cards
        function self.get_card_types()
            return _card_types
        end

        -- returns table of available cards on a router
        function self.get_cards()
            return _cards
        end

        -- returns card based on slot (eg. card == ethernet1)
        function self.get_card_of_slot(slot)
            slot = tostring(slot)
            local ok, valid = pcall(cli,"status.device_info.slot[" .. slot .."]")
            if not ok then
                lua_log("ERROR: Failed to get card in slot " .. slot .. ": " .. valid )
                return false, nil
            end
            local card = _cards[cli(valid .. ".board_type")]
            return true, card
        end

        -- returns board_type of a chosen slot (eg. M3CPU, RMINI)
        function self.get_board_type_of_slot(slot)
            slot = tostring(slot)
            local ok, valid = pcall(cli, "status.device_info.slot[" .. slot .. "]")
            if not ok then
                lua_log("ERROR: Failed to get board in slot " .. slot .. ": " .. valid)
                return false, nil
            end
            local board = cli(valid .. ".board_type")
            return true, board
        end

        -- adds a new field to every (or a specific) table entry
        -- table parameter: table or array
        -- entry parameter: name for entry/attribute to be added (eg. for Ports tables, add entry 'mode')
        -- value parameter: value for  added entry, if not given use default value '---'
        -- key parameter: if key is given, add entry to specific key, else add entry to every table element
        function self.add_entry(tbl, entry, value, key)
            value = value or '---'
            if key then
                local sub_tbl = tbl[key]
                if sub_tbl and not sub_tbl[entry] then
                    sub_tbl[entry] = value
                end
                return tbl
            end

            for _, v in pairs(tbl) do
                if not v[entry] then
                    v[entry] = value
                end
            end
            return tbl
        end

        -- deletes a field from every (or a specific) table entry
        -- Same parameters, but without 'value'
        function self.delete_entry(tbl, entry, key)
            if key then
                local sub_tbl = tbl[key]
                if not sub_tbl then
                    lua_log("ERROR: Field: " .. entry .. " from " .. tbl .. "[" .. key .. "] does not exist")
                    return false
                end
                sub_tbl[entry] = nil
                return tbl
            end
            for _, v in pairs(tbl) do
                v[entry] = nil
            end
            return tbl
        end

        -- lists all entries of a table or subtable (eg. list_table_contents(Ports) or list_table_contents(Ports[key]))
        -- used for debugging purposes -> CLI or GUI necessary
        function self.list_table_contents(tbl)
            if type(tbl) == 'table' then
                for k,v in pairs(tbl) do
                    print(k,v)
                end
                return true
            end
            return false
        end

        -- sorts table by keys
        -- compare parameter: specify how a table is sorted (eg. function(a,b) return a < b end for ascending order)
        function self.sort_table(tbl, compare)
            local keys = {}
            for k in pairs(tbl) do table.insert(keys, k) end
            table.sort(keys, compare)
            local i = 0
            return function()
                i = i + 1
                local k = keys[i]
                if k then
                    return k, tbl[k]
                end
            end
        end

        -- get index of first found entry in an endless list
        -- entry specifies where to look for eg. description, name; entry can be left empty
        function self.get_index(cli, pattern, entry)
            local ok, indexes = get_indexes(cli, pattern, entry)
            if ok then
                for k in self.sort_table(indexes, function(a, b) return a<b end) do
                    return true, k
                end
            end
            return false, nil
        end

        -- same as function above but returns a list of indices
        function self.get_indexes(cli, pattern, entry)
            ok, indexes = get_indexes(cli, pattern, entry)
            if ok then
                return true, indexes
            end
            return false, table
        end

        -- returns first index found from cli list output by name (eg. name="net1")
        function self.get_index_by_name(cli, name)
            local ok, index_table = get_indexes(cli, name, "name")
            if not ok then
                return false, nil
            end
            for k in self.sort_table(index_table, function(a,b) return a < b end) do
                return true, k
            end
        end

        -- returns first index found by pattern in description (eg. description='TCP Port 123', pattern == '123')
        function self.get_index_by_description(cli, pattern)
            local ok, index_table = get_indexes(cli, pattern, "description")
            if not ok then
                return false, nil
            end
            for k in self.sort_table(index_table, function(a,b) return a<b end) do
                return true, k
            end
        end

        -- returns table of indexes, from cli list output, found by pattern in description
        function self.get_indexes_by_description(cli, pattern)
            local ok, index_table = get_indexes(cli, pattern, "description")
            if not ok then
                return false, nil
            end
            return true, index_table
        end

        -- sets current wan chain
        function self.set_wan_chain(wan)
            -- checks if wan chain exists
            if wan == cli("status.sysstat.wan.name") then
                lua_log("ERROR: Already set to " .. wan)
                return false, nil
            end
            local switch_wan
            local ok, switch_wan_index = self.get_index_by_name("wan.wans.wan_chain", wan)
            if not ok then
                lua_log("ERROR: WAN chain " .. wan .. " does not exist and could not be set")
                return false, nil
            end
            switch_wan = cli("wan.wans.wan_chain[" .. switch_wan_index .. "].name")
            -- set and activate wan chain
            cli("help.debug.wan_chain.wan_chain=" .. switch_wan)
            cli("help.debug.wan_chain.submit")
            return true, switch_wan
        end

        return self
    end

    -- handle router network interfaces (IP-net, WAN-cards, VPN)
    local function Interfaces()
        local self = {}
        local _vpn_types = {"openvpn", "ipsec", "gre", "dmvpn", "pptp", "pppoe"}
        local _net_interfaces = {}
        local _wan_interfaces = {}
        local _vpn_interfaces = {}
        local _ip_addresses = {}
        local help = selfs.Helper
        local _cards = help.get_cards()

        -- return table of available IPnet interfaces
        local function _ip_nets()
            for ni = 1, cli("interfaces.ip_nets.net.size") do
                local net = cli("interfaces.ip_nets.net[" .. ni .. "].name")
                _net_interfaces[net] = {net        = net,
                                        index      = ni,
                                        ip_address = {}}
                for ipi = 1, cli("interfaces.ip_nets.net[".. ni .. "].ip_address.size") do
                    _net_interfaces[net].ip_address[ipi] = {address = cli("interfaces.ip_nets.net[".. ni .. "].ip_address[" .. ipi .. "].ip_address"),
                                                            index   = ipi}
                end
            end
            return _net_interfaces
        end

        -- returns table of available WAN-cards that double as interfaces (LTE, DSL)
        local function _wans()
            for _, v in pairs(_cards) do
                if v:find("lte") then
                    _wan_interfaces[v] = {net = v}
                elseif v:find("dsl") then
                    _wan_interfaces[v] = {net = v}
                end
            end
            return _wan_interfaces
        end

        -- returns table of VPN tunnels per type (OpenVPN, IPsec)
        local function _vpns()
            for _, v in pairs(_vpn_types) do
                local size = cli("interfaces." .. v .. ".tunnel.size")
                if size ~= 0 then
                    for vi = 1, size do
                        _vpn_interfaces[v .. vi] = {net          = v .. vi,
                                                    index        = vi}
                    end
                end
            end
            return _vpn_interfaces
        end

        -- sets apn of lte modem from a table of apns based on imsi of inserted sim card
        local function set_apn(modem, apn_table, run_time, mode)
            if not modem:find("lte") then
                lua_log("ERROR: Modem '" .. modem .. "' is not a LTE Modem")
            end
            if not _wan_interfaces[modem] then
                lua_log("ERROR: Modem '" .. modem .. "' does not exist")
                return false
            end
            local lte, slot = modem:match("^(lte)_serial(%d)$")
            local board = help.get_board_type_of_slot(slot)
            local device = help.get_device_type()
            if board == "M3PSQ" or device == "ECR-LW300" then
                local exists, used_sim = pcall(cli, "status." .. modem .. ".used_sim")
                if not exists then
                    return false
                end
                if not used_sim:find("1") then
                    return false
                end
            end
            local exists, imsi, apn
            if not run_time then
                run_time = true
            end
            while run_time do
                if mode == 'imsi' then
                    exists, imsi_usim = pcall(cli, "status." .. modem .. ".IMSI")
                else
                    exists, imsi_usim = pcall(cli, "status." .. modem .. ".USIM")
                end
                if not exists then
                    return false
                end
                if imsi_usim:find("^(%d+)$") or run_time == 0 then
                    break
                end
                run_time = run_time - 1
                sleep(1)
            end
            for imsis_usims_provider, apn_provider in pairs(apn_table) do
                if imsi:find(imsis_usims_provider) then
                    apn = apn_provider
                end
            end
            if not apn then
                lua_log("ERROR: APN could not be found")
                return false
            end
            lua_log("Setting APN to " .. apn)
            cli("interfaces." .. lte .. slot .. ".apn=" .. apn)
            return true
        end

        -- returns table of IPnet interfaces
        function self.get_ip_net_interfaces()
            if next(_net_interfaces) then
                for k in pairs(_net_interfaces) do
                    _net_interfaces[k] = nil
                end
            end
            _ip_nets()
            return _net_interfaces
        end

        -- returns table of VPN interfaces
        function self.get_vpn_interfaces()
            if next(_vpn_interfaces) then
                for k in pairs(_vpn_interfaces) do
                    _vpn_interfaces[k] = nil
                end
            end
            _vpns()
            return _vpn_interfaces
        end

        -- returns table of interfaces that are also MR-cards
        function self.get_wan_interfaces()
            if next(_wan_interfaces) then
                for k in pairs(_wan_interfaces) do
                    _wan_interfaces[k] = nil
                end
            end
            _wans()
            return _wan_interfaces
        end

        -- returns table of ip addresses for given ipnet
        function self.get_ip_addresses(net)
            _ip_nets()
            if next(_ip_addresses) then
                for k in pairs(_ip_addresses) do
                    _ip_addresses[k] = nil
                end
            end
            if _net_interfaces[net] then
                _ip_addresses = _net_interfaces[net].ip_address
                return _ip_addresses
            end
            return false
        end

        function self.set_apn_by_imsi(modem, apn_table, run_time)
            local success = set_apn(modem, apn_table, run_time, "imsi")
            if not success then
                return false
            end
            return true
        end

        function self.set_apn_by_usim(modem, apn_table, run_time)
            local success = set_apn(modem, apn_table, run_time, "usim")
            if not success then
                return false
            end
            return true
        end

        return self
    end

    -- detect and manage router ports
    local function Ports()
        local self = {}
        local _ports = {}
        local _sfp_ports = {}
        local _ethernet_ports = {}
        local help = selfs.Helper
        local interface = selfs.Interfaces
        local _ip_net = interface.get_ip_net_interfaces()

        -- returns table of ethernet and sfp cards
        local _cards = (function ()
            local original = help.get_cards()
            local ret = {}
            for ci, c in pairs(original) do
                if c:find("ethernet") or c:find("sfp") then
                    ret[ci] = c
                end
            end
            return ret
        end)()

        -- returns table of all detected ports and seperate tables for only ethernet/sfp ports
        local function _device_ports()
            for _, k in pairs(_cards) do
                local size = cli("status." .. k .. ".port.size")
                local slot = k:match("(%d)$")
                for p = 1, size do
                    _ports[slot .. "." .. p] = {card = k}
                    if k:find("ethernet") then
                        _ethernet_ports[slot .. "." .. p] = {card = k,
                                                             port = slot .. "." .. p,
                                                             link = cli("status." .. k .. ".port[" .. p .. "].link"),
                                                             net  = cli("status." .. k .. ".port[" .. p .. "].port_net")}
                    else
                        _sfp_ports[slot .. "." .. p] = {card = k,
                                                        port = slot .. "." .. p,
                                                        link = cli("status." .. k .. ".port[" .. p .. "].link"),
                                                        net  = cli("status." .. k .. ".port[" .. p .. "].port_net"),
                                                        has_module = cli("status." .. k .. ".port[" .. p .."].inserted")}
                    end
                end
            end
            return _ports, _ethernet_ports, _sfp_ports
        end

        _device_ports()

        -- returns table of detected ports
        function self.get_ports()
            return _ports
        end

        -- returns table of only ethernet ports
        function self.get_ethernet_ports()
            return _ethernet_ports
        end

        -- returns table of only sfp ports
        function self.get_sfp_ports()
            return _sfp_ports
        end

        -- updates all ports
        function self.update_ports()
            return _device_ports()
        end

        -- returns specific port (entry) from ports table
        function self.get_port(port)
            port = tostring(port)
            if not _ports[port] then
                lua_log("ERROR: Port " .. port .. " does not exist")
                return false
            end
            if _ethernet_ports[port] then
                return _ethernet_ports[port]
            elseif _sfp_ports[port] then
                return _sfp_ports[port]
            end
        end

        -- detects link of ethernet/sfp port (up/down)
        function self.get_port_link(port)
            _device_ports()
            local link
            port = tostring(port)
            -- checks if specific port is detected port on device
            if not _ports[port] then
                lua_log("ERROR: Port " .. port .. " does not exist")
                return false, nil
            end
            -- returns link of port and updates entry
            if _ethernet_ports[port] then
                link= _ethernet_ports[port].link
            else
                link = _sfp_ports[port].link
            end
            return true, link
        end

        -- checks if specific sfp port has  module inserted (true/false) and returns currently examined port
        function self.get_port_has_sfp_module(port)
            _device_ports()
            port = tostring(port)
            -- checks if sfp port exists
            if not _sfp_ports[port] then
                return false, nil
            end
            -- look up in sfp_port table to determine if port has a sfp module
            if _sfp_ports[port].has_module == "yes" then
                return true, port
            end
            return false, nil
        end

        -- returns interface used by given port (eg. Port: '1.1' uses 'net1')
        function self.get_port_net(port)
            _device_ports()
            local net
            port = tostring(port)
            -- checks if specific port is a detected port on device
            if not _ports[port] then
                lua_log("ERROR: Port " .. " does not exist")
                return false, nil
            end
            -- returns interface of port, '---' if no interface was assigned to port and updates table entry
            if _ethernet_ports[port] then
                net = _ethernet_ports[port].net
            else
                net = _sfp_ports[port].net
            end
            return true, net
        end

        -- sets desired interface to given port
        function self.set_port_net(port, net)
            port = tostring(port)
            local slot, port_num = port:match("^(%d)%.(%d)$")
            -- check if interface is a detected interface
            if not _ip_net[net] and net ~= "---" then
                lua_log("ERROR: IPnet Interface does not exist")
                return false
            end
            -- returns both, assigned interface and edited port and updates net table entry
            local ok, ipnet = pcall(cli,"interfaces.ethernet".. slot .. ".port" .. port_num .. "_active=" .. net)
            if not ok then
                ok, ipnet = pcall(cli,"interfaces.sfp" .. slot .. ".port" .. port_num .. "_active=" .. net)
                if not ok then
                    lua_log("Port '" .. port .. "' does not exist")
                    return false
                end
            end
            if _ethernet_ports[port] then
                _ethernet_ports[port].net = ipnet
            else
                _sfp_ports[port].net = ipnet
            end
            return true
        end

        return self
    end

    -- send and handle recieved messages
    local function Messages()
        local self = {}
        local _event_id
        local _message
        local _modem
        local _sender
        local interfaces = selfs.Interfaces
        local wans = interfaces.get_wan_interfaces()

        -- sends mail to desired mail address with text and subject
        function self.send_email(mail_address, text, subject)
            cli("help.debug.email.recipient=" .. mail_address)
            cli("help.debug.email.subject=" .. subject)
            cli("help.debug.email.text=-----BEGIN TEXT-----" .. text .. "-----END TEXT-----")
            local result = cli("help.debug.email.submit")
            -- creates a log entry if email couldn't be sent
            if result == "manual action failed" then
                lua_log("ERROR: Email cannot be sent. Verify your contact: " .. mail_address)
                return false
            end
            return true
        end

        -- sends sms to desired recipient with text messages through given modem
        function self.send_sms(recipient, text, modem)
            -- get the next best LTE modem found by Interface class
            local default_modem = ( function()
                for _, v in pairs(wans) do
                    if v.net:find("lte") then
                        local default = v.net
                        if v.net:find("lte_serial") then
                            local lte, slot = v.net:match("^(lte)_serial(%d)$")
                            default = lte .. slot
                        end
                        return default
                    end
                end
            end)()
            modem = modem or default_modem
            cli("help.debug.sms.modem=" .. modem)
            cli("help.debug.sms.recipient=" .. recipient)
            cli("help.debug.sms.text=-----BEGIN TEXT-----" .. text .. "-----END TEXT-----")
            local result = cli("help.debug.sms.submit")
            -- creates a log entry if email couldn't be sent
            if result == "manual action failed" then
                lua_log("ERROR: SMS cannot be sent. Verify if phone number exists: " .. recipient)
                return false
            end
            return true
        end

        -- sends notification based on an already configured contact in profile
        function self.send_message(message)
            cli("help.debug.message.message=" .. message)
            local result = cli("help.debug.message.submit")
            -- creates a log entry if email couldn't be sent
            if result == "manual action failed" then
                lua_log(string.format("ERROR: Message or notification could not be sent. Verify if %s exists or is set up", message))
                return false
            end
            return true
        end

        -- store values of last message-event (ASCII trigger). Overwrites previous values
        -- if function is used before an event occurs, all currently saved values that were extracted from a past event, will be nil
        function self.message_event_extraction()
            _event_id = (cli("events.info[event_id]"))
            _message = (cli("events.info[message]"))
            _modem = (cli("events.info[modem]"))
            _sender = (cli("events.info[sender]"))
            return _event_id, _message, _modem, _sender
        end

        -- return already extracted and store values from a message event
        function self.get_extracted_event_info()
            return _event_id, _message, _modem, _sender
        end

    return self
    end

    -- responsible for connectivity checks
    local function Connectivity()
        local self = {}
        local interfaces = selfs.Interfaces
        local _wans = interfaces.get_wan_interfaces()
        local _ipnet = interfaces.get_ip_net_interfaces()
        local _vpns = interfaces.get_vpn_interfaces()

        -- checks validity of IP-Address. 0 == type of IP-Address is not a string, 1 == IPv4-Address, 2 == IPv6-Address, 3 == string (google.de) or invalid ip_address (999.999.999.999)
        local function _get_ip_type(ip)
            local r = {error = 0, ipv4 = 1, ipv6 = 2, string = 3}
            if type(ip) ~= "string" then
                lua_log("ERROR: IP is not type string")
                return r.error
            end

            -- check for format 1.11.111.111 for ipv4
            local chunks = {ip:match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$")}
            if #chunks == 4 then
                for _,v in pairs(chunks) do
                    if tonumber(v) > 255 then
                        lua_log("ERROR: Address" .. ip .. " is not a valid IPv4")
                        return r.string
                    end
                end
                return r.ipv4
            end

            -- check for ipv6 format, should be 8 'chunks' of numbers/letters
            -- without leading/trailing chars
            -- or fewer than 8 chunks, but with only one `::` group
            local chunks = {ip:match("^"..(("([a-fA-F0-9]*):"):rep(8):gsub(":$","$")))}
            if #chunks == 8 or #chunks < 8 and ip:match('::') and not ip:gsub("::","",1):match('::') then
                for _,v in pairs(chunks) do
                    if #v > 0 and tonumber(v, 16) > 65535 then return r.string end
                end
                return r.ipv6
            end

            return r.string
        end

        -- make ping to an IP Addresss
        local function ping(dest, net, num_of_pings, vx)
            local exist, result, exit

            -- if net and/or number of pings are set, check for validity and set parameter else use default empty value
            if net and net ~= "" then
                if not(_ipnet[net] or _wans[net] or _vpns[net]) then
                    lua_log("ERROR: Source Interface " .. net .. " does not exist")
                    return false, nil
                end
                net = "-I " .. net .. " "
            else
                net = ""
            end
            if num_of_pings and num_of_pings ~= "" then
                num_of_pings = tostring(num_of_pings)
                if not num_of_pings:match("^%d+$") then
                    lua_log("ERROR: Chosen Number of Pings is invalid")
                    return false, nil
                end
                num_of_pings = "-c" .. num_of_pings .. " "
            else
                num_of_pings = "-c1 "
            end
            if net:find("lte_serial") then
                local lte, slot = net:match("^(lte)_serial(%d)")
                net = lte .. slot
            end

            -- checks for syntax of IP-Address and determines type of ICMP-Ping. versions == 6 for PING6, version == "" for PING4
            local ip_type = _get_ip_type(dest)
            if ip_type == 0 then
                return false
            elseif ip_type == 1 and vx ~= 4 then
                return false
            elseif ip_type == 2 and vx ~= 6 then
                return false
            elseif ip_type == 3 and (dest:match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$") or dest:match("^"..(("([a-fA-F0-9]*):"):rep(8):gsub(":$","$")))) then
                return false
            end
            vx = (vx == 4) and "" or 6
            exist, result, exit = pcall(cli, "help.debug.tool=ping"..vx.." "..net..num_of_pings..dest)
            -- if any other errors occur
            if exit ~= 0 or not exist then
                lua_log("Ping cannot be made: " ..  result)
                return false, nil
            end
            -- if more pings at once are made, that a certain threshold can't be undercut
            local pl = result:match("(%d+)%% packet loss")
            local loss = tonumber(pl)
            local pong = {packet_loss = loss .. "%",
                     result_message = result,
                     exit_code = exit }
            if loss < 40 then
                return true, pong
            end
            lua_log("WARNING: Packet loss is at " .. loss .. "%")
            return false, pong
        end

        -- ping a v4 address
        -- net parameter(OPTIONAL): ping from given interface
        -- num_of_pings parameter(OPTIONAL): number of pings
        function self.ping(dest, net, num_of_pings)
            local ok, result = ping(dest, net, num_of_pings, 4)
            return ok, result
        end

        -- ping a v6 address
        -- same optional parameters as above
        function self.ping6(dest, net, num_of_pings)
            local ok, result = ping(dest, net, num_of_pings, 6)
            return ok, result
        end

        -- checks connectivity of LTE Modem and returns true/false if usable and state of modem
        function self.lte_check_state(modem)
            local state_handler = {
                ["Turned off"]         = 0,
                ["Turned on"]          = 1,
                ["SIM interface down"] = 2,
                ["Logged out"]         = 3,
                ["Logging in"]         = 4,
                ["Logged in"]          = 5, -- modem can at least send sms
                ["Offline"]            = 6,
                ["Online"]             = 7  -- modem has internet connection
            }
            -- checks if modem parameter is not only a string (in case of a misuse) but also a valid lte modem
            if type(modem) ~= 'string' then
                lua_log("ERROR: Chosen Modem is invalid")
                return false, nil
            elseif not modem:find("lte") then
                lua_log("ERROR: Cant check for LTE functionality because " .. modem .. " has no LTE modem")
                return false, nil
            elseif not _wans[modem] then
                lua_log("ERROR: " .. modem .. " does not exist")
                return false, nil
            end
            local ok , state = pcall(cli, "status.".. modem .. ".state")
            if not ok then
                lte, slot = modem:match("^(.-)(%d)")
                modem = lte .. "_serial" .. slot
                state = cli("status.".. modem .. ".state")
            end
            if state_handler[state] == 7 then
                lua_log("Modem has state '" .. state .. "': Internet connection")
                return true, 1
            elseif state_handler[state] == 6 or state_handler[state] == 5 then
                lua_log("Modem has state '" .. state .. "': Connected to provider " .. cli("status." .. modem .. ".provider_name") .. " - >able to send SMS")
                return true, 0
            else
                lua_log("WARNING: Modem has state '" .. state .. "': not connected to a provider -> unable to send sms or connect to internet")
                return true, -1
            end
        end

        -- restarts lte modem
        function self.restart_modem(modem)
            if modem:find("serial") then
                lte, slot = modem:match("^(lte)_serial(%d)")
                modem = lte .. slot
            end
            if not _wans[modem] then
                lua_log("ERROR: " .. modem .. " is not a modem")
                return false
            end
            cli("help.debug.modem_state.name=" .. modem)
            cli("help.debug.modem_state.state_change=turn_off")
            cli("help.debug.modem_state.submit")
            sleep(3)
            cli("help.debug.modem_state.name=" .. modem)
            cli("help.debug.modem_state.state_change=turn_on")
            cli("help.debug.modem_state.submit")
            sleep(3)
            cli("help.debug.modem_state.name=" .. modem)
            cli("help.debug.modem_state.state_change=log_in")
            cli("help.debug.modem_state.submit")
            return true
        end

        return self
    end

    -- scans and organizes I/Os of device
    local function IOs()
        local self = {}
        local _outputs = {}
        local _inputs =  {}
        local help = selfs.Helper

        -- remove all Ethernet cards, because they don't have any IOs
        local _cards = (function ()
            local original = help.get_cards()
            local ret = {}
            for ci, c in pairs(original) do
                if not c:find("ethernet") then
                    ret[ci] = c
                end
            end
            return ret
        end)()
        local _device_info = help.get_device_type()
        local _cli_table = help.cli_specifics_into_table

        -- helper function to add IOs
        -- parameter 'on_card' has both the MR-Card and corresponding slot (eg. ethernet1, adio5)
        local function _add_io(table, io, analog_digital, status, on_card)
            table[io] = {index = io,
                         status = status,
                         analog_digital = analog_digital,
                         on_card = on_card}
        end

        -- find I/Os on MRX
        local function _ios_mrx()
            for _, card in pairs (_cards) do
                local slot = card:match("(%d)$")
                -- DSL is special case because of different CLI syntax
                if card:find("dsl") then
                    _add_io(_inputs, slot .. ".1", cli("status." .. card .. ".status.input_1"), card)
                    _add_io(_inputs, slot .. ".2", cli("status." .. card .. ".status.input_2"), card)
                else
                    -- process the rest of the found cards
                    local cmds = _cli_table(cli("status." .. card))
                    for _, k in ipairs(cmds) do
                        local io_type, io, io_num = k:match("([%a+_]*)(input)_(%d)")
                        if not io then
                            io_type, io, io_num = k:match("([%a+_]*)(output)_(%d)")
                        end
                        if io then
                            local io_table = (io == "input") and _inputs or _outputs
                            local io_index = (io_type == "analog_") and slot .. "." .. io_num .. "a" or slot .. "." .. io_num
                            local io_state = cli("status." .. card .. "." .. io_type .. io .. "_" .. io_num)
                            local io_types = (io_type == "analog_") and "analog" or (io_type == "digital_") and "digital" or ""
                            _add_io(io_table, io_index, io_types, io_state, card)
                        end
                    end
                end
            end
            return _inputs, _outputs
        end

        -- find I/Os of MIRO
        local function _ios_miro()
            local io_mode = cli("status.io2.direction")
            -- MIRO has programmable I/O, if I/O switches state, entry in other table will be deleted
            if io_mode == "in" then
                if _outputs["2.1"] then
                    _outputs["2.1"] = nil
                end
                _add_io(_inputs, "2.1", cli("status.io2.state"), "io2")
                return _inputs
            else
            -- same applies to the case above with input changed to output
                if _inputs["2.1"] then
                    _inputs["2.1"] = nil
                end
                _add_io(_outputs, "2.1", cli("status.io2.state"), "io2")
                return _outputs
            end
        end

        -- find IOs on SCR or ECR
        local function _ios_scr_ecr()
            _add_io(_inputs, "3.1", cli("status.io3.input_1"), "io3")
            _add_io(_inputs, "3.2", cli("status.io3.input_2"), "io3")
            _add_io(_outputs, "3.1", cli("status.io3.output_1"), "io3")
            _add_io(_outputs, "3.2", cli("status.io3.output_2"), "io3")
            return _inputs, _outputs
        end

        -- execute detection of I/Os depending on the device
        local function _io_device(d)
            local device = d:match("^(%a%a%a)")
            local device_handler = {
                ["MRX"] = _ios_mrx,
                ["MRO"] = _ios_mrx,
                ["MIR"] = _ios_miro,
                ["ECR"] = _ios_scr_ecr,
                ["SCR"] = _ios_scr_ecr
            }
            device_handler[device]()
        end
        _io_device(_device_info)


        -- set type and value of analog output eg. analog_type = "voltage", value = "3" -> 3V
        local function set_analog_output(output, analog_type, value)
            if analog_type == "voltage" and value > 10 then
                lua_log("ERROR: Voltage output can't exceed 10V")
                return false
            elseif analog_type == "current" and value > 20 then
                lua_log("ERROR: Voltage output can't exceed 20mA")
                return false
            end
            if not _outputs[output .. "a"] then
                lua_log("ERROR: Chosen output " .. output .. " does not exist or isn't analog")
                return false
            end
            local ok, result = pcall(cli, "interfaces." .. _outputs[output .. "a"].on_card .. ".analog_out1_type=" .. analog_type)
            if not ok then
                lua_log("ERROR: " .. result)
                return false
            end
            cli("help.debug.analog_output.output=" .. output)
            cli("help.debug.analog_output.value=" .. value)
            local ret = cli("help.debug.analog_output.submit")
            if ret == "manual action failed" then
                lua_log("ERROR: Output could not be set")
                return false
            end
            return true
        end

        -- get specific table of IOs
        local function get_io_table(input_output, analog_digital)
            local io_table = {}
            io_table = (input_output == "input") and _inputs or _outputs
            for k, v in pairs(io_table) do
                if analog_digital == "analog" and k:find("a") then
                    k:gsub("a", "")
                    io_table[k] = v
                end
                if analog_digital == "digital" and not k:find("a") then
                    io_table[k] = v
                end
            end
            return io_table
        end

        -- returns table of detected digital outputs
        function self.get_digital_outputs()
            local digital_outputs = get_io_table("output", "digital")
            return digital_outputs
        end

        -- returns table of detected digital inputs
        function self.get_digital_inputs()
            local digital_inputs = get_io_table("input", "digital")
            return digital_inputs
        end

        -- returns table of detected analog inputs
        function self.get_analog_inputs()
            local analog_inputs = get_io_table("input", "analog")
            return analog_inputs
        end

        -- returns table of detected analog outputs
        function self.get_analog_outputs()
            local analog_output = get_io_table("output", "analog")
            return analog_output
        end

        -- returns specific input
        function self.get_input(input)
            input = tostring(input)
            if _inputs[input] then
                return true, _inputs[input]
            end
            lua_log("ERROR: I/O " .. input .. " is not an input")
            return false, nil
        end

        --returns specific output
        function self.get_output(output)
            output = tostring(output)
            if _outputs[output] then
                return true, _outputs[output]
            end
            lua_log("ERROR: I/O " .. output .. " is not an output")
            return false, nil
        end

        -- returns state of I/O (outputs: open/closee, inputs: high/low) -> for 'direction' parameter: 1 for inputs, 0 for outputs
        function self.get_io_state(io, direction)
            io = tostring(io)
            direction = tonumber(direction)
            if not direction then
                lua_log("ERROR: Direction value: " .. direction .." , make sure it is set to 1 => inputs or 0 => outputs")
                return false, nil
            end
            -- special case for MIRO, where it upates its status and returns either state of input or ouptut
            if _device_info:find("MIRO") then
                self.update_miro_io()
                local status = _inputs[io].status or _outputs[io].status
                return true, status
            end

            local io_table = (direction == 1) and _inputs or _outputs
            local io_dir = (direction == 1) and "input_" or "output_"
            local io_prefix = (io_table[io].on_card:find("adio")) and io_table[io].analog_digital .. "_" or ""
            local io_number = io:match("^%d%.(%d)")

            -- depending on direction, updates and returns state of I/O
            ok, io_table[io].status = pcall(cli, "status." .. io_table[io].on_card .. "." .. io_prefix .. io_dir .. io_number)
            if not ok then
                if not io_table[io] then
                    if not _inputs[io] then
                        lua_log("ERROR: I/O " .. io .. " is not an Input")
                    else
                        lua_log("ERROR: I/O " .. io .. " is not an Output")
                    end
                else
                    lua_log("ERROR: Something went wrong")
                end
                return false, nil
            end
            return true, io_table[io].status
        end

        -- log if I/O status has changed (true/false), update table entry of I/O
        -- returns updated I/O index and status
        function self.get_io_state_change(io, direction)
            io = tostring(io)
            direction = tonumber(direction)
            local io_num = io:match("^%d%.(%d)")
            if not direction or (direction ~= 1 and direction ~= 0) then
                lua_log("ERROR: Direction value: " .. direction .." , make sure it is set to 1 => inputs or 0 => outputs")
                return false, nil
            end

            -- create variables for cli string
            local io_table = (direction == 1) and _inputs or _outputs
            local io_dir = (direction == 1) and "input_" or "output_"
            local io_prefix = (io_table[io].on_card:find("adio")) and io_table[io].analog_digital .. "_" or ""
            local prev_status = io_table[io].status

            -- special case for MIRO I/O
            if _device_info:find("MIRO") then
                local cur_status = cli("status.io2.state")
                if cur_status ~= prev_status then
                    lua_log("IO " .. io .. " changed state to " .. cur_status)
                    io_table[io].status = cur_status
                    return true, cur_status
                end
                return false, cur_status
            end

            -- get current I/O status and compare to previous state
            local cur_status = cli("status." .. io_table[io].on_card .. "." .. io_prefix .. io_dir .. io_num)
            if cur_status ~= prev_status then
                lua_log("IO " .. io .. " changed state to " .. cur_status)
                io_table[io].status = cur_status
                return true, cur_status
            end
            return false, cur_status
        end

        -- returns card of I/O
        function self.get_card_of_io(io, direction)
            io = tostring(io)
            direction = tonumber(direction)
            if not direction then
                lua_log("ERROR: Direction value: " .. direction .." , make sure it is set to 1 => inputs or 0 => outputs")
                return false, nil
            end
            -- special case for MIRO, becouse IO is always on 'card' io2 and io index are both the same for inputs and outputs
            if _device_info:find("MIRO") then
                if _inputs[io] or _outputs[io] then
                    return true, "io2"
                end
                lua_log("ERROR: " .. io .. " does not exist on MIRO")
                return false, nil
            end
            -- handle the other cases
            if direction == 1 then
                if _inputs[io] then
                    return true, _inputs[io].on_card
                end
                lua_log("ERROR: I/O " .. io .. " is not an Input")
            elseif direction == 0 then
                if _outputs[io] then
                    return true, _outputs[io].on_card
                end
                lua_log("ERROR: I/O " .. io .. " is not an Output")
            end
            return false, nil
        end

        -- update I/Os
        function self.update_ios()
            return _io_device(_device_info)
        end

        -- set voltage of analog output and update table
        function self.set_analog_output_voltage(output, value)
            local success = set_analog_output(output, "voltage", value)
            _ios_mrx()
            return success
        end

        -- set current of analog output and update table
        function self.set_analog_output_current(output, value)
            local success = set_analog_output(output, "current", value)
            _ios_mrx()
            return success
        end

        -- set mode of analog input to "current" or "voltage" and update table
        function self.set_analog_input(input, input_type)
            if not _inputs[input .. "a"] then
                lua_log("ERROR: Input '" .. input .. "' does not exist or is not analog")
                return false
            end
            if not (input_type == "current" or input_type == "voltage") then
                lua_log("ERROR: input '" .. input .. "' can't be set to state '" .. input_type .."'; invalid state type")
                return false
            end
            ok, result = pcall(cli, "interfaces." .. _inputs[input .. "a"].on_card .. ".analog_in" .. input:match("^%d%.(%d)") .. "_type=" .. input_type)
            if not ok then
                lua_log("ERROR: " .. result)
                return false
            end
            _ios_mrx()
            return true
        end

        -- set digital output to given parameters
        -- Parameter 1: digital output
        -- Parameter 2: state of output ('close', 'open', 'toggle' == change state regardless of previous one or 'pulses')
        -- Parameter 3: number of pulses to be made (1-255)
        -- Parameter 4: periode of pulses (200-5000ms)
        function self.set_digital_output(output, state, pulses, periode)
            if not _outputs[output] then
                lua_log("ERROR: Output " .. output .. " does not exist")
                return false
            end
            if not(state == "toggle" or state == "open" or state == "close" or state == "pulses") then
                lua_log("ERROR: Output state '" .. state .. "' is not valid")
                return false
            end
            if state == "pulses" and (pulses < 1 or pulses > 255) then
                lua_log("ERROR: number of pulses == '" .. pulses .. "'; Number must be in range 1-255")
                return false
            end
            if state == "pulses" and periode % 100 ~= 0 and (periode < 200 or periode > 5000) then
                lua_log("ERROR: pulse periode == '" .. periode .. "'; must be a multiple of 100 and in range 200-5000")
                return false
            end
            cli("help.debug.output.output=" .. output)
            cli("help.debug.output.change=" .. state)
            if state == "pulses" then
                cli("help.debug.output.pulses=" .. pulses)
                cli("help.debug.output.periode=" .. periode)
            end
            local result = cli("help.debug.output.submit")
            if result == "manual action failed" then
                return false
            end
            return true
        end

        return self
    end

    lua_log("Start initialising Classes")
    selfs = {}
    selfs.Helper = Helper()
    selfs.Interfaces = Interfaces()
    selfs.Ports = Ports()
    selfs.Ios = IOs()
    selfs.Messages = Messages()
    selfs.Connectivity = Connectivity()
    lua_log("Initialising classes complete")
    return selfs
end

return Classes()

-----LUA-----
