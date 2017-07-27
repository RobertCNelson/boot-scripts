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
# This function will verify the device by  checking software version, communication status, temperature
######################################################################################
import logging
from control import *
import time,datetime
from Constants import *

	
source_defs = [
	(DPP2607_Read_EmbeddedSoftwareVersion,(),"Status - Read Embedded Software", "Do you get the value (patch=3, minor=6, major=1)?"),
#	(DPP2607_Read_SystemStatus,(),"Status - Read System Status", "Do you get the status Yes/No/Stop (StatInit,StatFlash, StatPAD, StatLED, StatBIST) ?"),
#	(DPP2607_Read_DeviceStatus,(),"Status - Read Device Status", "Do you get the device status? (DevID,DevFlashStatus,DevInitStatus,DevLEDStatus)"),
	(DPP2607_Read_CommunicationStatus,(),"Status - Communication status","Is the status reading ok (compound_stat_inv_cmd, compound_stat_par_cmd, compound_stat_mem_rd, compound_stat_cmd_par, compound_stat_cmd_abt)?"),
#	(DPP2607_Read_InterruptStatus,(),"Status - Interrupt status","Is the status reading ok (int_seq_abort, int_dmd_reset_overrun, int_dmd_block_error, int_dmdif_overrun, int_format_buf_overflow, int_format_starvation, int_flash_fifo_err, int_flash_dma_err, int_format_mult_err, int_format_cmd_err, int_format_queue_warn, int_ddr_overflow_bp, int_ddr_overflow_fb, int_scaler_line_err, int_scaler_pixerr, int_led_timeout) ?"),
]

def main(task=None):
	Test_name = 'Status'
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


