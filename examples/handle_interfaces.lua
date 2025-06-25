-----LUA-----
-- get and set interface attributes

-- get an object from the class
C = require("Classes")
Interfaces = C.Interfaces

-- get available interfaces
ipnets = Interfaces.get_ip_net_interfaces()
vpns   = Interfaces.get_vpn_interfaces()
wans   = Interfaces.get_wan_interfaces()

-- get indices of interfaces
net1_index = ipnets["net1"].index
ovpn1_index = vpns["openvpn1"].index

-- get an attribute of an ipnet interface eg. user defined mac address of net1
mac = cli("interfaces.ip_nets.net[" .. net1_index .. "].user_defined_mac")

-- set mode of net1 to eg. WAN by using its index
cli("interfaces.ip_nets.net[" .. net1_index .. "].mode=wan")

-- get an attribute of vpn interface eg. mode of openvpn1
mode = cli("interfaces.openvpn.tunnel[" .. ovpn1_index .. "].mode")

-- change certificate of vpn interface openvpn1
cli("interfaces.openvpn.tunnel[" .. ovpn1_index .. "].ca=ca_cert3")

-----LUA-----
