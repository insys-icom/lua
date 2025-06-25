-----LUA-----
-- how to use Port class

-- get objects of class, detect ports automatically
C = require("Classes")
Ports = C.Ports

-- get table of ethernet ports and sfp ports
eth_ports = Ports.get_ethernet_ports()
sfp_ports = Ports.get_sfp_ports()

-- choose ports to work with
eth_port13 = Ports.get_port("1.3")
sfp_port51 = Ports.get_port("5.1")

-- every entry in tables have the following attributes
-- attributes apply to both port types

eth13_card  = eth_port13.card  -- name of card the port resides on
eth13_port  = eth_port13.port  -- port, so keys dont have to be extracted
eth13_link  = eth_port13.link  -- link of port can be up/down
eth13_net   = eth_port13.net   -- interface of port

-- attributes exclusive to sfp ports
sfp51_module = sfp_port51.has_module -- if sfp port has a module inserted

-- getter functions are used to get those attributes and update the table by every call
-- attributes are return values

-- suppose, that link has changed
-- call function -> update entries
ret, eth13_new_link = Ports.get_port_link("1.3")

-- or suppose, that sfp-module was removed
-- call function -> update entries
ret, sfp51_module_status = Ports.get_port_has_sfp_module("5.1")

-- change ip interface of a port
ret = Ports.set_port_net("1.3", "net2")
ret = Ports.set_port_net("5.1", "net1")

-- get/check if change was successfull

ret, eth13_new_net = Ports.get_port_net("1.3")
ret, sfp51_new_net = Ports.get_port_net("5.1")

-----LUA-----

