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

int main(int argc, char** argv) {
	// Variable declarationss
	struct fb_fix_screeninfo fix_info;
	struct fb_var_screeninfo var_info;
	int fb, delay = 1000000, repeat = 1, framerate = 10, num_images = 0, i = 0;
	int test_flag = 0, screen_persist = 0, kill_x = 0, trig_in = 0, video_mode = 0, restart_x = 0;
	//char image_names[100][200]; 
	char ** image_names;
	long screensize;
	uint8_t *fbp, *buffer;

	// Allocate image structure which will be used to store image names
	image_names = (char**)malloc(100 * sizeof(char*));
	for (i = 0; i < 100; i++) {
		image_names[i] = (char*)malloc(200 * sizeof(char));
	}
	


	// Handle command line arguments
	if (argc <= 1) {
		printf("Usage: pattern_disp [options] framerate repetitions\n\n");
		printf("Options:\n");
		printf(" -test (-t)     run through built in test patterns\n");
		printf(" -in (-i)       use the trigger in (GPIO"GPIO_IN") to advance to next pattern instead of set framerate\n");
		printf(" -persist (-p)  the last pattern will stay on the screen at the end of the sequence\n");
		printf(" -kill (-k)     stop running the X-server (sometimes gets better results and hides extra graphics)\n");
		printf(" -video (-v)    don't disable any of the video processing algoirthms on the EVM when running this code\n");
		printf(" -restart (-r)  stop running the X-server and restart the X-server when done\n");
		return EXIT_FAILURE;
	}
	
	
	i = 1;
	// Handle flags set from command line arguments
	while (i < argc && argv[i][0] == '-') { // while there are flags to handle
		if ((strcmp("-t",argv[i]) == 0) || (strcmp("-test",argv[i]) == 0)) {
			test_flag = 1;
		}

		if ((strcmp("-p",argv[i]) == 0) || (strcmp("-persist",argv[i]) == 0)) {
			screen_persist = 1;
		}

		if ((strcmp("-k",argv[i]) == 0) || (strcmp("-kill",argv[i]) == 0)) {
			kill_x = 1;
			printf("Closing X server...\n");
			system("sudo service lightdm stop");
			usleep(1000000); // let X server close
		}

		if ((strcmp("-r",argv[i]) == 0) || (strcmp("-restart",argv[i]) == 0)) {
			kill_x = 1;
			restart_x = 1;
			printf("Closing X server...\n");
			system("sudo service lightdm stop");
			usleep(1000000); // let X server close
		}

		if ((strcmp("-i",argv[i]) == 0) || (strcmp("-in",argv[i]) == 0)) {
			trig_in = 1;
		}

		if ((strcmp("-v",argv[i]) == 0) || (strcmp("-video",argv[i]) == 0)) {
			video_mode = 1;
		}
		i++;
	}

	if (argc >= (i+1)) { // get framerate if it is entered
		framerate = (int)strtol(argv[i],NULL,10);
		delay = 1000000/framerate;
	}
	if (argc >= (i+2)) { // get number of times to repeat pattern if it's entered
		repeat = (int)strtol(argv[i+1],NULL,10);
	}


	// Setup framebuffer and GPIO pins
	if (setup_fb(&fix_info, &var_info, &fb, &screensize, &fbp, &buffer, video_mode) == EXIT_FAILURE) {
		printf("Unable to setup framebuffer\n");
		return EXIT_FAILURE;
	}
	if (setup_GPIO() == EXIT_FAILURE) {
		printf("Unable to setup GPIO pins as triggers\n");
		return EXIT_FAILURE;
	}


	// Display images
	if(test_flag) {
		test_loop(fbp, buffer, &var_info, &fix_info, delay, repeat, screensize, trig_in); // display test "images"
	}
	else {
		if(load_image_files(&num_images, image_names) == EXIT_FAILURE) {
			return EXIT_FAILURE;
		}
		qsort(image_names, num_images, sizeof(image_names[0]), compar); // load files in alphabetical order

		display_images(image_names, num_images, fbp, buffer, &var_info, &fix_info, delay, repeat, screensize, screen_persist, trig_in); // Display loaded images
	}
	

	// Cleanup open files
	if (cleanup(fb, fbp, buffer, screensize, restart_x, video_mode, image_names) == EXIT_FAILURE){
		printf("Error cleaning up files\n");
		return EXIT_FAILURE;
	}

	return EXIT_SUCCESS;
}


