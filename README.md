# QuakeScope
open-source toolkit for interactive sonification of earthquakes data.

This toolkit has been realized by Robin Morabito, during summer '22 at the Intelligent Instruments Lab (Reykjavik)
with the auspices of the Icelandic Student Research Fund.

## Pre-requirements
Tested only on MacOSX 10.13.6; please report the status on other operative systems when possible.
QuakeScope runs on a computer, and is currently only used with headphones (circumaural models work best, but report your experience with other models too).
This application requires the presence of the following programs on the running machine:
- SuperCollider (https://supercollider.github.io/);
- Arduino (https://www.arduino.cc/en/software)

Addional harware required is listed below. QuakeScope software is distributed in this repository as well.

## Instructions - hardware

QuakeScope interfaces is thought to be embedded in a left-hand glove.
Pick an old glove that fits quite tightly to your hand, and remove the 4th and 5th fingers (optional).
Hardware requirements for the controller circuit:
- an Arduino Nano (https://store.arduino.cc/products/arduino-nano , or other Arduino models);
- a tiny breadboard (enough to fit the Arduino on it);
- a flex resistor (like this one: https://www.sparkfun.com/products/8606);
- an Adafruit LIS3DH accelerometer (https://www.adafruit.com/product/2809 , but other accelerometers might work as well*);
- a bunch of conductive tape, or other bendable conductive materials to cover the 3 glove fingertips;
- a bunch of breadboard jumper wires;
- if using a LIS3DH accelerometer, a Stemma-QT wire (https://learn.adafruit.com/introducing-adafruit-stemma-qt/what-is-stemma-qt);
- 10kOhm resistors;
- an old glove

### Circuit
Here a quick overview of the Arduino based circuit is provided, with the connections for each element. Find a graphic overwiew in the attached `Fritzing-plain` and `Fritzing-hand` files.
Note: thumb, index and middle fingers are imagined to be wrapped in conductive tape beforehand.
Arduino digital pins are marked as D1, D2 etc.; analog pins are marked A1, A2 etc.; 5V and 3V are called as on the Arduino; GND represents any of the GND pins on Arduino.

#### LIS3DH
- Stemma-QT red -> Arduino 3V
- Stemma-QT black -> Arduino GND
- Stemma-QT blue -> Arduino A4
- Stemma-QT yellow -> Arduino A5

#### Flex resistor
(facing grid side)
- right pin -> Arduino 5V
- left pin -> 10kOhm resistor -> GND
- left pin -> Arduino A1

#### Glove Index finger
It's recommended to wrap additional conductive tape around the fingertips 
to ensure tight adherence wire-tape, after placing the wires as indicated below:
- 1 wire -> Arduino D1
- 1 wire -> 10kOhm resistor -> Arduino GND

#### Glove Middle finger
It's recommended to wrap in additional conductive tape, as index finger:
- 1 wire -> Arduino D2
- 1 wire -> 10kOhm resistor -> Arduino GND

#### Glove Thumb
- 1 wire -> Arduino 5V

Optional:
to verify the circuit works correctly, open `arduino-code.ino` on your computer;
this should launch the Arduino IDE and display the code in a window.
Connect the Arduino port via USB (this should light up the board and the accelerometer). 
Make sure to select the right board and port from the Arduino "Tools" menu. 
Click "Upload" on the Arduino window to load the code on the Arduino board; 
if the uploading is successfull, open the serial port in the IDE to verify that data are actually being posted from LIS3DH and the flex resistor. 
Verify the fingers are operating correctly by making index and thumb touch (this should change the first digit posted to "1"),
and by making middle finger and thumb touch (this should result in the last posted digit to turn into "1").

## Instructions - software
Follow these steps after having built QuakeScope hardware.
1. download this repository and unzip it in a known folder;
2. quit SuperCollider (or not! up to you);
3. connect QuakeScope interface to the computer via USB and wait till it powers up;
4. open `setup.scd` file by double clicking it: this will launch SuperCollider;
5. make sure the post window is open, by ticking Post Window in the View > Docklets menu in SuperCollider;
6. click anywhere below the first line (you should see a cursor blink in that spot);
7. execute the whole thing by pressing cmd+enter; it should flash for an instant and display " environment is set up! " in the post window;
8. open `control.scd` file by double clicking it; it should open in SuperCollider, in a new tab. This file contains a sequence of functions to start QuakeScope;
9. place the cursor on line 3, where you see `~bb.();`, by left clicking there;
10. execute the line by pressing cmd+enter; this will open QuakeScope GUI (it might take a couple of seconds);
11. try clicking "Open map" on the GUI; it should open a map of Iceland in a separate window. If this works, click "Close map"
12. select the USB port the interface is plugged into by clicking on the popup menu at the top of the GUI 
(a success message in the post window will confirm correct booting); 
if the connection was successfull, the slider at the bottom of the GUI will move according to accelerometer movement;
13. execute `~cc.();` in `control.scd` line 5: this will print `Tdef('eventStream')` in the post window;
14. execute `~dd.();` in `control.scd` line 7: this will print `Tdef('volContextUpdate')` in the post window;
15. execute `~ee.();` in `control.scd` line 9: this will print `Tdef('action')` in the post window.

You're ready to go! QuakeScope should be working smoothly at this point. If it doesn't, please open an issue in this repository or contact me to get it fixed!
Each time you wanna use QuakeScope, repeat steps 2-15


For a list of complete QuakeScope functions, take a look at the "Proto-manual" in this repository.

Have fun and feel free to propose edits to this app!

## Troubleshooting
#### the USB port is not displayed in the Supercollider Gui
- try closing the GUI window and repeating steps 9-15;
- if this doesn't work, close the GUI window, execute `~aa.();` in line 1; then disconnect the controller, reconnect and repeat steps 9-15;

#### "Protected Call Stack" in post window
- cmd+dot (cmd key and dot key) to quit the server;
- if this doesn't stop it, right click on "Interpreter" at the bottom of the SuperCollider IDE, then "Quit interpreter"
- Click "Language", then "Reboot Interpreter" in SuperCollider IDE

This error is mostly caused by `~ee.()` failing to connect with the previous steps. To make sure this doesn't occur, follow carefully the steps listed above.
- `bb.()` has to go first
- then select USB port
- then execute `~cc.()`, `~dd.()`, `~ee.()` in the order illustrated.

#### any other weird error in SC post window:
- try executing `~aa.()` in `control.scd`, before repeating all the steps 1-15
