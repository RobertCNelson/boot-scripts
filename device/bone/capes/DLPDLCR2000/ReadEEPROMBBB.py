# DLPDLCR2000EVM Example Test Script Suite
#
# Implements basic functionality of DLP LightCrafter Display 2000 EVM 
# using included python library
#
# Copyright (C) 2017 Texas Instruments Incorporated - http://www.ti.com/ 
# 
# 
#  Redistribution and use in source and binary forms, with or without 
#  modification, are permitted provided that the following conditions 
#  are met:
#
#    Redistributions of source code must retain the above copyright 
#    notice, this list of conditions and the following disclaimer.
#
#    Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the 
#    documentation and/or other materials provided with the   
#    distribution.
#
#    Neither the name of Texas Instruments Incorporated nor the names of
#    its contributors may be used to endorse or promote products derived
#    from this software without specific prior written permission.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
#  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
#  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
#  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
#  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT 
#  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
#  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
#  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
#  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

######################################################################################
# This function will read the CAPE EEPROM
######################################################################################
import logging
from control import *
import time,datetime
from Constants import *

def read_eeprom(bus, slave_addr, mem_addr, length):
	with open('/sys/bus/i2c/devices/%01d-00%02d/eeprom' % (bus, slave_addr), 'r') as f:
		f.seek(mem_addr)
		payload = f.read(length)
	plist = list(payload)
	log(DEBUG, 'EEPROM Value %r', plist)
	return plist
	
source_defs = [
	(read_eeprom,(2,57,0,4),"Data - Read EEPROM", "Do you get the value?"),
	(read_eeprom,(2,57,4,4),"Data - Read EEPROM", "Do you get the value?"),
	(read_eeprom,(2,57,8,4),"Data - Read EEPROM", "Do you get the value?"),
	(read_eeprom,(2,57,12,4),"Data - Read EEPROM", "Do you get the value?"),
]

def main(task=None):
	Test_name = 'Read Cape EEPROM'
	#Filepath_n,
	
	# setup the Test name
	datalog = DataLog(LogDir, Test_name)

	print "\n********** Make sure have permission to /sys/bus/i2c/devices/2-0057/eeprom **********\n"
	time.sleep(4)
	# general setup
	logging.getLogger().setLevel(logging.ERROR)

	try:
		callTable(Test_name,datalog,source_defs);
			
	except Exception:
		print "Test failed Exception"
		datalogConstants(datalog)
		datalog.add_col('Test name', Test_name)
		datalog.add_col('End Time',' '+str(datetime.datetime.now()))
		datalog.add_col('Result', "Test Fail EXCEPTION")        
		datalog.add_col('P/F Result', "Fail")
		datalog.log()

	finally:
		# cleanup
		return

		
if __name__ == "__main__":
	main()

