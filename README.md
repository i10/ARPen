# ARPen

ARPen uses the ARKit framework to track a pen in 3D. This project is sponsored by the German Federal Ministry of Education and Research (BMBF) as part of their Open Photonics call (Personal Photonics, 13N14065).

## Building the ARPen iOS App
1. You can start building the project like every other iOS project.

## Building the ARPen
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
