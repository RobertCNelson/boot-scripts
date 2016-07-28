#Current:

- init-eMMC-flasher-v3.sh

  - Current BeagleBone Black production flasher, runs in single user mode:
  
    ```
    cmdline=init=<path>/init-eMMC-flasher-v3.sh
    ```
  
- init-eMMC-flasher-v3-bbg.sh

  - Current BeagleBone Green production flasher, runs in single user mode:
  
    ```
    cmdline=init=<path>/init-eMMC-flasher-v3-bbg.sh
    ```

- beaglebone-black-make-microSD-flasher-from-eMMC.sh

  - Clones eMMC to microSD and sets it up to flash the eMMC.
  
    ```
    sudo ./beaglebone-black-make-microSD-flasher-from-eMMC.sh
    ```

- bbb-eMMC-flasher-eewiki-ext4.sh

  - Clones microSD to eMMC as a single ext4 partition.
  
    ```
    sudo ./bbb-eMMC-flasher-eewiki-ext4.sh
    ```


#In development:

- init-eMMC-flasher-from-usb-media.sh

#Obsolete:

- bbb-eMMC-flasher-eewiki-12mb.sh

  - replaced by: bbb-eMMC-flasher-eewiki-ext4.sh

- init-eMMC-flasher-v2.sh:

  - replaced by: init-eMMC-flasher-v3.sh
