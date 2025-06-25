-----LUA-----
-- get, set and add ip_addresses of ipnet interface

-- get objects from the class
C = require("Classes")
Help = C.Helper
Interface = C.Interfaces

-- get available ipnet interfaces
ipnets = Interface.get_ip_net_interfaces()

-- get a list of all IP addresses of interface "net1"
net1_addresses = Interface.get_ip_addresses("net1")

-- get first address
net1_ip = net1_addresses[1].address

-- get index of first address
net1_ip_index = net1_addresses[1].index

-- change the first ip address of net1
-- first get index of net1
net1_index = ipnets["net1"].index

-- set ip address
cli("interfaces.ip_nets.net[" .. net1_index .. "].ip_address[" .. net1_ip_index .. "].ip_address=192.168.4.1")

-- add new ip address and set its address and netmask
cli("interfaces.ip_nets.net[" .. net1_index .. "].ip_address.add")
cli("interfaces.ip_nets.net[" .. net1_index .. "].ip_address[last].netmask=24")
cli("interfaces.ip_nets.net[" .. net1_index .. "].ip_address[last].ip_address=192.168.5.3")

-- get information about new ip address by calling get_ip_addresses again (updates used table)
net1_addresses = Interface.get_ip_addresses("net1")

-- get index of last inserted index -> gives also the number of ip_addresses
for k in Help.sort_table(net1_addresses) do
    last_ip_index = k
end

-- change description of previously added ip_address
cli("interfaces.ip_nets.net[" .. net1_index .. "].ip_address[" .. last_ip_index .. "].ip_description=Subnet of Router 123")

-----LUA-----
