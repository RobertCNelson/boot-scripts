

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
# This function will set the LED brigtness 
######################################################################################
import logging
from control import *
import time,datetime
from Constants import *
from sys import * 

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

	if (len(argv)==4):
		DPP2607_Write_LedCurrentRed(int(argv[1]))
		DPP2607_Write_LedCurrentGreen(int(argv[2]))
		DPP2607_Write_LedCurrentBlue(int(argv[3]))
		DPP2607_Write_PropagateLedCurrents(1)

	# cleanup
	DPP2607_Close()
	datalog.close()

		
if __name__ == "__main__":
    main()


