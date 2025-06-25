-- examples for sending messages (predefined, email or sms)
-----LUA-----

-- get an object from the class
C = require("Classes")
Messages = C.Messages

-- send an email
Messages.send_email("anothermail@address.de", "email text", "subject")

-- send a sms (giving modem is optional, default: first modem gets used)
Messages.send_sms("+4912345678", "SMS text", "lte2")

-- send a predefined message stored in the profile
Messages.send_message("message1")



-- utilize tables for sending more than one email
mail_table = {
    a = { mail_address = "mail@fire.com",  text = "hot text",    subject = "Burning Subject" },
    b = { mail_address = "mail@water.com", text = "liquid text", subject = "Wet Subject"     },
    c = { mail_address = "mail@earth.com", text = "hard text",   subject = "Dirty Subject"   },
    d = { mail_address = "mail@air.com",   text = "windy text",  subject = "Breezy Subject"  }
}
for _, v in pairs(mail_table) do
    Messages.send_email(v.mail_address, v.text, v.subject)
end

-----LUA-----
