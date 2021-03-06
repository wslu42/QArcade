# Tutorials for setting up an QArcade

How to build a case which hosts our arcade machine and make it up and running

## Building a physical arcade machine
  1. Building the arcade case by cutting the MDF boards [with this design](https://www.slideshare.net/WenSenLu1/qarcade-layout)
  2. (optional) build anchoring parts with a 3D printer 
  3. Putting together the arcade case
  4. Prepare rasbian OS (Debian distribution) onto the micro SD card by using Raspberry Pi imager.
  5. Wiring up the parts and boot into raspbian OS.
  6. Make sure everything works including the monitor, sound, keyboard, and mouse in Debian OS.

## Setting up coding environment for fantasy consoles in QArcade
  1. [Update the fresh Debian environment](https://itsfoss.com/apt-get-linux-guide/)
  2. Setting up coding environment with [Sublime Text editor](https://snapcraft.io/install/sublime-text/raspbian) and [the PICO-8 plugin](https://packagecontrol.io/packages/PICO-8)/[the TIC-80 plugin](https://github.com/AlRado/Sublime-TIC-80)
  3. [Get the PICO-8 linux version](https://www.lexaloffle.com/pico-8.php?#getpico8)/[Download the TIC-80 Debian version](https://github.com/nesbox/TIC-80/releases/download/v0.90.1723/tic80-v0.90-rpi.deb) and setup to run the executable
  4. Setting up joystick controller key mapping for PICO-8/TIC-80
  5. (optional) [boot into PICO-8 directly](https://magpi.raspberrypi.org/articles/pico-8-raspberry-pi-starter-guide)

## Let's get some walks in fantasy consoles
  1. Write our first game in PICO-8/TIC-80
  2. What is micro-qiskit
  3. Hello world Quantum
  4. The circuit composer and gate-base logic for a universal quantum computer
  5. More ideas to use quantum computation when developing games
