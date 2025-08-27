# Lua Library for the CLI

This ***Lua Library*** provides a set of functions to:
  - *Extend* and *automate* workflow on INSYS icom routers
  - Build *robust* and *reusable* scripts
  - *Simplify repetitive* CLI calls
  - Implement *dynamic logic* like interface monitoring, redundancy switching or other custom features

## Why *Lua*?

The CLI itself gives a lot of options to set or get certain states from the router or even set up new rules. But it can get *tedious* over time especially if bigger configurations or checks have to be made.

*That is why Lua is offered as a solution.*

Lua is a **lightweight, embeddable** scripting language that is easy to learn and **very efficient** in terms of execution speed and memory footprint.
This makes it perfect for embedded environments like industrial routers.
The syntax is designed to be intuitive, so it can be used by both experienced and inexperienced programmers.

Lua allows to go beyond the static CLI:

- Bundle multiple CLI commands into one script
- Create functions and routines
- Dynamically interact with states or automate status checks
- Respond to events, that aren't supported by the standard CLI like failed pings

**All INSYS icom routers** support a built-in Lua interpreter, also called ***Lua Mode***, that can be activated by placing:

    -----LUA-----

... at the start of a CLI session, ASCII config or script.

---
**IMPORTANT:**
> *Repeat this step at the end of a CLI session or config/script, in order to exit LUA mode. If it's missing in a config/script, then the file can't be uploaded!*
---

*A simple example using CLI calls in Lua:*

    cli("status.sysstat.wan.name") -- gives the name of the currently used wan chain e.g. "wan1"
    cli("status.sysstat.wan.interface[1].if_name") -- gives the name first interface used by the current wan chain e.g. "net1"

