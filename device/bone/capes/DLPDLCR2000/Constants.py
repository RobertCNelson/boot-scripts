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
# This file contains all the constant. 
######################################################################################

#Test date/Start Time, Start_Time
#Test date/End Time, End_Time
#Test Name,
Station_Name = 'laptop'
Operator = "user"
DUT_Identity = "2607 EVM"
DUT_Version = "version 0.1"
Device_Identity = "2607EVM" 
Device_Version = "version 1.0"
Software_Version = "version test" 
#Result,
#P/F Result, 
#Filepath_n,
LogDir='0524'
SlaveAddr = 0x36
IODebug = False
VG870Port = 7
E34xxPort = 10

# should use the define in dpp2607 class TestPattern(IntEnum):
#    ANSI_4X4_CHECKERBOARD = 0x00
#    SOLID_BLACK = 0x01
#    SOLID_WHITE = 0x02
#    SOLID_GREEN = 0x03
#    SOLID_BLUE = 0x04
#    SOLID_RED = 0x05
#    VERTICAL_LINES_1W_7B_ = 0x06
#    HORIZONTAL_LINES_1W_7B_ = 0x07
#    VERTICAL_LINES_1W_1B_ = 0x08
#    HORIZONTAL_LINES_1W_1B_ = 0x09
#    DIAGONAL_LINES = 0x0A
#    VERTICAL_GREY_RAMPS = 0x0B
#    HORIZONTAL_GREY_RAMPS = 0x0C
#    FINE_CHECKERBOARD = 0x0D	
	
SolidFieldBlack = 1
SolidFieldWhite = 2
SolidFieldGreen = 3
SolidFieldBlue = 4 
SolidFieldRed = 5 

Checkerboard4x4 = 0x0d 
Checkerboard16x9 = 0x00
 
VerticalLines1W7B = 6 
VerticalLines1W1B = 8 

HorizontalLines1W7B = 7 
HorizontalLines1W1B = 9
 
 
# Test Pattern Program
QVGA_PORTRAIT_TEST_PATTERN = 1
QVGA_LANDSCAPE_TEST_PATTERN = 2
QWVGA_PORTRAIT_TEST_PATTERN = 3
QWVGA_LANDSCAPE_TEST_PATTERN = 4
X_2_3_VGA_PORTRAIT_TEST_PATTERN = 5
X_3_2_VGA_LANDSCAPE_TEST_PATTERN = 6
VGA_PORTRAIT_TEST_PATTERN = 7
VGA_LANDSCAPE_TEST_PATTERN = 8
WVGA_720_PORTRAIT_TEST_PATTERN = 9
WVGA_720_LANDSCAPE_TEST_PATTERN = 10
WVGA_752_PORTRAIT_TEST_PATTERN = 11
WVGA_752_LANDSCAPE_TEST_PATTERN = 12
WVGA_800_PORTRAIT_TEST_PATTERN = 13
WVGA_800_LANDSCAPE_TEST_PATTERN = 14
WVGA_852_PORTRAIT_TEST_PATTERN = 15
WVGA_852_LANDSCAPE_TEST_PATTERN = 16
WVGA_853_PORTRAIT_TEST_PATTERN = 17
WVGA_853_LANDSCAPE_TEST_PATTERN = 18
WVGA_854_PORTRAIT_TEST_PATTERN = 19
WVGA_854_LANDSCAPE_TEST_PATTERN = 20
WVGA_864_PORTRAIT_TEST_PATTERN = 21
WVGA_864_LANDSCAPE_TEST_PATTERN = 22
NTSC_LANDSCAPE_TEST_PATTERN = 23
PAL_LANDSCAPE_TEST_PATTERN = 24
NHD_PORTRAIT_TEST_PATTERN = 25
NHD_LANDSCAPE_TEST_PATTERN = 26

ROTATION_TEST_PATTERN = 35
CROP_TEST_PATTERN = 37

