# Introduction to the Koheron SDK and Red Pitaya

In this workshop, we'll be building a simple FPGA instrument to run on
the [Red Pitaya](https://www.redpitaya.com/) board, using the [Koheron
SDK](https://www.koheron.com/software-development-kit/).
The Red Pitaya has a Zynq 7010 chip, combining an ARM dual core
processor and FPGA programmable logic in a single chip.

## Why Koheron?

Creating a design with robust and reliable communication between FPGA
and CPU can take a long time to design, implement and test, and yet is
required by virtually every Zynq design.
When Linux is run on the CPU, both the FPGA hardware design and a
Linux device driver (normally a char driver) need to be developed.
First and second stage bootloaders, a kernel and a root filesystem are
also required, all of which take time to develop and debug.
There are several tools available to ease this process, including:

* [Petalinux](https://www.xilinx.com/products/design-tools/embedded-software/petalinux-sdk.html),
a Xilinx-supported toolchain for building embedded
Linux systems, which provides templates for device drivers
* [Xillybus](http://www.xillybus.com/), a commercial IP core and
device driver to handle transfer over PCIe or AXI (for
Zynq). Includes Xillinux, an Ubuntu-based OS for Zynq
boards.
* Koheron's SDK, an open source makefile-based toolchain which integrates
hardware design, CPU/FPGA communication and software
development.

We'll be using Koheron because of its support for the Red Pitaya board
out of the box, and because it abstracts away the complicated process
of developing a Linux device driver.

## Outline

This workshop is split into several subsections:

1. Obtaining the Koheron SDK
1. The key components of a design using the SDK
1. Building a simple LED blinker design (the "Hello world" of FPGAs is
   to make an LED flash)
1. Modifying an existing design to add new functionality.

This should be enough to give some familiarity with the SDK, as well
as to illustrate how quickly a simple functioning system can be
brought up.
At the end of this sheet you'll find some resources for further
development.

## Obtaining the Koheron SDK

The SDK is a collection of scripts and makefiles.
It is available on Github, at
[https://github.com/Koheron/koheron-sdk](https://github.com/Koheron/koheron-sdk).

To obtain the SDK, clone the Git repository to a local directory:

```git clone https://github.com/Koheron/koheron-sdk.git```

To use the SDK, you'll also need a working Xilinx Vivado
installation.
We'll be using Vivado 2017.4, which can be downloaded from the
[Xilinx website](https://www.xilinx.com/products/design-tools/vivado.html)
if it's not already installed.

## Key files in the SDK

Start by looking at one of the example designs, in the
`examples/red-pitaya/led-blinker]` directory.
You'll see that there are only a few files required to produce a
basic working instrument.

* `config.yml` contains the high level configuration of the
  design. This includes the board the design is for, which FPGA cores
  (equivalant to software library functions) it uses, memory maps,
  control and status register names, files for the Linux driver and
  files for a web GUI. It also includes the name of a constraints
  file
* `constraints.xdc` will be used to set which IO pins on the FPGA we want to
  connect input and output signals to. The constraints file can additionally include
  timing information such as what clock signals are present on the
  FPGA and how they interact, though we won't get into this in this
  workshop.
* `block_design.tcl` is a TCL script used by Vivado to build the FPGA
  design. In here we can write commands to add new IP cores, make
  connections between the cores and connect IO pins to the
  cores. Vivado uses a superset of the standard TCL language, so these
  scripts can even include things like loops, arithmetic and
  conditionals depending on parameters specified in the `config.yml`
  file.
* `led_blinker.hpp` is the C++ device driver to control the
  design. Koheron provides an API to read and write control registers
  and streaming data, which hides the underlying communication
  mechanisms between the FPGA and CPU.
* `led_blinker.py` is a Python application which uses the C++
  driver. In here you can add higher level functionality. The
  application provides a class which can be instantiated by a remote
  client over TCP/IP, using Koheron's Python module, to control the
  intrument remotely and programatically.
* The `web` folder contains a TypeScript (a Microsoft-developed
  strongly-typed superset of Javascript) web app, which enables
  development of a web GUI for the instrument. We won't use this
  in this workshop.

## Building the example `led_blinker` design

Since the SDK is based on makefiles, building a design is a one-liner.
From the `koheron-sdk` directory, run the following command:

`make VIVADO_VERSION=2017.4 CONFIG=examples/red-pitaya/led-blinker/config.yml`

This command will do the following:

* Compile the C++ driver
* Use the TCL script to produce a block design in Vivado, and
  generate a bistream to program the FPGA with this design.
* Compile the Typescript web app.
* Package up the FPGA bitstream and all the software into a single ZIP
  file, which can be copied to the Red Pitaya.

### Running the design

To run the instrument, the Red Pitaya must have an SD card with the
Koheron Ubuntu image on it.
This can be downloaded from Koheron's website and written to the SD
card using your favourite image-writing software.

If you find copying a zip file to the SD card to be too onerous, this
step can be automated.
The following command will, in addition to building the instrument,
copy the output files onto the Red Pitaya and load the instrument up:

`make VIVADO_VERSION=2017.4 CONFIG=examples/red-pitaya/led-blinker/config.yml HOST=<IP of Red Pitaya> run`

This can be particularly useful during development, as you can perform
many design iterations.
And because this is makefile-based, only the components which need to
be rebuilt will be, so if you're only making changes to the Python
application or C++ driver this step will be pretty quick.
Sadly, re-building the FPGA image does take a while...

### Viewing the results

In a web browser, navigate to the IP address (or hostname) of the Red
Pitaya.
You'll see a web page with 8 buttons, allowing you to turn the LEDs on
the side of the board on and off.
Congratulations: you've produced your first instrument!

## Modifying an existing design

Next, we'll take an existing design and modify it to do what we want.
We're going to modify the `adc-dac` example design, to take 1 ADC
input and tee it off.
One input will be sent directly to DAC 1. The other will be filtered
and sent to DAC 2.

1. Copy the adc-dac example design to a new folder:
```
mkdir instruments
cp -r examples/red-pitaya/adc-dac instruments
mv instruments/adc-dac instruments/new
```
1. Add `fpga/cores/boxcar_filter_v1_0` to the `cores` section in
   `config.yml`
1. Build the block design:
```make VIVADO_VERSION=2017.4 CONFIG=instruments/new/config.yml block_design```
1. We now need to modify the block design. Add the boxcar filter IP
   (CTRL+I, type "boxcar" and double click the boxcar filter).
1. Double click on the boxcar filter block, and change the data width
   to 14 to match the ADCs and DACs.
1. Connect the `adc_clk` output of the `adc_dac` block to the `clk`
   pin of the boxcar filter.
1. Connect the `adc2` output of the `adc_dac` block to the `din` port
   of the boxcar filter.
1. Delete the connection from the `dac1` output of the `ctl` block to
   the `dac2` input of the `adc_dac` block.
1. Connect the `dout` of the boxcar filter to the `dac2` input of the
   `adc_dac` block.
1. Save the block design (CTRL+S). Then export it as a TCL script,
   overwriting the block_design.tcl one, by clicking File -> Export ->
   Export Block Design and setting the file name appropriately.
1. Close Vivado
1. Build and run the instrument:
```make VIVADO_VERSION=2017.4 CONFIG=instruments/new/config.yml HOST=<Red Pitaya IP address> run```

You should now find that if you put a noisy signal on input 1, you'll
see the same signal on output 1 but a slighly less noisy signal on
output 2.

#### A quick note

The TCL file produced by Vivado is very verbose.
While it can be checked in to version control, it's not particularly
easy to see what changes have been made.
An alternative workflow is to make modifications to the original
`block_design.tcl` by hand, using the functions Koheron provides as
wrappers to Vivado's lower level TCL functions.
You can see an example at [block_design.tcl](block_design.tcl) in this repository,
which I've written by hand and does the same thing as the
modifications we made in the GUI.
