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

#include "display_app.h"
#include "open_bmp.h"
#include "display_core.h"

int setup_fb(struct fb_fix_screeninfo *fix_info, struct fb_var_screeninfo *var_info, int *fb, long *screensize, uint8_t **fbp, uint8_t **buffer, int video_mode) {
	// Setup fb0
	*fb =  open("/dev/fb0", O_RDWR); // set framebuffer
	if (*fb < 0) {
		printf("Unable to open frame buffer 0\n");
		return EXIT_FAILURE;
	}

	// Setup EVM for output from Beagle
	system("i2cset -y 2 0x1b 0x0b 0x00 0x00 0x00 0x00 i");
	system("i2cset -y 2 0x1b 0x0c 0x00 0x00 0x00 0x1b i");

	// Get screen infromation and ensure it is properly setup
	ioctl(*fb, FBIOGET_FSCREENINFO, fix_info); //Get the fixed screen information
	ioctl(*fb, FBIOGET_VSCREENINFO, var_info); // Get the variable screen information

	// Ensure certain parameters are properly setup (they already should be)
	var_info->grayscale = 0;
	var_info->bits_per_pixel = 32;

	// Change some video settings for better "pixel accurate" mode
	if (!video_mode) {
		system("i2cset -y 2 0x1b 0x7e 0x00 0x00 0x00 0x02 i"); // disable temporal dithering
		system("i2cset -y 2 0x1b 0x50 0x00 0x00 0x00 0x06 i"); // disable automatic gain control
		system("i2cset -y 2 0x1b 0x5e 0x00 0x00 0x00 0x00 i"); // disable color coordinate adjustment (CCA) function
	}

	// Setup mmaped buffers
	*screensize = var_info->yres_virtual * fix_info->line_length; // Determine total size of screen in bytes
	*fbp = mmap(0, *screensize, PROT_READ | PROT_WRITE, MAP_SHARED, *fb, (off_t)0); // Map screenbuffer to memory with read and write access and visible to other processes
	*buffer = mmap(0, *screensize, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, (off_t)0); // Second buffer 

	if (*fbp == MAP_FAILED || *buffer == MAP_FAILED) {
		printf("mmap failed\n");
		return EXIT_FAILURE;
	} 


	if (DEBUG) {
		print_fix_info(*fix_info);
		print_var_info(*var_info);
	}

	return EXIT_SUCCESS;



}


int setup_GPIO() {
	DIR *dir_out, *dir_in;
	dir_out = opendir("/sys/class/gpio/gpio"GPIO_OUT);
	dir_in = opendir("/sys/class/gpio/gpio"GPIO_IN);

	if (!dir_out) { // if pin isn't setup as GPIO need to do that
		if (DEBUG) {
			printf("Setting up GPIO"GPIO_OUT" as output\n");
		}
		system("echo "GPIO_OUT" > /sys/class/gpio/export"); // setup pin as gpio
		usleep(200000); // wait for pin to finish setting up
		
	} 

	if (!dir_in) { // if pin isn't setup as GPIO need to do that
		if (DEBUG) {
			printf("Setting up GPIO"GPIO_IN" as input\n");
		}
		system("echo "GPIO_IN" > /sys/class/gpio/export"); // setup pin as gpio
		usleep(200000); // wait for pin to finish setting up
	} 

	system("echo out > /sys/class/gpio/gpio"GPIO_OUT"/direction"); // setup pin GPIO_OUT as output
	system("echo in > /sys/class/gpio/gpio"GPIO_IN"/direction"); // setup pin GPIO_IN as input
	
	closedir(dir_out);
	closedir(dir_in);

	return EXIT_SUCCESS;
}


int clear_screen(uint8_t* fbp, uint8_t* bbp, struct fb_var_screeninfo* var_info, struct fb_fix_screeninfo* fix_info, long screensize) {
	long x, y, location;
	long x_max = var_info->xres_virtual;
	long y_max = var_info->yres_virtual;
	uint32_t pix = 0x123456;// Pixel to draw

	// Transfer image structure to the buffer
	pix = pixel_color(0x00, 0x00, 0x00, var_info);
	for (y=0; y<y_max; y++) {
		for (x=0; x<x_max; x++) {
			location = (x+var_info->xoffset) * (var_info->bits_per_pixel / 8) + (y + var_info->yoffset) * fix_info->line_length; // offset where we write pixel value
			*((uint32_t*)(bbp + location)) = pix; // write pixel to buffer	
		}
	}

	// Display image
	memcpy(fbp, bbp, screensize); // load framebuffer from buffered location

	return EXIT_SUCCESS;
}


