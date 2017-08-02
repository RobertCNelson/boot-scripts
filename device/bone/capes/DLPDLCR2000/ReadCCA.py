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
# This function will read all the CCA setting. In addition, it will write a different value to validate
# there is no issue in writting. Final, a system reset will change all value back to default
######################################################################################
import logging
from control import *
import time,datetime
from Constants import *
	
source_defs = [
	(DPP2607_Read_CcaC1r1Coefficient,(),"CCA read C1R1","Does the CCA C1R1 Coefficient correct? (def 256) (Pass/Fail/Stop)"),
	(DPP2607_Read_CcaC1r2Coefficient,(),"CCA read C1R2","Does the CCA C1R2 Coefficient correct? (def 0) (Pass/Fail/Stop)"),
	(DPP2607_Read_CcaC1r3Coefficient,(),"CCA read C1R3","Does the CCA C1R3 Coefficient correct? (def 0) (Pass/Fail/Stop)"),
	(DPP2607_Read_CcaC2r1Coefficient,(),"CCA read C2R1","Does the CCA C2R1 Coefficient correct? (def 0) (Pass/Fail/Stop)"),
	(DPP2607_Read_CcaC2r2Coefficient,(),"CCA read C2R2","Does the CCA C2R2 Coefficient correct? (def 256) (Pass/Fail/Stop)"),
	(DPP2607_Read_CcaC2r3Coefficient,(),"CCA read C2R3","Does the CCA C2R3 Coefficient correct? (def 0) (Pass/Fail/Stop)"),
	(DPP2607_Read_CcaC3r1Coefficient,(),"CCA read C3R1","Does the CCA C3R1 Coefficient correct? (def 0) (Pass/Fail/Stop)"),
	(DPP2607_Read_CcaC3r2Coefficient,(),"CCA read C3R2","Does the CCA C3R2 Coefficient correct? (def 0) (Pass/Fail/Stop)"),
	(DPP2607_Read_CcaC3r3Coefficient,(),"CCA read C3R3","Does the CCA C3R3 Coefficient correct? (def 256) (Pass/Fail/Stop)"),
	(DPP2607_Read_CcaC4r1Coefficient,(),"CCA read C4R1","Does the CCA C4R1 Coefficient correct? (def 0) (Pass/Fail/Stop)"),
	(DPP2607_Read_CcaC4r2Coefficient,(),"CCA read C4R2","Does the CCA C4R2 Coefficient correct? (def 256) (Pass/Fail/Stop)"),
	(DPP2607_Read_CcaC4r3Coefficient,(),"CCA read C4R3","Does the CCA C4R3 Coefficient correct? (def 256)  (def 256) (Pass/Fail/Stop)"),
	(DPP2607_Read_CcaC5r1Coefficient,(),"CCA read C5R1","Does the CCA C5R1 Coefficient correct? (def 256) (Pass/Fail/Stop)"),
	(DPP2607_Read_CcaC5r2Coefficient,(),"CCA read C5R2","Does the CCA C5R2 Coefficient correct? (def 0) (Pass/Fail/Stop)"),
	(DPP2607_Read_CcaC5r3Coefficient,(),"CCA read C5R3","Does the CCA C5R3 Coefficient correct? (def 256) (Pass/Fail/Stop)"),
	(DPP2607_Read_CcaC6r1Coefficient,(),"CCA read C6R1","Does the CCA C6R1 Coefficient correct? (def 256) (Pass/Fail/Stop)"),
	(DPP2607_Read_CcaC6r2Coefficient,(),"CCA read C6R2","Does the CCA C6R2 Coefficient correct? (def 256) (Pass/Fail/Stop)"),
	(DPP2607_Read_CcaC6r3Coefficient,(),"CCA read C6R3","Does the CCA C6R3 Coefficient correct? (def 0) (Pass/Fail/Stop)"),
	(DPP2607_Read_CcaC7r1Coefficient,(),"CCA read C7R1","Does the CCA C7R1 Coefficient correct? (def 256) (Pass/Fail/Stop)"),
	(DPP2607_Read_CcaC7r2Coefficient,(),"CCA read C7R2","Does the CCA C7R2 Coefficient correct? (def 256) (Pass/Fail/Stop)"),
	(DPP2607_Read_CcaC7r3Coefficient,(),"CCA read C7R3","Does the CCA C7R3 Coefficient correct? (def 256) (Pass/Fail/Stop)"),

	(DPP2607_Write_CcaC1r1Coefficient,(256,),"",""),
	(DPP2607_Write_CcaC1r2Coefficient,(256,),"",""),
	(DPP2607_Write_CcaC1r3Coefficient,(256,),"",""),
	(DPP2607_Read_CcaC1r1Coefficient,(),"CCA read C1R1","Does the CCA C1R1 Coefficient correct? (should be 256) (Pass/Fail/Stop)"),
	(DPP2607_Read_CcaC1r2Coefficient,(),"CCA read C1R2","Does the CCA C1R2 Coefficient correct? (should be 256) (Pass/Fail/Stop)"),
	(DPP2607_Read_CcaC1r3Coefficient,(),"CCA read C1R3","Does the CCA C1R3 Coefficient correct? (should be 256) (Pass/Fail/Stop)"),
	
	(DPP2607_Write_CcaFunctionEnable,(0,),"CCA Function Control","Does the display updated? (Pass/Fail/Stop)"),
	(DPP2607_Write_CcaFunctionEnable,(1,),"CCA Function Control","Does the display updated? (Pass/Fail/Stop)"),
# system reset will reset the CCA value
	(DPP2607_Write_SystemReset,(),"",""),
]

def main(task=None):
	Test_name = 'Read CCA Coefficient'
	#Filepath_n,
	
	# setup the Test name
	datalog = DataLog('.', Test_name)

	# general setup
	logging.getLogger().setLevel(logging.ERROR)
	DPP2607_Open()
	DPP2607_SetSlaveAddr(SlaveAddr)
	DPP2607_SetIODebug(False)

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


