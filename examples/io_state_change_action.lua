-----LUA-----
-- switch interface of port

-- get objects of class
C = require("Classes")
Ports = C.Ports
IOs = C.Ios
Interfaces = C.Interfaces

-- get ethernet ports and digital inputs
eth_ports = Ports.get_ethernet_ports()
digital_inputs = IOs.get_digital_inputs()
ipnet_interfaces = Interfaces.get_ip_net_interfaces()

-- get state of IO 2.1
ret, input_21_state = IOs.get_io_state("2.1", 1)

-- get current interface of Port 3 on slot 1
ret, current_ip_net = Ports.get_port_net("1.3")

-- change Interface if IO state has changed
while true do
    state_has_changed, new_status = IOs.get_io_state_change("2.1", 1)
    if state_has_changed and new_status == "high" then
        if current_ip_net ~= "net2" then
            Ports.set_port_net("1.3", "net2")
            break
        end
    end
end

-----LUA-----
