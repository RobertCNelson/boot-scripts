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
# This function is for enviornmental test. It will display all splash screen and 
# query the temperature
######################################################################################
import logging
from control import *
import time,datetime
from Constants import *

source_defs = [
	(DPP2607_Write_VideoSourceSelection,(SourceSel.EXTERNAL_VIDEO_PARALLEL_I_F_,),"",""),
	(DPP2607_Write_VideoResolution,(Resolution.NHD_LANDSCAPE,),"",""), #640x360
	(DPP2607_Write_VideoPixelFormat,(RGB888_24_BIT,),"",""),

	(DPP2607_Write_LedDriverEnable,(ENABLED,ENABLED,ENABLED), "", ""),
	
	(DPP2607_Write_DisplayCurtainControl,(ENABLED,DMDCurtainColor.RED),"RED Curatin Test","Does the RED curtain display correct? (Pass/Fail/Stop)"),
	(DPP2607_Write_LedCurrentRed,(800,),"",""),
	(DPP2607_Write_LedCurrentGreen,(800,),"",""),
	(DPP2607_Write_LedCurrentBlue,(800,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"",""),
	(time.sleep,(1,),"",""),
	(DPP2607_Write_LedCurrentRed,(300,),"",""),
	(DPP2607_Write_LedCurrentGreen,(300,),"",""),
	(DPP2607_Write_LedCurrentBlue,(300,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"",""),	
	(time.sleep,(1,),"",""),
	(DPP2607_Write_DisplayCurtainControl,(ENABLED,DMDCurtainColor.GREEN),"GREEN Curatin Test","Does the GREEN curtain display correct? (Pass/Fail/Stop)"),
	(DPP2607_Write_LedCurrentRed,(800,),"",""),
	(DPP2607_Write_LedCurrentGreen,(800,),"",""),
	(DPP2607_Write_LedCurrentBlue,(800,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"",""),
	(time.sleep,(1,),"",""),
	(DPP2607_Write_LedCurrentRed,(300,),"",""),
	(DPP2607_Write_LedCurrentGreen,(300,),"",""),
	(DPP2607_Write_LedCurrentBlue,(300,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"",""),
	(time.sleep,(1,),"",""),
	(DPP2607_Write_DisplayCurtainControl,(ENABLED,DMDCurtainColor.BLUE),"BLUE Curatin Test","Does the BLUE curtain display correct? (Pass/Fail/Stop)"),
	(DPP2607_Write_LedCurrentRed,(800,),"",""),
	(DPP2607_Write_LedCurrentGreen,(800,),"",""),
	(DPP2607_Write_LedCurrentBlue,(800,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"",""),
	(time.sleep,(1,),"",""),
	(DPP2607_Write_LedCurrentRed,(300,),"",""),
	(DPP2607_Write_LedCurrentGreen,(300,),"",""),
	(DPP2607_Write_LedCurrentBlue,(300,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"",""),
	(time.sleep,(1,),"",""),
	(DPP2607_Write_DisplayCurtainControl,(ENABLED,DMDCurtainColor.YELLOW),"YELLOW Curatin Test","Does the YELLOW curtain display correct? (Pass/Fail/Stop)"),
	(DPP2607_Write_LedCurrentRed,(800,),"",""),
	(DPP2607_Write_LedCurrentGreen,(800,),"",""),
	(DPP2607_Write_LedCurrentBlue,(800,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"",""),
	(time.sleep,(1,),"",""),
	(DPP2607_Write_LedCurrentRed,(300,),"",""),
	(DPP2607_Write_LedCurrentGreen,(300,),"",""),
	(DPP2607_Write_LedCurrentBlue,(300,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"",""),
	(time.sleep,(1,),"",""),
	(DPP2607_Write_DisplayCurtainControl,(ENABLED,DMDCurtainColor.MAGENTA),"MAGENTA Curatin Test","Does the MAGENTA curtain display correct? (Pass/Fail/Stop)"),
	(DPP2607_Write_LedCurrentRed,(800,),"",""),
	(DPP2607_Write_LedCurrentGreen,(800,),"",""),
	(DPP2607_Write_LedCurrentBlue,(800,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"",""),
	(time.sleep,(1,),"",""),
	(DPP2607_Write_LedCurrentRed,(300,),"",""),
	(DPP2607_Write_LedCurrentGreen,(300,),"",""),
	(DPP2607_Write_LedCurrentBlue,(300,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"",""),
	(time.sleep,(1,),"",""),
	(DPP2607_Write_DisplayCurtainControl,(ENABLED,DMDCurtainColor.CYAN),"CYAN Curatin Test","Does the CYAN curtain display correct? (Pass/Fail/Stop)"),
	(DPP2607_Write_LedCurrentRed,(800,),"",""),
	(DPP2607_Write_LedCurrentGreen,(800,),"",""),
	(DPP2607_Write_LedCurrentBlue,(800,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"",""),
	(time.sleep,(1,),"",""),
	(DPP2607_Write_LedCurrentRed,(300,),"",""),
	(DPP2607_Write_LedCurrentGreen,(300,),"",""),
	(DPP2607_Write_LedCurrentBlue,(300,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"",""),
	(time.sleep,(1,),"",""),
	(DPP2607_Write_DisplayCurtainControl,(ENABLED,DMDCurtainColor.WHITE),"WHITE Curatin Test","Does the WHITE curtain display correct? (Pass/Fail/Stop)"),
	(DPP2607_Write_LedCurrentRed,(800,),"",""),
	(DPP2607_Write_LedCurrentGreen,(800,),"",""),
	(DPP2607_Write_LedCurrentBlue,(800,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"",""),
	(time.sleep,(1,),"",""),
	(DPP2607_Write_LedCurrentRed,(300,),"",""),
	(DPP2607_Write_LedCurrentGreen,(300,),"",""),
	(DPP2607_Write_LedCurrentBlue,(300,),"",""),
	(DPP2607_Write_PropagateLedCurrents,(1,),"",""),
	(time.sleep,(1,),"",""),

	(DPP2607_Write_VideoSourceSelection,(SourceSel.SPLASH_SCREEN,),"",""),
	(DPP2607_Write_DisplayCurtainControl,(DISABLED,WHITE),"",""),
	(DPP2607_Write_VideoResolution,(Resolution.QWVGA_LANDSCAPE,),"",""),
	(DPP2607_Write_VideoPixelFormat,(PixFormat.RGB888_24_BIT_,),"",""),
	(time.sleep,(1,),"",""),
	(DPP2607_Write_SetSplashScreen,(SPLASH_IMAGE_0,),"Environmental Test - Splash 0 (DLP Logo)","Does the Splash screen display (DLP Logo) correct? (Pass/Fail,Stop)"),
	(DPP2607_Write_SetSplashScreen,(SPLASH_IMAGE_1,),"Environmental Test - Splash 1 (Color Pattern)","Does the Splash screen display (Color Pattern) correct? (Pass/Fail,Stop)"),
	(DPP2607_Write_SetSplashScreen,(SPLASH_IMAGE_2,),"Environmental Test - Splash 2 (Girl/Flower)","Does the Splash screen display (Girl/Flower) correct? (Pass/Fail,Stop)"),
	(DPP2607_Write_SetSplashScreen,(SPLASH_IMAGE_3,),"Environmental Test - Splash 3 (Color Pattern)","Does the Splash screen display (Color Pattern) correct? (Pass/Fail,Stop)"),
	(DPP2607_Write_SetSplashScreen,(OPTICAL_TEST_IMAGE,),"Environmental Test - OPTICAL IMAGE (Grid)","Does the optical image (Grid) display correct? (Pass/Fail,Stop)"),
]

def main(task=None):
	Test_name = 'Environmental Test'
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


