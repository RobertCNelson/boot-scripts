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
# This function will access the sequence stored in the flash
# Assume sequence from 0 to 6
######################################################################################
import logging
from control import *
import time,datetime
from Constants import *

source_defs = [
	(DPP2607_Write_VideoSourceSelection,(SourceSel.INTERNAL_TEST_PATTERNS,),"",""),
	(DPP2607_Write_VideoResolution,(Resolution.NHD_LANDSCAPE,),"",""),
	(DPP2607_Write_SequenceSelect,(CompoundLooks.SEQUENCE_0,),"Checker Box (Sequence 0) Test","Does the Checker Box display OK? (Pass/Fail/Stop)"),
	(DPP2607_Write_SequenceSelect,(CompoundLooks.SEQUENCE_1,),"Checker Box (Sequence 1) Test","Does the Checker Box display OK? (Pass/Fail/Stop)"),
	(DPP2607_Write_SequenceSelect,(CompoundLooks.SEQUENCE_2,),"Checker Box (Sequence 2) Test","Does the Checker Box display OK? (Pass/Fail/Stop)"),
	(DPP2607_Write_SequenceSelect,(CompoundLooks.SEQUENCE_3,),"Checker Box (Sequence 3) Test","Does the Checker Box display OK? (Pass/Fail/Stop)"),
	(DPP2607_Write_SequenceSelect,(CompoundLooks.SEQUENCE_4,),"Checker Box (Sequence 4) Test","Does the Checker Box display OK? (Pass/Fail/Stop)"),
	(DPP2607_Write_SequenceSelect,(CompoundLooks.SEQUENCE_5,),"Checker Box (Sequence 5) Test","Does the Checker Box display OK? (Pass/Fail/Stop)"),
	(DPP2607_Write_SequenceSelect,(CompoundLooks.SEQUENCE_6,),"Checker Box (Sequence 6) Test","Does the Checker Box display OK? (Pass/Fail/Stop)"),
]

def main(task=None):
	Test_name = 'Look - Checker Box Sequence Test'
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


