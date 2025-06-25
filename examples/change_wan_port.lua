-----LUA-----
-- make another Port to WAN port, if primary port is down

-- get object of class
C = require("Classes")
Ports = C.Ports

-- set interface of a port to a WAN interface
-- suppose WAN interface is known
wan_net = "net1"

-- get ethernet ports of router
eth_ports = Ports.get_ethernet_ports()

-- set interface of Port "1.2" to wan interface
Ports.set_port_net("1.2", wan_net)

-- simple loop that checks if link of Port "1.2" is down and if so change set wan interface to port "1.3"

while true do
    ret, eth12_link = Ports.get_port_link("1.2")
    if eth12_link == "down" then
        Ports.set_port_net("1.3", wan_net)
        Ports.set_port_net("1.2", "---")
    end
    if eth12_link == "up" and eth12_link ~= wan_net then
        Ports.set_port_net("1.2", wan_net)
        Ports.set_port_net("1.3", "---")
    end
end

-----LUA-----

