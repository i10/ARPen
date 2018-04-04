# Guide to Writing Plugins

### What is a plugin?

A plugin can be used to add functional logic to the ARPen app. Some example plugin functionalities: draw a line, create a cube, and change texture.  

### Do you want to write a plugin? 

Nice! Start by creating a new swift file in the folder `Plugins` and create a new class inherited from `Plugin`. `Plugin` is a protocol that defines one method and two properties, which are explained below. For now, add your plugin to the `PluginManager` by opening the file `PluginManager.swift` and adding the object you had created to the array `plugins`.

Next, define an identifier and a `UIImage` for your plugin. These will be used to add your plugin to the menu on the main screen, making it possible to select your plugin.
Implement the method `didUpdateFrame(scene:buttons:)` specified in the `Plugin` protocol. This method is invoked everytime a new marker position is detected. It is possible that this method is invoked very often — so try to avoid complex computations in this method. The scene elements are children of the "drawingNode" of the penScene.

### Where can I find the ARPen's position?

The given PenScene has a SCNNode property named `pencilPoint`. The position of this node (i.e., `penScene.pencilPoint.position`) should always be the latest position of the ARPen.

### Can I call my plugin with a UIButton?

The plugin menu is automatically populated with the entries of the `plugins` array in the `PluginManager.swift` file. Selecting a plugin in the UI activates the selected plugin.
Currently, it is not possible to invoke a plugin via events from the `ViewController` instance. To do so, you need to make changes to `ViewController` and `PluginManager`.
