# ARPen

## Build ARPen iOS App
To build the project first run `carthage bootstrap`. After carthage finished you can start building the project like every other iOS project.

## Build the ARPen
You can 3D print the whole ARPen by your own. Follow these instructions to get your own pen:

### If you use a multi-material printer

1. Print the part Pen.stl. Then print Box_white.stl (in white color) and Box_black.stl (in black color) in one part. Also do this for Cap_white.stl and Cap_black.stl

### If you use a single-material printer
1. 3D print the part Pen.stl, Box.stl and Cap.stl
2. 2D print the Sticker.pdf cut it out and put it around the box.

---

1. Insert some arduino buttons in the holes and solder them to a cable.
2. Agglutinate the box with the pen.
3. Buy a Bluetooth chip (RedBear Nano v2 or similar), connect it with the buttons (as shown [here](images/connection.pdf)), and put it in the box. You can find the software for the Bluetooth chip in the folder `BLE_Serial`.
