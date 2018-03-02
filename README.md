# ARPen

ARPen uses the ARKit framework to track a special 3D-printed pen (ARPen) in 3D. This project is sponsored by the German Federal Ministry of Education and Research (BMBF) as part of their Open Photonics call (Personal Photonics, 13N14065).

## Step 2: iOS App
You can build the ARPen iOS app like every other iOS project. 

## Step 1: Build the ARPen
You can 3D print the whole ARPen on your own. To do so, follow these instructions:

### If you are using a multi-material printer, print the part `Pen.stl`. Then print `Box_white.stl` (in _white_ color) and `Box_black.stl` (in _black_ color) in one part. Repeat this process for `Cap_white.stl` and `Cap_black.stl`.

### If you use a single-material printer, first 3D print the parts `Pen.stl`, `Box.stl` and `Cap.stl`. Then, 2D print  `Sticker.pdf`, cut it out, and put it around the box.

---

1. Insert some arduino buttons in the holes and solder them to a cable.
2. Agglutinate the box with the pen.
3. Buy a Bluetooth chip (RedBear Nano v2 or similar), connect it with the buttons (as shown [here](images/connection.pdf)), and put it in the box. You can find the software for the Bluetooth chip in the folder `BLE_Serial`.
