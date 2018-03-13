# What is ARPen?

Ever wanted to 3d print a dock for your phone? Or maybe a coffee cup holder that can be attached next to your car dashboard? If so, you would have to measure the dimensions of your phone and dashboard, construct 3d models using CAD-like software, convert these models to appropriate format, and print them in 3d. As you can see, this is an arduous process. 

ARPen is an iOS app that allows you to use a mobile pen to perform free-hand 3D modeling _directly in the real world_. The app uses the in-built iPhone camera to do the tracking. ARPen uses the ARKit framework to track a special 3D-printed pen, called ARPen, in 3D. Instructions to build this pen can be found *below*.  

This project is sponsored by the German Federal Ministry of Education and Research (BMBF) as part of their Open Photonics call (Personal Photonics, 13N14065).  

# Instructions
## 1. Building the ARPen
You can 3D print the whole ARPen on your own. The 3d models can be found under the `ARPen 3d Models and Marker` folder.  

1. Print the 3d models for the ARPen.
	* If you are using a multi-material printer, which allows you to use more than one print material, print the following models
		* `Pen.stl`,
		* `Box_white.stl` in _white_ color,
		* `Box_black.stl` in _black_ color, 
		* `Cap_white.stl` in _white_ color, and 
		* `Cap_black.stl` in _black_ color. 
	* If you are using a single-material printer:
		* Print these models: `Pen.stl`, `Box.stl`, and `Cap.stl`.
		* Print `Sticker.pdf` on an A4 paper using a normal 2D printer, cut out the individual marker codes (6x), and paste them around the printed box. 
2. Insert three momentary switches or buttons into the holes in the ARPen as shown below and solder them to cables, which will be connected to a Bluetooth chip as described in step 4.  
	![][image-1]
3. Glue the box to the pen. 
4. Connect a Bluetooth chip (such as [RedBear Nano v2][1]) with the buttons as shown below, and put it in the box. You can find the software for the Bluetooth chip in the `Bluetooth Software` folder. 
	![][image-2] 

## 2. Using the iOS App
You can build the ARPen iOS app like every other iOS project.  

---- 

# Contributions

Feel free to [submit pull requests][3], [create issues][2] or spread the word. 

[1]:	https://redbear.cc/product/ble-nano-2.html "RedBear Nano v2"
[2]:	https://github.com/i10/ARPen/issues/new "Add an issue"
[3]:    https://github.com/i10/ARPen/compare 

[image-1]:	https://github.com/i10/ARPen/blob/master/images/Buttons.JPG "Momentary Buttons "
[image-2]:	https://github.com/i10/ARPen/blob/master/images/Bluetooth%20Setup.jpg "Bluetooth Setup"
