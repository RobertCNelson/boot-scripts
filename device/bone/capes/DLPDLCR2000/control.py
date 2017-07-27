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
# This file contains all the helper functions
######################################################################################

import sys
import os
import time,datetime
import logging
######################################################################################
# depends on the library package
from dlp_lightcrafter.dpp2607 import *
from dlp_lightcrafter.datalog import DataLog
######################################################################################
from Constants import *

######################################################################################
#Assume the system perform the following setup as ROOT when system start
#  echo 48 >/sys/class/gpio/export
#  echo out >/sys/class/gpio/gpio48/direction
######################################################################################

skip = 1
######################################################################################
#This function will turn on/off the gpio pin. Such this function should run under BBB
######################################################################################
def ExtProjOnOff(OnOff):
	if (OnOff==1):
		os.system("sudo sh -c 'echo 1 >/sys/class/gpio/gpio48/value'")
	else:
		os.system("sudo sh -c 'echo 0 >/sys/class/gpio/gpio48/value'")

######################################################################################
#This function will play the Video on the display :0 such this function should be executed under BBB
######################################################################################
def Mplayer(VideoFile):
	os.system("export DISPLAY=:0 | mplayer -fs "+VideoFile)

######################################################################################
#This function will call the function with the parameter being listed in plist tuple
######################################################################################
def fun126(fun,plist):
	if (len(plist)==0):
		return fun()
	elif (len(plist)==1):
		print plist[0]
		return fun(plist[0])
	elif (len(plist)==2):
		print plist[0]
		print plist[1]
		return fun(plist[0],plist[1])
	elif (len(plist)==3):
		return fun(plist[0],plist[1],plist[2])
	elif (len(plist)==4):
		return fun(plist[0],plist[1],plist[2],plist[3])

def datalogConstants(datalog):
	datalog.add_col('Station_Name',Station_Name)
	datalog.add_col('Operator',Operator)
	datalog.add_col('DUT_Identity',DUT_Identity)
	datalog.add_col('DUT_Version',DUT_Version)
	datalog.add_col('Device_Identity',Device_Identity)
	datalog.add_col('Device_Version',Device_Version)
	datalog.add_col('Software_Version',Software_Version)
		
######################################################################################
#This function will perform function call based on the input table
######################################################################################		
Line = '##################################################################'
def callTable(Test_name,datalog,source_defs):

	for fun,plist,desc,queryMsg in source_defs:
		if (desc==''):
			result = fun126(fun,plist)
			continue
		datalog.add_col('Start Time',' '+str(datetime.datetime.now()))
		datalogConstants(datalog)
		datalog.add_col('Test name', Test_name)
		###patch, minor, major = DPP2607_Read_EmbeddedSoftwareVersion()
		print Line+'\n'+desc
		datalog.add_col('Desc', desc)
#			datalog.add_col('Start Time',' '+str(datetime.datetime.now()))
		result = fun126(fun,plist)
		datalog.add_col('End Time',' '+str(datetime.datetime.now()))
		print result
		query = Query(queryMsg)
		if query.return_code == Query.STOP:
			print "Stopped"
			datalog.add_col('Result', "User Terminate")
			datalog.add_col('P/F Result', "Fail")
		elif query.return_code == Query.PASS:
			print "Test passed"
			datalog.add_col('Result', "Test Pass")
			datalog.add_col('P/F Result', "Pass")
		elif query.return_code == Query.FAIL:
			print "Test failed"
			datalog.add_col('Result', "Test Fail")
			datalog.add_col('P/F Result', "Fail")
		datalog.add_col('End Time',' '+str(datetime.datetime.now()))
		datalog.add_col('Comment', 'Return:['+str(result)+'] ['+query.comment+']')
		datalog.log()

if sys.platform == 'win32':		
	import msvcrt
	######################################################################################
	# This function will prompt the user and read any input within time defined by t 
	######################################################################################
	def raw_input_with_timeout(prompt,t,ch):
		print "--->"+prompt   
		finishat = time.time() + t 
		result = []
		while True:
			if msvcrt.kbhit():
				result.append(msvcrt.getche())
				if result[-1] == '\r':   # or \n, whatever Win returns;-)
					return ''.join(result)
				time.sleep(0.1)          # just to yield to other processes/threads
			else:
				if time.time() > finishat:
					return ch
else:
	import signal

	class AlarmException(Exception):
		pass

	def alarmHandler(signum, frame):
		raise AlarmException

	def raw_input_with_timeout(prompt, timeout,ch):
		signal.signal(signal.SIGALRM, alarmHandler)
		signal.alarm(timeout)
		try:
			result = raw_input(prompt)
			signal.alarm(0)
			return result
		except AlarmException:
			return ch
		signal.signal(signal.SIGALRM, signal.SIG_IGN)
		signal.alarm(0)
		return ch 

		
######################################################################################
# This function will prompt the user (Stop/Continue). The function will return s for stop, c for continue
######################################################################################
class Prompt(): 
	OK = 0
	STOP = 1
	
	def __init__(self, question):
		self.return_code=''
		while self.return_code=='':
			if skip==1:
				reply = str(raw_input_with_timeout(question+' (Stop/Continue): ',1,'c')).lower().strip() 
			else:
				reply = str(raw_input(question+' (Stop/Continue): ')).lower().strip() 
			if reply=='':
				self.return_code=''
			elif reply[0] == 's': 
				self.return_code = self.STOP 
			elif reply[0] == 'c': 
				self.return_code = self.OK 

######################################################################################
# This function will prompt the user (Pass/Fail/Stop). The function will return p for pass, f for fail, S for stop
######################################################################################
class Query():
	PASS = 0
	FAIL = 1
	STOP = 2

	def __init__(self, question):
		self.return_code=''
		self.comment=''
		while self.return_code=='':
			if skip==1:
				reply = str(raw_input_with_timeout(question+' (Pass/Fail/Stop) and comment: ',1,'p')).lower().strip() 
			else:
				reply = str(raw_input(question+' (Pass/Fail/Stop) and comment: ')).lower().strip() 
			self.comment = '' if (reply.find(' ')==-1) else reply[reply.find(' '):]
			if reply=='':
				self.return_code=''
			elif reply[0] == 'p': 
				self.return_code = self.PASS 
			elif reply[0] == 'f': 
				self.return_code = self.FAIL 
			elif reply[0] == 's': 
				self.return_code = self.STOP 

######################################################################################
# This function will prompt the user (Yes/No/Stop). The function will return y for yes, n for no, s for stop
######################################################################################
class AskYesNo():
	NO = 0
	YES = 1
	STOP = 2
	
	def __init__(self, question):
		self.return_code=''
		while self.return_code=='':
			if skip==1:
				reply = str(raw_input_with_timeout(question+' (Pass/Fail/Stop): ',1,'y')).lower().strip() 
			else:
				reply = str(raw_input(question+' (Yes/No/Stop): ')).lower().strip() 
			if reply=='':
				self.return_code=''
			elif reply[0] == 'n': 
				self.return_code = self.NO 
			elif reply[0] == 'y': 
				self.return_code = self.YES 
			elif reply[0] == 's': 
				self.return_code = self.STOP 
