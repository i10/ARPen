# How to write a plugin?

If you want to write a plugin, read this document. First we want to answer the question: 

### What is a plugin?

With a plugin you can add logic to this app. Examples for a plugin is the functionality to draw a line with the pen or to create three dimensional objects in a scene using your ARPen.

### I want to write a plugin!

Nice! Start by creating a new swift file in the folder `Plugins` and create a new class inherited from `Plugin`. `Plugin` is a protocol which defines just one method and two properties, which are explained later. For now, add your plugin to the PluginManager. Visit the file `PluginManager.swift` and add your created object to the array `plugins` like the others.

Now you can start writing your plugin. You need to define a identifier and a UIImage for your plugin. These will be used to add your plugin to the menu on the main screen making it possible to select your plugin.
Just implement the method `didUpdateFrame(scene:buttons:)` specified in the `Plugin` protocol. The method is called everytime a new marker position is detected. The method could be called very often so try to avoid complex computations. The scene elements are children of the "drawingNode" of the penScene.

### Where can I find the pencil point?

The given PenScene has a SCNNode property named `pencilPoint`. The position of this node (`penScene.pencilPoint.position`) should always be the newest position of the pencil point.

### Can I call my plugin with a UIButton?

The plugin menu is automatically populated with the entries of the `plugins` Array of the `PluginManager`. Selecting a plugin activates the selected plugin.
At the moment, a plugin is  not able to get called by events from the `ViewController` instance. You have to do some adjustments in `ViewController` and `PluginManager`.
