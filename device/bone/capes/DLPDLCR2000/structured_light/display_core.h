 /*
 DLPDLCR2000EVM Example Test Script Suite
 Implements basic structured light functionality of  the DLP LightCrafter
 Display 2000 EVM using the provided code

 Copyright (C) 2018 Texas Instruments Incorporated - http://www.ti.com/


  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:

    Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.

    Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the  
    distribution.

    Neither the name of Texas Instruments Incorporated nor the names of
    its contributors may be used to endorse or promote products derived
    from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <linux/fb.h> 
#include <stdint.h>
#include <sys/mman.h> 
#include <unistd.h> 
#include <string.h> 
#include <sys/time.h> 
#include <sys/ioctl.h>
#include <linux/kd.h>
#include <dirent.h>

int setup_fb(struct fb_fix_screeninfo *fix_info, struct fb_var_screeninfo *var_info, int *fb, long *screensize, uint8_t **fbp, uint8_t **buffer, int video_mode);
int setup_GPIO();
int cleanup(int fb, uint8_t *fbp, uint8_t *buffer, long screensize, int restart_x, int video_mode, char **image_names);
int clear_screen(uint8_t* fbp, uint8_t* bbp, struct fb_var_screeninfo* var_info, struct fb_fix_screeninfo* fix_info, long screensize);
void print_fix_info(struct fb_fix_screeninfo fix_info);
void print_var_info(struct fb_var_screeninfo var_info);
inline uint32_t pixel_color(uint8_t r, uint8_t g, uint8_t b, struct fb_var_screeninfo *var_info);
int test_loop(uint8_t* fbp, uint8_t* bbp, struct fb_var_screeninfo* var_info, struct fb_fix_screeninfo* fix_info, int delay, int repeat, long screensize, int trig_in);
