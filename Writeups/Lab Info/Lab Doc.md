# LAB 3 - FPGA and Shape Detection

###
In this lab, you will split into two teams to develop an FPGA module capable of detecting basic shapes from a camera input. This device will be mounted on the robot to identify these shapes on the walls of the maze.

Below is a block diagram of the device that will implemented. The red blocks, along with all of the interconnects will be made by you, the white ones are provided.    

![BLOCK DIAGRAM](images/Lab3BlockDiagram.png "Block, Lock, and Drop it")

## Prelab

The FPGA being used is the DE0-Nano (Non-SOC). Read some key portions of the DE0-nano's documentation here:

* [DE0-Nano Specifications](http://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=165&No=593&PartNo=2 "Specs")

* [DE0-Nano User Manual](http://www.ti.com/lit/ug/tidu737/tidu737.pdf "The Manual")

The expansion headers on **page 18** of the manual will be particularly useful for planning GPIO from the FPGA to both the Arduino and the camera.

To setup the OV7670 digital camera, you will need to get acquainted with its datasheet here:

* [OV7670 Datasheet](https://www.voti.nl/docs/OV7670.pdf "Camera stuff")

In order to perform image processing (for our object detection), it is useful to store our image data in a *memory buffer*. Given that the buffer can hold all the pixel data for exactly one image at a time, reading from it is equivalent to scanning through the pixels of the image in one frame of image output from the camera. No buffer exists onboard the OV7670, so one must be created on the DE0-Nano using its onboard **embedded memory**. This embedded memory consists of M9K memory blocks that we may configure to create a RAM. One caveat of this is that each entry in the RAM must have a size of 8 or 9 bits.

We will use a VGA adapter to connect to a display for debugging (to ensure your image comes out properly). The adapter takes pixel data in RGB 332 format (8 bits - 3 red, 3 blue, 2 green). 

The OV7670 camera requires being setup every time the camera is powered on. This involves setting registers in the camera, which can be done over the Arduino's I2C interface. The cam also requires the input of some clock. Lastly for inputs, it has an active-low reset pin and a power-down pin. Outputs of the camera include 8 pins for 8b data output and 3 signals for sampling: PCLK(pixel clock), HS(HREF), and VS(VSYNC).
 - HREF indicates the start (rising edge) and end (falling edge) of a row of pixels in an image.
 - VSYNC indicates the start (falling edge) and end (rising edge) of a frame of an image
 - PCLK decides the speed at which the data output is being transmitted. Its rising edge indicates a new byte is ready to read.

### Questions

 #### *Q1:*  
 Reviewing the FPGA's specifications, what is the maximum size of buffer that we can create in Kilobits? Given that each entry is, how many entires large can the RAM be?  
 ***Answer***   
 *The specification above states that the DE0-Nano has 594 Kbits of embedded memory, allowing for 74,250 8-bit entries*

 #### *Q2:*  
 The OV7670 offers a variety of pixel formats to sample data at (see: Output Formats in "Key Specifications" table). Which of the formats available provides the most info on the base colors making up each pixel?  
 ***Answer***
 *RGB 565*

 #### *Q3:*  
 Given that the input to our VGA adapter is RGB 332. How may we convert (downsize) the pixel format from *Q2* to be accepted by the VGA module.  
 ***Answer***
 *Remove the least significant 2b of R, 3b of G, and 2b of B*

 #### *Q4:*  
 Now that we know the downsized space each pixel will take (from Q3), we need to know how many of them we must fit in memory. Which of the predefined resolutions that the OV7670 supports provides the max amount of pixels in an image, given the constrained max size of our buffer(from *Q1*)? What's the size of our buffer?  
 ***Answer***
 *QCIF,* 
 *176px * 144px * 8b/p  = 202 Kbits*

 #### *Q5:*  
 Using the Register Set table on pages 10-23 of the OV7670 datasheet, find the registers you will need to set to do the following:  
 - reset all registers
 - Enable scaling
 - Use external clock as internal clock
 - Set the camera to output the resolution you specified in *Q4* and the pixel format you specified in *Q2*.(Note: The pixel format will take setting an extra register to fully specify)
 - Enable a color bar test (takes setting 2 regs, neither of them are the SCALING regs)
 - Vertical and mirror flip the output image (optional: it's not necessarily needed but could be useful)  

 **Make sure to get each register's name, address(hex), and value they will be set to (hex).**  

 **Answer**
 - COM7,  addr: 0x12, val: 0x80
 - COM3,  addr: 0x0C, val: 0x08
 - CLKRC, addr: 0x11, val: 0x80
 - COM7,  addr: 0x12, val: 0x0C  
  COM15, addr: 0x40, val: 0xF0
 - COM7,  addr: 0x12, val: 0x02  
  COM17, addr: 0x42, val: 0x0C
 - MVFP,  addr: 0x1E, val: 0x30

 #### *Q6:*  
 Take a look at the timing diagrams (Fig 5 and 6) on Page 7 (Ignore HSYNC, we don't use it). Use both diagrams to determine when we should sample our data. (Hint: We only want to sample valid bytes, and each one only once)  
 ***Answer***
 *Data is valid only when HREF is LOW and VSYNC is HIGH. To sample each byte only once, sample on the rising edge of PCLK*

## Lab

To begin, collect an OV7670 camera and a DE0-Nano FPGA for your team. You will need to split into two teams to complete this lab, so decide which members will go into each. Team Camera will be working on setting up the OV7670 camera with the Arduino. Team FPGA will work on creating a downsampler in Verilog, and writing an image to the VGA display. Once *both* teams are done, work to combine the two and display the camera's image to the display. Once a subteam is done with their task. they may begin implementing their image processor in Verilog.

### PLL
 Each team will need a clock to run their respective devices. The camera requires a 24MHz MCLK (External clock) and the VGA module requires a 25MHz clock to drive the screen. RAM also uses read and write clocks. 

 The FPGA can generate a 50 MHz Clock called CLOCK_50, though we require slower clocks than this. Although we may divide these in logic, this approach is succeptible to clock skew and it is much more pragmatic to use a *phase-locked loop*. This will ensure that the clocks are treated in the FPGA as actual clock lines, and that they remain locked in phase, preventing skew. To use one of these, we'll use a piece *Altera* IP that comes with Quartus II.

#### Download Template
 We first need to download the template for the Quartus II project. You can download that here:

 [Lab 3 FPGA Template](https://drive.google.com/open?id=1HTdRnfoV5JKO79emLY9o_kRIBhPtXBx0)

 Unzip this folder and put it somewhere you'll remember.

#### Open Project
 Open Quartus II on the lab computer   
 Go to *File>Open Project* and open the folder you unzipped, in there select the "DE0_NANO.qpf" project.  
 The top file is called DE0_NANO.v; this is where the FPGA team will work.  

#### To create our PLL
 1. Navigate to *Tools>IP Catalog* to bring up the IP Catalog  
 2. In the window that pops up, click *Library>Basic 
 Functions>Clocks; PLLs and Resets>PLL*  
 3. Double click *ALTPLL*  
 4. In the pop-up, name the IP variation file whatever you'd like. Make sure you use a Verilog IP. 
 ![PLL makeo](images/PLL1.PNG "Really, go nuts")

 5. In the General Modes tab, set the device speed to *Any* and the frequency of inclk0 to *50MHz*, as below.
 ![PLL makeo](images/PLL2.PNG "You'll miss these early parts of this lab")

 6. In the **Inputs/Lock** tab deselect everything

 7. In the **Bandwidth/SS** tab only click the *Auto* bubble

 8. In the **Clock Switchover** tab deselct everything

 9. You can skip over to **Output Clocks** now. We'll be setting up *clk c0*, *clk c1*, and *clk c2*. 

 ![PLL makeo](images/PLL3.PNG "I thought this was supposed to be the easy part")

 10. For c0, select *Use this clock*. Also select *Enter output clock frequency* and set it to *24.0 MHz* as the Requested Setting. Make sure you set the clock duty cycle to *50%*.

  For c1, select *Use this clock*. Also select *Enter output clock frequency* and set it to *25.0 MHz* as the Requested Setting. Make sure you set the clock duty cycle to *50%*.

  For c2, select *Use this clock*. Also select Also select *Enter output clock frequency* and set it to *50.0 MHz* as the Requested Setting. We are making this clock, despite having CLOCK 50 as the reference clock, for the others to always be phase-locked to . As such, you should be sure to use this clock instead of CLOCK_50. Make sure you set the clock duty cycle to *50%*.

 11. Jump to the summary tab and select *nameyouchose*_inst.v and *nameyouchose*_bb.v. Your design should look like the block on the left of the picture below.

 ![PLL makeo](images/PLL4.PNG "almost there")

 Click **Finish**

 13. Go to *File>Open>folder_your_project_is_in*, and you should be able to open your *nameyouchose*_inst.v file. Pasting this into your top level module will allow you access to these clock signals. Remember to input 50MHz.

 You'll want to assign the 24MHz output to a GPIO pin, for the Camera team to use.

### Team Camera

Congrats, you've been chosen to be a part of Team Camera. You will be responsible for wiring the camera properly and setting up its registers. 

So grab the OV7670 and get to work.

Study and download the template Arduino code provided here:

 [Lab 3 Arduino Template](https://drive.google.com/open?id=1HTdRnfoV5JKO79emLY9o_kRIBhPtXBx0)

In order for the provided functions to work, we need to set up the Arduino's I2C interface. This will require wiring the Arduino's SDA and SCL pins to the camera's, and setting the camera up as a slave peripheral.

#### **EXTREMELY IMPORT PART TO NEVER, EVER, FORGET**
Everytime you start a new lab session, **BEFORE** uploading **ANY** code to your Arduino (at least including what's in the template), we must disable the internal pull-up resistors that are a part of the Arduino's I2C interface. This is because they pull the signals that set-up our camera to 5V, while our camera requires 3.3V. Sending 5V through will harm the camera. 

To disable these:
1. Go to *twi.c* at *C:\Program Files (x86)\Arduino\hardware\arduino\avr\libraries\Wire\src\utility*

2. Right click the file and do *Properties>Securities>Edit*
  * Click *Users*
  * Click *Full Control*
  * Click *OK* and *Close*
3. Open *twi.c* 
4. Comment out the following lines
```C
//activate internal pullups for twi
digitalWrite(SDA,1);
digitalWrite(SCL,1);
```



### Team FPGA

Congrats, you've been chosen to be a part of Team FPGA.
Notice that the OV7670 outputs 1 pixel of data over two clock cycles, outputting 8 bits of a pixel at a time throught D7 - D1. Missing just one of these cycles will lose some information, so you must determine when to sample, update wri
Combining

### Image Processing