// Releases appropriate files
int cleanup(int fb, uint8_t *fbp, uint8_t *buffer, long screensize, int restart_x, int video_mode, char **image_names) {
	int i = 0;
	
	if (munmap(fbp, screensize) == EXIT_FAILURE) {
		printf("Unable to unmap fbp\n");
	}
	if (munmap(buffer, screensize) == EXIT_FAILURE) {
		printf("Unable to unmap buffer\n");
	}
	if (close(fb) == EXIT_FAILURE) {
		printf("Unable to close frame buffer\n");
	}
	if (restart_x == 1) { // should restart x server
		system("sudo service lightdm start");
	}
	if (!video_mode) { // reset to video mode
		system("i2cset -y 2 0x1b 0x7e 0x00 0x00 0x00 0x00 i"); // enable temporal dithering
		system("i2cset -y 2 0x1b 0x50 0x00 0x00 0x00 0x07 i"); // enable automatic gain control
		system("i2cset -y 2 0x1b 0x5e 0x00 0x00 0x00 0x01 i"); // enable color coordinate adjustment (CCA) function
	}
	if (image_names != NULL) {
		for (i = 0; i < 100; i++) {
			free(image_names[i]);
		}
		free(image_names);
	}
	return EXIT_SUCCESS;
}

inline uint32_t pixel_color(uint8_t r, uint8_t g, uint8_t b, struct fb_var_screeninfo *var_info) {
	return (r<<var_info->red.offset) | (g<<var_info->green.offset) | (b<<var_info->blue.offset);

}


int test_loop(uint8_t* fbp, uint8_t* bbp, struct fb_var_screeninfo* var_info, struct fb_fix_screeninfo* fix_info, int delay, int repeat, long screensize, int trig_in) {
	int i, ii;
	long x, y, location;
	long x_max = var_info->xres_virtual;
	long y_max = var_info->yres_virtual;
	uint32_t pix = 0x123456;// Pixel to draw
	struct timeval start, stop;
	int usecs = 0;
	double totalusecs = 0, total_displayed = 0;
	char trig_in_value = 0;
	FILE *fp_trig_in; 

	if (trig_in) { // if there is a trigger in delay should coorspond to a relativly high framerate (~20fps works)
		delay = 50000;
	}

	// Will loop through displaying all images
	for (ii = 0; ii < repeat; ii++) {
		for (i = 0; i < 6; i++) {
			// Transfer image structure to the buffer
			for (y=0; y<y_max; y++) {
				for (x=0; x<x_max; x++) {
					location = (x+var_info->xoffset) * (var_info->bits_per_pixel / 8) + (y + var_info->yoffset) * fix_info->line_length; // offset where we write pixel value
					if (i == 0) {
						pix = pixel_color(0xff, 0xff, 0xff, var_info);
					}
					else if (i == 1) {
						pix = pixel_color(0xff, 0x00, 0x00, var_info);
					}
					else if (i == 2) {
						pix = pixel_color(0x00, 0xff, 0x00, var_info);
					}
					else if (i == 3) {
						pix = pixel_color(0x00, 0x00, 0xff, var_info);
					}
					else if (i == 4) {
						pix = pixel_color(0x20, 0x20, 0x20, var_info);
					}
					else {
						pix = pixel_color(0x00, 0x00, 0x00, var_info);
					}
					

					*((uint32_t*)(bbp + location)) = pix; // write pixel to buffer	
				}
			}
			system("echo 0 > /sys/class/gpio/gpio"GPIO_OUT"/value"); // set trigger outpu low since we have completed the trigger

			
			// Wait until delay is over
			if (!(ii == 0 && i == 0) && !trig_in) { // as long as it's not the first time through the loop we have to wait
				do {
					usleep(10);
					gettimeofday(&stop, NULL);
					usecs = (stop.tv_usec - start.tv_usec) + (stop.tv_sec - start.tv_sec)*1000000;

				
				} while (usecs < (delay-EXTRA_TIME)); // -EXTRA_TIME which is approximate buffer load time 
				
				if (DEBUG_TIME) {
					printf("Delay goal is %ius versus actual of %ius. Difference: %.1fms\n",delay,usecs,(usecs-delay)/1000.0);
					totalusecs+=usecs;
					total_displayed++;
				}
			}
			else if (trig_in) { // if we are using trigger in
				
				while (trig_in_value == '0') { // wait until trigger in is asserted
					fp_trig_in = fopen("/sys/class/gpio/gpio"GPIO_IN"/value","r");
					trig_in_value = fgetc(fp_trig_in);
					fclose(fp_trig_in);
					usleep(1000);
				}
				trig_in_value = '0';
			}

			// Freeze update buffer of DLP2000
			system("i2cset -y 2 0x1b 0xa3 0x00 0x00 0x00 0x01 i");

			// Display image
			memcpy(fbp, bbp, screensize); // load framebuffer from buffered location
			
			// Start timer that will be used for next image
			gettimeofday(&start, NULL);
			
			usleep(delay/3); // allow buffer to finish loading
			system("i2cset -y 2 0x1b 0xa3 0x00 0x00 0x00 0x00 i"); // Unfreeze update buffer of DLP2000
			usleep(delay/10); // allow DLP2000 to update
			system("echo 1 > /sys/class/gpio/gpio"GPIO_OUT"/value"); // set trigger high to indicate image done loading
			
		}
	}

	// Wait for last image to be done
	do {
		usleep(10);
		gettimeofday(&stop, NULL);
		usecs = (stop.tv_usec - start.tv_usec) + (stop.tv_sec - start.tv_sec)*1000000;
	} while (usecs < (delay-EXTRA_TIME)); // -EXTRA_TIME which is approximate buffer load time 
	
	system("echo 0 > /sys/class/gpio/gpio"GPIO_OUT"/value"); // set trigger low since we have completed the trigger

	if (DEBUG_TIME) {
		printf("Delay goal is %ius versus actual of %ius. Difference: %.1fms\n",delay,usecs,(usecs-delay)/1000.0);
		totalusecs+=usecs;
		total_displayed++;
		printf("Average difference: %.1fms\n\n", (totalusecs/total_displayed - delay)/1000.0);
	}


	return EXIT_SUCCESS;
}