*[More information about the CLI and Lua](https://docs.insys-icom.com/docs/en/command-line-interface-cli-en)*


## Why this Library?

Although using CLI calls provide already a great number of possibilities to get/set different router settings, it is however **verbose and gets confusing** as the script grows.

**This is where this library proves to be useful**, because it wraps common tasks into **reusable functions**, reducing repetetive CLI calls, enabling logical abstraction and
making a script more readable and sleek.

---
> *You write what you need*
---

The Library contains these set of **Sub-classes** that cover the following topics:

| Sub-class      | Purpose                            |
|----------------|------------------------------------|
| `Helper`       | General utility                    |
| `Interfaces`   | Manage & detect interfaces         |
| `Ports`        | Manage, configure & detect Ports   |
| `Messages`     | Send SMS, E-mail & preset messages |
| `Connectivity` | Ping, LTE status, modem restart    |
| `IOs`          | Manage, configure & detect I/OS    |

---
## Example: checking connection of port to subnet

### Scenario

You have a MRX5-Router and several other devices connected via ethernet. The connectivity to those devices has to be monitored across various subnets and receive SMS alerts if a link goes down or ping fails.
The goal of this script is to be as **generic** as possible for **minimum maintenance**.

- **with CLI calls only**

        -----LUA-----
        ping_destination = {"192.168.3.1", "192.168.4.1", "192.168.5.1", "192.168.6.1", "192.168.7.1"}

        destination_by_interface = {}
        eth_cards = {}
        lte_modem = ""

        for c = 1, 5 do
            local ok, card = pcall(cli, "status.device_info.slot[" .. c .. "].board_type")
            if not ok then
                break
            end
            if card == "M3SWM" or card == "M3CPU" then
                table.insert(eth_cards, "ethernet" .. c)
            elseif card == "M3PWS" or card == "M3PWL" then
                local ok, connection = pcall(cli, "status.lte" .. c .. ".state")
                if not ok then
                    ok, connection = pcall(cli, "status.lte_serial" .. c .. ".state")
                end
                if connection == "Offline" or connection == "Logged in" or connection == "Online" then
                    lte_modem = "lte" .. c
                end
            end
        end

        for _, ip in ipairs(ping_destination) do
            local subnet = ip:match("(%d+%.%d+%.%d+)%.%d+")
            for n = 1, cli("interfaces.ip_nets.net.size") do
                for i = 1, cli("interfaces.ip_nets.net[" .. n .. "].ip_address.size") do
                    local address = cli("interfaces.ip_nets.net[" .. n .. "].ip_address[" .. i .. "].ip_address")
                    local ipnet = cli("interfaces.ip_nets.net[" .. n .. "].name")
                    if address:find(subnet) and not destination_by_interface[ipnet] then
                        destination_by_interface[ipnet] = ip
                    end
                end
            end
        end

        while true do
            for _, eth_card in ipairs(eth_cards) do
                local slot = eth_card:match("ethernet(%d)")
                for i = 1, cli("status." .. eth_card .. ".port.size") do
                    local link = cli("status." .. eth_card .. ".port[" .. i .. "].link")
                    local net = cli("status." .. eth_card .. ".port[" .. i .. "].port_net")
                    if not destination_by_interface[net] then
                        goto continue
                    end
                    if link == "down" then
                        cli("help.debug.sms.recipient=+49123456789")
                        cli("help.debug.sms.text=-----TEXT BEGIN-----Port ".. slot .. "." .. i .." is down-----TEXT END-----")
                        cli("help.debug.sms.modem=" .. lte_modem)
                        cli("help.debug.sms.submit")
                    else
                        for _, ip in ipairs(destination_by_interface[net]) do
                            ok, result, exit_code = pcall(cli, "help.debug.tool=ping -I " .. net .. " -c1 " ..  ip)
                            if exit_code == 1 then
                                cli("help.debug.sms.recipient=+49123456789")
                                cli("help.debug.sms.text=-----TEXT BEGIN-----Port " .. slot .. "." .. i .." has no connection to " .. ip .. "-----TEXT END-----")
                                cli("help.debug.sms.modem=" .. lte_modem)
                                cli("help.debug.sms.submit")
                            end
                        end
                    end
                    ::continue::
                end
            end
            sleep(30)
        end
        -----LUA-----

- **with `Classes.lua`**

        -----LUA-----
        C = require("Classes")
        Ports = C.Ports
        Con = C.Connectivity
        Messages = C.Messages
        Help = C.Helper
        Interfaces = C.Interfaces
        eth_ports = Ports.get_ethernet_ports()
        ip_net_interfaces = Interfaces.get_ip_net_interfaces()

        ping_destination = {"192.168.3.1", "192.168.4.1", "192.168.5.1", "192.168.6.1", "192.168.7.1"}

        destination_by_interface = {}
        for _, ip in ipairs(ping_destination) do
            local subnet = ip:match("(%d+%.%d+%.%d+)%.%d+")
            for ipnet in pairs(ip_net_interfaces) do
                local exist = Help.get_index("interfaces.ip_nets.net[" .. ip_net_interfaces[ipnet].index .. "].ip_address", subnet, "ip_address")
                if exist then
                    destination_by_interface[ipnet] = destination_by_interface[ipnet] or {}
                    table.insert(destination_by_interface[ipnet], ip)
                end
            end
        end

        while true do
            for port in Help.sort_table(eth_ports) do

                local _, net = Ports.get_port_net(port)
                if not destination_by_interface[net] then
                    goto continue
                end

                local _, link = Ports.get_port_link(port)
                if link == "down" then
                    Messages.send_sms("+49123456789", "Port " .. port .. " is down")
                else
                    for _, ip in ipairs(destination_by_interface[net]) do
                        local success = Con.ping(ip, net)
                        if not success then
                            Messages.send_sms("+49123456789", "Port " .. port .. " has no connection to " .. destination_by_interface[net])
                        end
                    end
                end
                ::continue::
            end
            sleep(30)
        end
        -----LUA-----

---

### Key takeaways

- **Automatic hardware discovery** - no hard-coding of cards, slots, interfaces or ports. It is all detected by initialisation of `Classes.lua`
- **Reduced** code size (64 lines → ~ 40 lines)
- More **readable, maintainable** logic and *less verbose* functions
- **Easier to debug** by using `lua-logs` inside of functions. Every functions first return value is a *boolean* for indication if function did work properly or not
- SMS alert in **one** line (`Messages.send_sms()`)

## Installation

> make sure at least one port set up for router access.
> for CLI make sure, that Port 22 (SSH) is activated
---

*Clone this repo or download **[Classes.lua](https://github.com/insys-icom/lua/archive/refs/heads/main.zip)***

#### via HTTPS/web Browser

1. *Log in* to your router
2. Go to *Administration \=> Profiles*
3. Under *"Import profile or ASCII configuration file"*, click **"Browse..."**
4. Select *`Classes.lua`*
5. Click *Import*

## How to use

1. *Enter* Lua-Mode `-----LUA-----`

2. To *load and use* the library:

       C = require("Classes")

3. *Create objects* of Sub-classes:

        Utility = C.Helper
        Interfaces = C.Interfaces
        Ports = C.Ports
        Messages = C.Messages
        Con = C.Connectivity
        IOs = C.Ios

4. *Call* any sub-class function:

        nameOfSubClass.functionName()

- Example:

      -- Get the interface assigned to port "1.3"
      Ports.get_port_net("1.3")

      -- Ping from net1 to google.de
      Con.ping("google.de", "net1")

      -- Send SMS
      Messages.send_sms("+491234567890", "Ping failed")

- complete Initialization cycle:

        C = require("Classes")
        Ports = C.Ports
        Messages = C.Messages
        Con = C.Connectivity

        Ports.get_port_net("1.3")
        Con.ping("google.de", "net1")
        Messages.send_sms("+491234567890", "Ping failed")

## List of Functions per Subclass

> Function List by Subclass
>
> **This list is always up-to-date and will be expanded continuously.**
---

### `Helper`

| Function | Description |
|-------------------|-------------|
| `table = cli_commands_into_table()` | Converts raw CLI output into a line-based table. |
| `device_type = get_device_type()` | Returns the detected router type (e.g., MRX3, MIRO-L200). |
| `card_types = get_card_types()` | Returns all recognized card types. |
| `cards = get_cards()` | Returns a table of all inserted cards. |
| `ok, card = get_card_of_slot(slot)` | Returns the card type of the given slot. |
| `ok, board = get_board_type_of_slot(slot)` | Returns the board type of the given slot. |
| `add_entry(tbl, entry, val, key)` | Adds an entry to a table, optionally using a key. |
| `delete_entry(tbl, entry, key)` | Removes an entry from a table. |
| `list_table_contents(tbl)` | Prints the contents of a table (debug only). |
| `iter = sort_table(tbl, compare)` | Returns a sorted iterator of a table. \=> best used for sorting hashtables \=> `iter = sort_table` \=> `for k, v in iter(table) do`|
| `ok, index = get_index(cli_path, pattern, entry)` | Finds the first matching index in CLI. |
| `ok, index_table = get_indexes(cli_path, pattern, entry)` | Returns all indexes that match pattern. |
| `ok, index = get_index_by_name(cli_path, name)` | Returns the index for the entry with given name. |
| `ok, index = get_index_by_description(cli_path, pattern)` | Returns index matching description. |
| `ok, index_table = get_indexes_by_description(cli_path, pattern)` | Returns all indexes matching a description pattern. |
| `ok, switched_wan = set_wan_chain(wan_name)` | Sets the given WAN chain as active. |

### `Interfaces`

| Function | Description |
|-------------------|-------------|
| `interfaces = get_ip_net_interfaces()` | Returns all configured IP network interfaces (net1, net2, ...). |
| `vpns = get_vpn_interfaces()` | Returns VPN tunnel interfaces (e.g., OpenVPN, IPsec). |
| `wans = get_wan_interfaces()` | Returns available WAN interfaces (e.g., lte2, dsl3). |
| `addresses = get_ip_addresses(net)` | Returns list of IP addresses assigned to a given network. |
| `ok = set_apn_by_imsi(modem, apn_table, run_time)` | Sets APN based on IMSI detection. |
| `ok = set_apn_by_usim(modem, apn_table, run_time)` | Sets APN based on USIM content. |


### `Ports`

| Function | Description |
|----------|-------------|
| `ports = get_ports()` | Returns all detected ports (Ethernet & SFP). |
| `eth_ports = get_ethernet_ports()` | Returns Ethernet ports only. |
| `sfp_ports = get_sfp_ports()` | Returns SFP ports only. |
| `update_ports()` | Refreshes port detection info. |
| `ok, port_info = get_port(port)` | Returns info for a given port. |
| `ok, link_state = get_port_link(port)` | Returns link state (up/down) of the port. |
| `ok, has_module = get_port_has_sfp_module(port)` | Checks if an SFP module is inserted. |
| `ok, net = get_port_net(port)` | Gets the network assigned to the port. |
| `ok = set_port_net(port, net)` | Assigns a network to the port. |

### `Messages`

| Function | Description |
|----------|-------------|
| `ok = send_email(mail_address, text, subject)` | Sends an email |
| `ok = send_sms(recipient, text, modem)` | Sends SMS using specified or available LTE modem. |
| `ok = send_message(message)` | Sends a preconfigured message. |
| `event_id, message, modem, sender = message_event_extraction()` | Extracts details from last incoming message event. |


### `Connectivity`

| Function | Description |
|----------|-------------|
| `ok, result = ping (dest, net, wait_time, ping_time, ping_interval, num_of_pings)` | Performs IPv4 ping on interface `net` to destination `dest`. |
| `ok, result = ping6(dest, net, wait_time, ping_time, ping_interval, num_of_pings)` | Performs IPv6 ping. |
| `state = lte_check_state(modem)` | Returns LTE modem status (Online, Offline, etc.). |
| `ok = restart_modem(modem)` | Restarts LTE modem and reconnects. |

### `IOs`

| Function | Description |
|----------|-------------|
| `digital_outputs = get_digital_outputs()` | Lists all digital outputs. |
| `digital_inputs = get_digital_inputs()` | Lists all digital inputs. |
| `analog_inputs = get_analog_inputs()` | Lists all analog inputs. |
| `analog_outputs = get_analog_outputs()` | Lists all analog outputs. |
| `ok, input_info = get_input(input)` | Returns info about a digital/analog input. |
| `ok, output_info = get_output(output)` | Returns info about a digital/analog output. |
| `ok, state = get_io_state(io, direction)` | Returns current state of I/O. |
| `ok, changed = get_io_state_change(io, direction)` | Checks if I/O state changed since last check. |
| `ok, card = get_card_of_io(io, direction)` | Returns card where the I/O is located. |
| `update_ios()` | Refreshes I/O state. |
| `ok = set_analog_output_voltage(output, value)` | Sets analog voltage output. |
| `ok = set_analog_output_current(output, value)` | Sets analog current output. |
| `ok = set_analog_input(input, type)` | Sets analog input mode: `"current"` or `"voltage"`. |
| `ok = set_digital_output(output, state, pulses, periode)` | Sets or pulses a digital output. |





