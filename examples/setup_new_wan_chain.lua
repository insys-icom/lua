-----LUA-----
-- add a new wan chain, add interfaces and change interface and set it to the current one

-- get an object from the class
C = require("Classes")
Help = C.Helper

-- add a new WAN chain and set description
cli("wan.wans.wan_chain.add")
cli("wan.wans.wan_chain[last].description=LTE with VPN")

-- add interfaces to new WAN chain with the index of recently added wan chain
ret, wan_index = Help.get_index_by_description("wan.wans.wan_chain", "LTE with VPN")
cli("wan.wans.wan_chain[" .. wan_index .. "].interface.add")
cli("wan.wans.wan_chain[" .. wan_index .. "].interface[last].interface=lte2")
cli("wan.wans.wan_chain[" .. wan_index .. "].interface.add")
cli("wan.wans.wan_chain[" .. wan_index .. "].interface[last].interface=openvpn1")

-- get index of wan interface with openvpn1
interface_index = Help.get_index("wan.wans.wan_chain[" .. wan_index .. "].interface", "interface", "openvpn1")

-- change interface to ipsec1
cli("wan.wans.wan_chain[" .. wan_index .. "].interface[" .. interface_index .. "].interface=ipsec1")

-- set recently added wan chain to current one
switch_wan = cli("wan.wans.wan_chain[" .. wan_index .. "].name")
Help.set_wan_chain(switch_wan)

-----LUA-----
