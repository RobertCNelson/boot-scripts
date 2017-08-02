To install and run mjpg_streamer on a BeagleBone with a Logitech C270/C920 webcam:

    debian@beaglebone:~$
    debian@beaglebone:~$ cd /opt/scripts/tools/software/mjpg-streamer/
    debian@beaglebone:/opt/scripts/tools/software/mjpg-streamer$ git pull
    Already up-to-date.
    debian@beaglebone:/opt/scripts/tools/software/mjpg-streamer$ sudo ./install_mjpg_streamer.sh

Browse to your BeagleBone from a web browser specifying port 8090: http://beaglebone.local:8090

If you are looking for a quick python script to listen to the stream, try https://gist.github.com/jadonk/2a045611c134e2307a772a721b66ff5d.
