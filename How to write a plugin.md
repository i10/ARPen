# How to write a plugin?

If you want to write a plugin, read this document. First we want to answer the question: 

### What is a plugin?

With a plugin you can add logic to this app. Examples for a plugin is the functionality to draw a line with the pen or to create three dimensional objects in a scene using your ARPen.

### I want to write a plugin!

Nice! Start by creating a new swift file in the folder `Plugins` and create a new class inherited from `Plugin`. `Plugin` is a protocol which defines just one method, which later is explained. For now, add your plugin to the PluginManager. Visit the file `PluginManager.swift` and add your created object to the array `plugins` like the others.

Now you can start writing your plugin. Just implement the method `didUpdateFrame(scene:buttons:)` specified in the `Plugin` protocol. The method is called everytime a new marker position is detected. The method could be called very often so try to avoid complex computations.

### Where can I find the pencil point?

The given PenScene has a SCNNode property named `pencilPoint`. The position of this node (`penScene.pencilPoint.position`) should always be the newest position of the pencil point.

### Can I call my plugin with a UIButton?

Not easily. A plugin is not at the moment able to get called by events from the `ViewController` instance. You have to do some adjustments in `ViewController` and `PluginManager`.