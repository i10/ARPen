# What is ARPen?

Ever wanted to 3d print a dock for your phone? Or maybe a coffee cup holder that can be attached next to your car dashboard? If so, you would have to measure the dimensions of your phone and dashboard, construct 3d models using CAD-like software, convert these models to appropriate format, and print them in 3d. As you can see, this is an arduous process. 

ARPen is an iOS app that allows you to use a mobile pen to perform free-hand 3D modeling _directly in the real world_. The app uses the in-built iPhone camera to do the tracking. ARPen uses the ARKit framework to track a special 3D-printed pen, called ARPen, in 3D. Instructions to build this pen can be found *below*.  

This project is sponsored by the German Federal Ministry of Education and Research (BMBF) as part of their Open Photonics call (Personal Photonics, 13N14065).
---- 

#### If you use a single-material printer, first 3D print the parts `Pen.stl`, `Box.stl` and `Cap.stl`. Then, 2D print  `Sticker.pdf`, cut it out, and put it around the box.

## Step 2: iOS App
You can build the ARPen iOS app like every other iOS project. 

---

1. Insert some arduino buttons in the holes and solder them to a cable.
2. Agglutinate the box with the pen.
3. Buy a Bluetooth chip (RedBear Nano v2 or similar), connect it with the buttons (as shown [here](images/connection.pdf)), and put it in the box. You can find the software for the Bluetooth chip in the folder `BLE_Serial`.
