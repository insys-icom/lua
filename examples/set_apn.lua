-- io has changed something
-- at least one IO example
-----LUA-----
-- set apn and activate profile

-- get objects from class
C = require("Classes")
Interfaces = C.Interfaces

-- creat apn table
-- keys should be imsi or usim of sim card
-- value should be apn of provider
apn_table = {
    ["26201"] = "internet.telekom",
    ["26202"] = "web.vodafone.de",
    ["24007"] = "m2m.tele2.com"
}

-- set apn
-- Parameter 1: Modem with SIM card
-- Parameter 2: apn table
-- Parameter 3 (Optional): how long the function searches for usim or imsi, if not immediately set after inserting

-- if table has imsi as keys
success = Interfaces.set_apn_by_imsi("lte_serial2", apn_table, 20)

-- if table has usim as keys
success = Interfaces.set_apn_by_usim("lte_serial2", apn_table, 20)

-- activate profile
cli("administration.profiles.activate")

-----LUA-----