/* This function prints some key, fixed parameters of the frame buffer. Usefule for debugging. */
void print_fix_info(struct fb_fix_screeninfo fix_info) {
	printf("-----Fixed framebuffer information:-----\n");
	printf("ID: %s\n", fix_info.id);
	printf("Framebuffer length mem: %i\n", fix_info.smem_len);
	printf("Framebuffer type (see FB_TYPE_): %i\n",fix_info.type); // probably 0 on Beagle which is packed_pixels 
	printf("Framebuffer visual (see FB_VISUAL_): %i\n",fix_info.visual); // probably 2 on Beagle which is truecolor
	printf("Line length (bytes): %i\n",fix_info.line_length);
	printf("Acceleration (see FB_ACCEL_*): %i\n",fix_info.accel); // probably 0 on Beagle which means none
	printf("\n");

	return;
}


void print_var_info(struct fb_var_screeninfo var_info) {
	printf("-----Variable framebuffer information:-----\n");
	printf("X Resolution: %i\n",var_info.xres); 
	printf("Y Resolution: %i\n",var_info.yres); 
	printf("X Resolution Virtual: %i\n",var_info.xres_virtual); 
	printf("Y Resolution Virtual: %i\n",var_info.yres_virtual); 
	printf("X Offset: %i\n",var_info.xoffset); 
	printf("Y Offset: %i\n",var_info.yoffset); 
	printf("Bits per pixel: %i\n",var_info.bits_per_pixel); 
	printf("Grayscale: %i\n",var_info.grayscale); // 0 = color
	printf("Red pixel\n");
	printf("   Offset = %i\n",var_info.red.offset);
	printf("   Length = %i\n",var_info.red.length);
	printf("   MSB Right = %i\n",var_info.red.msb_right);
	printf("Green pixel\n");
	printf("   Offset = %i\n",var_info.green.offset);
	printf("   Length = %i\n",var_info.green.length);
	printf("   MSB Right = %i\n",var_info.green.msb_right);
	printf("Blue pixel\n");
	printf("   Offset = %i\n",var_info.blue.offset);
	printf("   Length = %i\n",var_info.blue.length);
	printf("   MSB Right = %i\n",var_info.blue.msb_right);
	printf("Transparency pixel\n");
	printf("   Offset = %i\n",var_info.transp.offset);
	printf("   Length = %i\n",var_info.transp.length);
	printf("   MSB Right = %i\n",var_info.transp.msb_right);
	printf("Nonstandard format: %i\n",var_info.nonstd); // 0 = standard
	printf("Pixel Clock: %ips\n",var_info.pixclock); // 0 = color
	printf("\n");
	return;
}