int display_images(char **image_names, int num_images, uint8_t* fbp, uint8_t* bbp, struct fb_var_screeninfo* var_info, struct fb_fix_screeninfo* fix_info, int delay, int repeat, long screensize, int screen_persist, int trig_in) {
	// Variable declarations
	int i, ii, usecs = 0;
	long x, y, location;
	long x_max = var_info->xres_virtual;
	long y_max = var_info->yres_virtual;
	uint32_t pix = 0x123456;// Pixel to draw
	pixel** img;
	struct timeval start, stop, start2, stop2;
	double totalusecs = 0;
	FILE *fp_trig_in; 
	char trig_in_value = '0';
	

	// Initial checks
	if (num_images <= 0) {
		printf("No images to display\n");
		return EXIT_FAILURE;
	}

	if (trig_in) { // if there is a trigger in, delay should coorspond to a relativly high framerate (~50fps works)
		delay = 20000;
	}

	system("echo 0 > /sys/class/gpio/gpio"GPIO_OUT"/value"); // ensure initial trigger output is low


	// Allocate image structure which will be used to load images
	img = (pixel**)malloc(IMG_Y * sizeof(pixel*));
	for (i = 0; i < IMG_Y; i++) {
		img[i] = (pixel*)malloc(IMG_X * sizeof(pixel));
	}


	// Will loop through displaying all images
	for (ii = 0; ii < repeat; ii++) {
		for (i = 0; i < num_images; i++) {
			// Open image and ensure it's successful. Inefficent to load file everytime but fine at BeagleBone's low effective video framerates
			if (open_bmp(*(image_names+i), img) == EXIT_FAILURE) {
				return EXIT_FAILURE;
			}
			system("echo 0 > /sys/class/gpio/gpio"GPIO_OUT"/value"); // set trigger output low since we have completed the trigger


			// Transfer image structure to the buffer
			for (y=0; y<y_max; y++) {
				for (x=0; x<x_max; x++) {
					location = (x+var_info->xoffset) * (var_info->bits_per_pixel / 8) + (y + var_info->yoffset) * fix_info->line_length; // offset where we write pixel value
					pix = pixel_color(img[y][x].r, img[y][x].g, img[y][x].b, var_info); // get pixel in correct format
					*((uint32_t*)(bbp + location)) = pix; // write pixel to buffer	
				}
			}
			

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
			

			// Freeze update buffer of DLP2000. This is so it won't display garbage data as we update the Beagles framebuffer
			system("i2cset -y 2 0x1b 0xa3 0x00 0x00 0x00 0x01 i");

			// Display image
			memcpy(fbp, bbp, screensize); // load framebuffer from buffered location

			// Start timer that will be used for next image
			gettimeofday(&start, NULL);

			usleep(delay/3); // allow framebuffer to finish loading
			system("i2cset -y 2 0x1b 0xa3 0x00 0x00 0x00 0x00 i"); // Unfreeze update buffer of DLP2000
			usleep(delay/10); // allow DLP2000 to update
			system("echo 1 > /sys/class/gpio/gpio"GPIO_OUT"/value"); // set trigger high to indicate image done loading
		}
	}

	// Wait for last image to be done
	if (!trig_in) {
		do {
			usleep(10);
			gettimeofday(&stop, NULL);
			usecs = (stop.tv_usec - start.tv_usec) + (stop.tv_sec - start.tv_sec)*1000000;
		} while (usecs < (delay-EXTRA_TIME)); // -EXTRA_TIME which is approximate buffer load time 
	}
	
	if (DEBUG_TIME && !trig_in) {
		printf("Delay goal is %ius versus actual of %ius. Difference: %.1fms\n",delay,usecs,(usecs-delay)/1000.0);
		totalusecs+=usecs;
		printf("Average difference: %.1fms\n\n", (delay-totalusecs/repeat/num_images)/1000.0);
	}

	// Cleanup image memory
	for (i = 0; i < IMG_Y; i++) {
		free(img[i]);
	}
	free(img);

	system("echo 0 > /sys/class/gpio/gpio"GPIO_OUT"/value"); // set trigger low since we have completed the trigger

	if (!screen_persist && !trig_in) {
		clear_screen(fbp, bbp, var_info, fix_info, screensize);
	}
	else if (!screen_persist && trig_in) { // wait until last trigger in to clear screen otherwise
		while (trig_in_value == '0') { // wait until trigger in is asserted
			fp_trig_in = fopen("/sys/class/gpio/gpio"GPIO_IN"/value","r");
			trig_in_value = fgetc(fp_trig_in);
			fclose(fp_trig_in);
			usleep(1000);
		}
		clear_screen(fbp, bbp, var_info, fix_info, screensize);
	}

	return EXIT_SUCCESS;
}

int compar (const void * a, const void * b)
{
    return strcmp(*(char **) b, *(char **) a);
}