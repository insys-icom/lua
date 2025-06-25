-----LUA-----
-- event starts this script, extract information from message, change hostname, send acknowledgement message

-- get objects of class
C = require("Classes")
Messages = C.Messages

-- extract message information
event_id, message, modem, sender = Messages.message_event_extraction()

-- find hostname in message
new_hostname = message:match("Hostname = (%a)")

-- set new hostname
ret = pcall(cli, "administration.hostnames.hostname=" .. new_hostname)

-- activate profile and send acknowledgement back to sender
if ret then
    cli("administration.profiles.activate")
    Messages.send_sms(sender, "Change was successfull", modem)
end

-----LUA-----

