-----LUA-----
-- find and modify a netfilter using indexes

-- get an object from the class
C = require("Classes")
Help = C.Helper

-- create a netfilter rule and set its index
cli("netfilter.ip_filter.rule.add")
cli("netfilter.ip_filter.rule[last].rule_description=Allow incoming TCP port 1234")

-- use get_index function, to find index in an endless list
-- Parameter 1: cli command
-- Parameter 2: desired pattern to search for
-- find first netfilter rule with pattern in description
ok, index = Help.get_index_by_description(cli("netfilter.ip_filter.rule"), "1234")

-- change description of previously added netfilter rule
cli("netfilter.ip_filter.rule[" .. index .. "].rule_description=[@ added by script] Allow incoming TCP port 1234")
cli("netfilter.ip_filter.rule[" .. index .. "].rule_description=Allow incoming TCP port 1234")

-- create multiple netfilter rules
cli("netfilter.ip_filter.rule.add")
cli("netfilter.ip_filter.rule[last].rule_description=Allow incoming TCP port 5678")
cli("netfilter.ip_filter.rule.add")
cli("netfilter.ip_filter.rule[last].rule_description=Allow incoming TCP port 9012")

-- find all netfilter rules with pattern in description
ok, indexes = Help.get_indexes_by_description(cli("netfilter.ip_filter.rule"), "TCP")

-- change descriptions of all netfilter rules found with pattern
for i, d in pairs(indexes) do
    cli("netfilter.ip_filter.rule[" .. i .. "].rule_description=[@ added by script] " .. d)
end

-- get the third entry found by 'get_indexes_by_description()'
-- uses sort_table function to sort indexes table and search through it
count = 1
entry = 3
for i, d in Help.sort_table(indexes) do
    if count == entry then
        print("Found Entry Nr.3 with Index: " .. i .. " and description " .. d)
        break
    end
    count = count + 1
end

-----LUA-----
