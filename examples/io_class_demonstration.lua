-----LUA-----
-- how to use the IO class

-- create object of class
-- IOs will be automatically detected
C = require("Classes")
IOs = C.Ios

-- get digital IOs
digital_inputs = IOs.get_digital_inputs()
digital_outputs = IOs.get_digital_outputs()

--get analog IOs
analog_inputs = IOs.get_analog_inputs()
analog_outputs = IOs.get_analog_outputs()

-- all IOs are stored in a table and have an Index eg. "3.1"
-- analog IOs have suffix "a" in their index eg. "3.1a"
-- first number is the slot, where the IO exists
-- second number is the IO number. If more than one exists, they will list as: "3.1, 3.2, 3.3" and so on

-- get Input or Output with all its attributes
-- ret returns true/false if function was successfull
ret, input_1 = IOs.get_input("3.1")
ret, output_1 = IOs.get_output("2.1")

ret, analog_input_1 = IOs.get_input("3.1a")

-- both inputs and outputs have the following attributes
input_1_state = input_1.status -- state of IO (inputs: high/low, outputs: open/closed)
input_1_card = input_1.on_card -- card the IO is on eg. lte_serial2
input_1_index = input_1.index -- io index -> key as a value

-- getter functions update the entry/attrbute of IO in table an returns the attribute
-- all getter functions have a second parameter 'direction' (1 = input, 0 = output)

-- return state of io (inputs = high/low, outputs = open/closed, analog IO = voltage/current value)
ret, input_1_state = IOs.get_io_state("3.1", 1)
ret, analog_output_1_state = IOs.get_io_state("3.1a", 0)

-- log I/O state change
-- first return value: if state was changed ret == true else false
-- second return value: state of examined IO
ret, input_1_new_state = IOs.get_io_state_change("3.1", 1)
ret, analog_output_1_new_state = IOs.get_io_state_change("3.1a", 0)

-- return the card the IO resides on -> also gives the slot implicitely
ret, card_of_input_1 = IOs.get_card_of_io("3.1", 1)
ret, card_of_analog_output_1 = IOs.get_card_of_io("3.1a", 0)

-- update table of I/Os
IOs.update_ios()

-- set the voltage of an analog output and get value
-- sets also the analog output to that mode (current or voltage) and updates table entry
-- return true or false if success
-- suffix 'a' does not need to be added for setting analog I/Os
ret = IOs.set_analog_output_voltage("3.1", 4) -- set to 4V
ret, voltage_of_analog_output_1 = IOs.get_io_state("3.1a", 0)

-- set current of analog output and get value
ret = IOs.set_analog_output_current("3.1", 10) -- set to 10mA
ret, current_of_analog_output_1 = IOs.get_io_state("3.1a", 0)

-- set mode of analog input and get value
ret = IOs.set_analog_input("3.2", "current")
ret,current_of_analog_input2 = IOs.get_io_state("3.2a", 1)

-- set digital output to desired parameters
-- Parameter 1: digital output
-- Parameter 2: state of output (closed/open/toggle/pulses);
--              'toggle' changes state regardles of previous one
--              'pulses' outputs a pulse squence
-- Parameter 3 (if state == pulses): number of pulses in range 1-255
-- Parameter 4 (if state == pulses): periode of pulses in range 200-5000ms -> must be a multiple of 100
ret = IOs.set_digital_output("3.3", "close")
ret, state_of_digital_ouput_3 = IOs.get_io_state("3.3", 0)

-- create pulses in digital ouput '3.3'
ret = IOs.set_digital_output("3.3", "pulses", 5, 300)

-----LUA-----

