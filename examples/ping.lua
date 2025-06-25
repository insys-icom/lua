-----LUA-----
-- ping checks

-- get object of class
C = require("Classes")
Con = C.Connectivity

-- ping function has 3 parameters
-- Parameter 1: destination (IP address or Domain)
-- Parameter 2 (OPTIONAL): intterface to ping from (eg. net1)
-- Parameter 3 (OPTIONAL): number of pings

-- ping a v4 address
ok1, result1 = Con.ping("8.8.8.8")

-- ping from a specific interface
ok2, result2 = Con.ping("8.8.8.8", "net1")

-- do 5 pings
ok3, result3 = Con.ping("8.8.8.8", "net1", 5)

-- ping a v6 address
-- other 2 parameters can be set like above or left out individually
okv6, resultv6 = Con.ping6("2001:4860:4860::8888")

-- for additional DNS lookup, use Domain for destination
okns, resultns = Con.ping("google.de")
oknsv6, resultnsv6 = Con.ping6("google.de")

-- first return values indicate if ping was successfull or not
-- result is a table that can be used for futher analysis
packet_loss_ping1 = result1.packet_loss
result_message_ping1 = result1.result_message
exit_code_ping1 = result1.exit_code

-- Ping for multiple addresses at once
address_table = {"192.168.1.3, 192.168.2.1, google.de, wikipedia.org"}

for i = 1, #address_table do
    ok = Con.ping(address_table[i])
    if not ok then
        -- do something
    end
end

-----LUA-----