# Movie Pattern (from Astro)
MOVIE_TEST_PATTERN = 40 
# 3D Test Pattern set Moving Image, Motion Blur
THREE_D_TEST_PATTERN = 41
# Polarity Test
PCLK_POLARITY_TEST_PATTERN = 42 
DISP_POLARITY_TEST_PATTERN = 43

# Test Max Line 
#23 32KHz
NTSC_LANDSCAPE_MAX_LINE_TEST_PATTERN = 50  
#24 39KHz
PAL_LANDSCAPE_MAX_LINE_TEST_PATTERN = 51
#2 32KHz
QVGA_LANDSCAPE_MAX_LINE_TEST_PATTERN = 52
#4 32KHz
QWVGA_LANDSCAPE_MAX_LINE_TEST_PATTERN = 53
#26 48KHz
NHD_LANDSCAPE_MAX_LINE_TEST_PATTERN = 54
#6 50KHz
X_3_2_VGA_LANDSCAPE_MAX_LINE_TEST_PATTERN = 55
#none 640x480 6 50KHZ
X_4_3_VGA_LANDSCAPE_MAX_LINE_TEST_PATTERN = 56
#10 44KHz
WVGA_720_LANDSCAPE_MAX_LINE_TEST_PATTERN = 57
#12 42KHz
WVGA_752_LANDSCAPE_MAX_LINE_TEST_PATTERN = 58
#14 40KHz  not meet 
WVGA_800_LANDSCAPE_MAX_LINE_TEST_PATTERN = 59
#16 37KHz
WVGA_852_LANDSCAPE_MAX_LINE_TEST_PATTERN = 60
#18 37KHz
WVGA_853_LANDSCAPE_MAX_LINE_TEST_PATTERN = 61
#20 37KHz
WVGA_854_LANDSCAPE_MAX_LINE_TEST_PATTERN = 62
#22 37KHz
WVGA_864_LANDSCAPE_MAX_LINE_TEST_PATTERN = 63

#1 42KHz
QVGA_PORTRAIT_MAX_LINE_TEST_PATTERN = 64
#3 52KHz
QWVGA_PORTRAIT_MAX_LINE_TEST_PATTERN = 65
#25 79KHz
NHD_PORTRAIT_MAX_LINE_TEST_PATTERN = 66
#5 74KHz    not meet
X_2_3_VGA_PORTRAIT_MAX_LINE_TEST_PATTERN = 67
# 66KHz
#X_4_3_VGA_PORTRAIT_MAX_LINE_TEST_PATTERN
#9 66KHz      not meet
WVGA_720_PORTRAIT_MAX_LINE_TEST_PATTERN = 69
#11 66KHz     not meet
WVGA_752_PORTRAIT_MAX_LINE_TEST_PATTERN = 70
#13 66KHz    not meet
WVGA_800_PORTRAIT_MAX_LINE_TEST_PATTERN = 71
#15 66KHz    not meet
WVGA_852_PORTRAIT_MAX_LINE_TEST_PATTERN = 72
#17 66KHz    not meet
WVGA_853_PORTRAIT_MAX_LINE_TEST_PATTERN = 73
#19 66KHz    not meet
WVGA_854_PORTRAIT_MAX_LINE_TEST_PATTERN = 74
#21 66KHz     not meet
WVGA_864_PORTRAIT_MAX_LINE_TEST_PATTERN = 75


# 100- 120 Hz
# nHD 100Hz MAX LINE 48kHz
NHD_LANDSCAPE_MAX_LINE_HI_FREQ_TEST_PATTERN = 76
# WQVGA 100Hz MAX LINE 32kHz
QWVGA_LANDSCAPE_MAX_LINE_HI_FREQ_TEST_PATTERN = 77
# QVGA 100Hz MAX LINE 32kHz
QVGA_LANDSCAPE_MAX_LINE_HI_FREQ_TEST_PATTERN = 78