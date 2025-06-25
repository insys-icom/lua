-----LUA-----
-- check state of lte modem and act upon it

-- get object of class
C = require("Classes")
Con = C.Connectivity
Message = C.Messages

-- check state of LTE modem and determine its usability for at least sending sms
-- Parameter 1: if true, modem can at least send a sms else false
-- Parameter 2: 1 == Internet connection, 0 == connected with a provider, -1 == none of the before
ret, state_code = Con.lte_check_state("lte_serial2")

-- restart modem -> also try to connect to a provider
Con.restart_modem("lte_serial2")

-- handle diffrent state codes

if state_code == 1 then
    Con.ping("google.de", "lte2", 3)
elseif state_code == 0 then
    Message.send_sms("+491234567", "i am text", "lte2")
else
    Con.restart_modem("lte2")
end

-----LUA-----
