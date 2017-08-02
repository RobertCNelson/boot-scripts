
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
# This function will test the LED brigtness from 1000 to 200. After the test, it will be set back to 300
######################################################################################
import logging
from control import *
import time,datetime
from Constants import *

source_defs = [
	(DPP2607_Write_DisplayCurtainControl,(ENABLED,DMDCurtainColor.WHITE),"",""),
	
	(DPP2607_Write_LedCurrentRed,(800,),"",""),
	(DPP2607_Write_LedCurrentGreen,(800,),"",""),
	(DPP2607_Write_LedCurrentBlue,(800,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"",""),
	(DPP2607_Write_LedDriverEnable,(ENABLED,ENABLED,ENABLED), "", ""),

	(DPP2607_Write_LedDriverEnable,(ENABLED,DISABLED,DISABLED), "", ""),
	(DPP2607_Write_LedCurrentRed,(1000,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"RED LED set 1000","Do you see a RED LED? (Pass/Fail/Stop)"),
	(DPP2607_Write_LedCurrentRed,(700,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"RED LED set 700","Do you see a RED LED? (Pass/Fail/Stop)"),
	(DPP2607_Write_LedCurrentRed,(600,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"RED LED set 600","Do you see a RED LED? (Pass/Fail/Stop)"),
	(DPP2607_Write_LedCurrentRed,(500,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"RED LED set 500","Do you see a RED LED? (Pass/Fail/Stop)"),
	(DPP2607_Write_LedCurrentRed,(400,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"RED LED set 400","Do you see a RED LED? (Pass/Fail/Stop)"),
	(DPP2607_Write_LedCurrentRed,(300,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"RED LED set 300","Do you see a RED LED? (Pass/Fail/Stop)"),
	(DPP2607_Write_LedCurrentRed,(200,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"RED LED set 200","Do you see a RED LED? (Pass/Fail/Stop)"),

	(DPP2607_Write_LedDriverEnable,(DISABLED,ENABLED,DISABLED), "", ""),
	(DPP2607_Write_LedCurrentGreen,(1000,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"GREEN LED set 1000","Do you see a GREEN LED? (Pass/Fail/Stop)"),
	(DPP2607_Write_LedCurrentGreen,(700,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"GREEN LED set 700","Do you see a GREEN LED? (Pass/Fail/Stop)"),
	(DPP2607_Write_LedCurrentGreen,(600,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"GREEN LED set 600","Do you see a GREEN LED? (Pass/Fail/Stop)"),
	(DPP2607_Write_LedCurrentGreen,(500,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"GREEN LED set 500","Do you see a GREEN LED? (Pass/Fail/Stop)"),
	(DPP2607_Write_LedCurrentGreen,(400,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"GREEN LED set 400","Do you see a GREEN LED? (Pass/Fail/Stop)"),
	(DPP2607_Write_LedCurrentGreen,(300,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"GREEN LED set 300","Do you see a GREEN LED? (Pass/Fail/Stop)"),
	(DPP2607_Write_LedCurrentGreen,(200,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"GREEN LED set 200","Do you see a GREEN LED? (Pass/Fail/Stop)"),

	(DPP2607_Write_LedDriverEnable,(DISABLED,DISABLED,ENABLED), "", ""),
	(DPP2607_Write_LedCurrentBlue,(1000,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"BLUE LED set 1000","Do you see a BLUE LED? (Pass/Fail/Stop)"),
	(DPP2607_Write_LedCurrentBlue,(700,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"BLUE LED set 700","Do you see a BLUE LED? (Pass/Fail/Stop)"),
	(DPP2607_Write_LedCurrentBlue,(600,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"BLUE LED set 600","Do you see a BLUE LED? (Pass/Fail/Stop)"),
	(DPP2607_Write_LedCurrentBlue,(500,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"BLUE LED set 500","Do you see a BLUE LED? (Pass/Fail/Stop)"),
	(DPP2607_Write_LedCurrentBlue,(400,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"BLUE LED set 400","Do you see a BLUE LED? (Pass/Fail/Stop)"),
	(DPP2607_Write_LedCurrentBlue,(300,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"BLUE LED set 300","Do you see a BLUE LED? (Pass/Fail/Stop)"),
	(DPP2607_Write_LedCurrentBlue,(200,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"BLUE LED set 200","Do you see a BLUE LED? (Pass/Fail/Stop)"),
	
	(DPP2607_Write_LedCurrentRed,(300,),"",""),
	(DPP2607_Write_LedCurrentGreen,(300,),"",""),
	(DPP2607_Write_LedCurrentBlue,(300,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"",""),
	(DPP2607_Write_LedDriverEnable,(ENABLED,ENABLED,ENABLED), "", ""),
	(DPP2607_Write_DisplayCurtainControl,(DISABLED,DMDCurtainColor.WHITE),"",""),

]

def main(task=None):
	Test_name = 'LEDTest'
	#Filepath_n,
	
	# setup the Test name
	datalog = DataLog(LogDir, Test_name)

	# general setup
	logging.getLogger().setLevel(logging.ERROR)
	DPP2607_Open()
	DPP2607_SetSlaveAddr(SlaveAddr)
	DPP2607_SetIODebug(IODebug)

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
		DPP2607_Close()
		datalog.close()

		
if __name__ == "__main__":
    main()


