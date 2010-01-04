/*
* 
* Copyright (c) 2008-2009 Lu Aye Oo
* 
* @author 		Lu Aye Oo
* 
* http://code.google.com/p/flash-console/
* 
*
* This software is provided 'as-is', without any express or implied
* warranty.  In no event will the authors be held liable for any damages
* arising from the use of this software.
* Permission is granted to anyone to use this software for any purpose,
* including commercial applications, and to alter it and redistribute it
* freely, subject to the following restrictions:
* 1. The origin of this software must not be misrepresented; you must not
* claim that you wrote the original software. If you use this software
* in a product, an acknowledgment in the product documentation would be
* appreciated but is not required.
* 2. Altered source versions must be plainly marked as such, and must not be
* misrepresented as being the original software.
* 3. This notice may not be removed or altered from any source distribution.
* 
* 

	BASIC USAGE:
		
		import com.luaye.console.*;
		C.start(this); // this = preferably the root or stage
		
		// OR  C.start(this,"debug");
		// Start console, parameter "debug" (optional) sets the console's password.
		// console will only open after you type "debug" in sequence at anytime on stage. 
		// Leave blank to disable password, where console will launch straight away.
		
		C.add("Hello World"); 
		// Output "Hello World" with default priority in defaultChannel
		
		C.add( ["Hello World" , "this is", "an array", "of arguments"] );
		// Passes multiple arguments as array (for the time being this is the only alternative)
		
		C.add("Important Trace!", 10);
		// Output "Important Trace!" with priority 10 in defaultChannel
		
		C.add("A Looping trace that I dont want to see a long list", 10, true);
		// Output the text in defaultChannel, replacing the last 'repeating' line. preventing it from generating so many lines.
		// good for tracing loops.
		// use C.forceLine = # to force print the line on # frames. # = a number.
		
		C.ch("myChannel","Hello my Channel"); 
		// Output "Hello my Channel" in "myChannel" channel.
		// note: "global" channel show trace lines from all channels.
		
		C.ch("myChannel","Hello my Channel", 8); 
		// Output "Hello my Channel" in "myChannel" channel with priority 8
		// note: "global" channel show trace lines from all channels.
		
		C.ch("myChannel","Hello my Channel", 8, true); 
		// Output "Hello my Channel" in "myChannel" channel with priority 8 replacing the last 'repeating' line
		// note: "global" channel show trace lines from all channels.
		
		
		// OPTIONAL USAGE
		C.visible = false // (defauilt: true) set to change visibility. It will still record but will not update prints etc

		C.tracing = true; // (default: false) when set, all console input will be re-traced during authoring
		C.alwaysOnTop = false; // (default: true) when set this console will try to keep it self on top of its parent display container.

		C.remoting = true; // (default: false) set to broadcast traces to LocalConnection
		C.isRemote = true; // (default: false) set to recieve broadcasts from LocalConnection remote
*/
package com.luaye.console {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.geom.Rectangle;

	/**
	 * C is a static / singleton adapter for Console (com.luaye.console.Console).
	 * In a later date when Console is no longer needed, remove C.start(..) or C.startOnStage(..) 
	 * and the rest of console related codes will stop executing to save memory and performance.
	 * @author  Lu Aye Oo
	 * @version 2.2
	 * @see http://code.google.com/p/flash-console/
	 * @see #start()
	 * @see #startOnStage()
	 */
	public class C{
		
		private static const ERROR_EXISTS:String = "[CONSOLE] already exists. Will keep using the previously created console. If you want to create a fresh 1, C.remove() first.";
		
		private static var _console:Console;
		
		/**
		 * Do not construct.
		 * Please use C.start(..); or C.startOnStage(...);
		 * 
		 * @throws Error error
		 * @see #start()
		 * @see #startOnStage()
		 */
		public function C() {
			throw new Error("[CONSOLE] Do not construct class. Please use C.start(mc:DisplayObjectContainer, password:String='')");
		}
		/**
		 * Start Console inside the given Display.
		 * <p>
		 * Calling any other C calls before this (or startOnStage(...)) will fail silently.
		 * When Console is no longer needed, removing this line alone will stop console from working without having any other errors.
		 * In flex, it is more convenient to use C.startOnStage() as it will avoid UIComponent typing issue.
		 * </p>
		 * @see #startOnStage()
		 *
		 * @param  Display in which console should be added to. Preferably stage or root of your flash document.
		 * @param  Password sequence to toggle console's visibility. If password is set, console will start hidden. Set C.visible = ture to unhide at start.
		 * 			Must be ASCII chars. Example passwords: ` OR debug. Make sure Controls > Disable Keyboard Shortcuts in Flash.
		 * @param  Skin preset number to use. 1 = black base, 2 = white base
		 */
		public static function start(mc:DisplayObjectContainer, pass:String = "", skin:int= 1):void{
			if(_console){
				trace(ERROR_EXISTS);
			}else{
				_console = new Console(pass, skin);
				// if no parent display, console will always be hidden, but using C.remoting is still possible so its not the end.
				if(mc!=null) mc.addChild(_console);
			}
		}
		/**
		 * Start Console in top level (Stage). 
		 * Starting in stage makes sure console is added at the very top level.
		 * <p>
		 * It will look for stage of mc (first param), if mc isn't a Stage or on Stage, console will be added to stage when mc get added to stage.
		 * Calling any other C calls before this will fail silently.
		 * When Console is no longer needed, removing this line alone will stop console from working without having any other errors.
		 * </p>
		 * 
		 * @param  Display which is Stage or will be added to Stage.
		 * @param  Password sequence to toggle console's visibility. If password is set, console will start hidden. Set C.visible = ture to unhide at start.
		 * 			Must be ASCII chars. Example passwords: ` OR debug. Make sure Controls > Disable Keyboard Shortcuts in Flash.
		 * @param  Skin preset number to use. 1 = black base, 2 = white base
		 * 			
		 */
		public static function startOnStage(mc:DisplayObject, pass:String = "", skin:int= 1):void{
			if(_console){
				trace(ERROR_EXISTS);
			}else if(mc !=null && mc.stage !=null ){
				start(mc.stage, pass, skin);
			}else{
			 	_console = new Console(pass, skin);
			 	// if no parent display, console will always be hidden, but using C.remoting is still possible so its not the end.
				if(mc!=null) mc.addEventListener(Event.ADDED_TO_STAGE, addedToStageHandle);
			}
		}
		//
		//
		//
		/**
		 * Add log line to default channel
		 *
		 * @param  String to add, any type can be passed and will be converted to string
		 * @param  Priority of line. 0-10, the higher the number the more visibilty it is in the log, and can be filtered through UI
		 * @param  When set to true, log line will replace the previous line rather than making a new line (unless it has repeated more than C.maxRepeats)
		 * 
		 */
		public static function add(str:*, priority:Number = 2, isRepeating:Boolean = false):void{
			if(_console){
				_console.add(str,priority, isRepeating);
			}
		}
		/**
		 * Add log line to channel.
		 * If channel name doesn't exists it creates one.
		 *
		 * @param  Name of channel, if a non-string param is passed, it will use the object's class name as channel name.
		 * @param  String to add, any type can be passed and will be converted to string
		 * @param  Priority of line. 0-10, the higher the number the more visibilty it is in the log, and can be filtered through UI
		 * @param  When set to true, log line will replace the previous line rather than making a new line (unless it has repeated more than C.maxRepeats)
		 * 
		 */
		public static function ch(channel:*, str:*, priority:Number = 2, isRepeating:Boolean = false):void{
			if(_console){
				_console.ch(channel,str, priority, isRepeating);
			}
		}
		/**
		 * Add log line with priority 1
		 * Allows multiple arguments for convenience use.
		 *
		 * @param String to be logged, any type can be passed and will be converted to string
		 */
		public static function log(...args):void{
			if(_console){
				_console.log.apply(null, args);
			}
		}
		/**
		 * Add log line with priority 3
		 * Allows multiple arguments for convenience use.
		 *
		 * @param String to be logged, any type can be passed and will be converted to string
		 */
		public static function info(...args):void{
			if(_console){
				_console.info.apply(null, args);
			}
		}
		/**
		 * Add log line with priority 6
		 * Allows multiple arguments for convenience use.
		 *
		 * @param String to be logged, any type can be passed and will be converted to string
		 */
		public static function debug(...args):void{
			if(_console){
				_console.debug.apply(null, args);
			}
		}
		/**
		 * Add log line with priority 8
		 * Allows multiple arguments for convenience use.
		 *
		 * @param String to be logged, any type can be passed and will be converted to string
		 */
		public static function warn(...args):void{
			if(_console){
				_console.warn.apply(null, args);
			}
		}
		/**
		 * Add log line with priority 10
		 * Allows multiple arguments for convenience use.
		 *
		 * @param String to be logged, any type can be passed and will be converted to string
		 */
		public static function error(...args):void{
			if(_console){
				_console.error.apply(null, args);
			}
		}
		/**
		 * Add log line as fatal level
		 * Allows multiple arguments for convenience use.
		 *
		 * @param String to be logged, any type can be passed and will be converted to string
		 */
		public static function fatal(...args):void{
			if(_console){
				_console.fatal.apply(null, args);
			}
		}
		/**
		 * Add log line with priority 1 to channel
		 * Allows multiple arguments for convenience use.
		 *
		 * @param  Name of channel, if a non-string param is passed, it will use the object's class name as channel name.
		 * @param String to be logged, any type can be passed and will be converted to string
		 */
		public static function logch(channel:*, ...args):void{
			if(_console){
				_console.logch.apply(null, [channel].concat(args));
			}
		}
		/**
		 * Add log line with priority 3 to channel
		 * Allows multiple arguments for convenience use.
		 *
		 * @param  Name of channel, if a non-string param is passed, it will use the object's class name as channel name.
		 * @param String to be logged, any type can be passed and will be converted to string
		 */
		public static function infoch(channel:*, ...args):void{
			if(_console){
				_console.infoch.apply(null, [channel].concat(args));
			}
		}
		/**
		 * Add log line with priority 6 to channel
		 * Allows multiple arguments for convenience use.
		 *
		 * @param  Name of channel, if a non-string param is passed, it will use the object's class name as channel name.
		 * @param String to be logged, any type can be passed and will be converted to string
		 */
		public static function debugch(channel:*, ...args):void{
			if(_console){
				_console.debugch.apply(null, [channel].concat(args));
			}
		}
		/**
		 * Add log line with priority 8 to channel
		 * Allows multiple arguments for convenience use.
		 *
		 * @param  Name of channel, if a non-string param is passed, it will use the object's class name as channel name.
		 * @param String to be logged, any type can be passed and will be converted to string
		 */
		public static function warnch(channel:*, ...args):void{
			if(_console){
				_console.warnch.apply(null, [channel].concat(args));
			}
		}
		/**
		 * Add log line with priority 10 to channel
		 * Allows multiple arguments for convenience use.
		 *
		 * @param  Name of channel, if a non-string param is passed, it will use the object's class name as channel name.
		 * @param String to be logged, any type can be passed and will be converted to string
		 */
		public static function errorch(channel:*, ...args):void{
			if(_console){
				_console.errorch.apply(null, [channel].concat(args));
			}
		}
		/**
		 * Add line as fatal level to channel
		 * Allows multiple arguments for convenience use.
		 *
		 * @param  Name of channel, if a non-string param is passed, it will use the object's class name as channel name.
		 * @param String to be logged, any type can be passed and will be converted to string
		 */
		public static function fatalch(channel:*, ...args):void{
			if(_console){
				_console.fatalch.apply(null, [channel].concat(args));
			}
		}
		/**
		 * Remove console from it's parent display and clean up
		 */
		public static function remove():void{
			if(_console){
				if(_console.parent != null){
					_console.parent.removeChild(_console);
				}
				_console.destroy();
				_console = null;
			}
		}
		/**
		 * Pauses output log and graphs in Console.
		 * It still record and print back out on resume.
		 */
		public static function get paused():Boolean{
			return getter("paused") as Boolean;
		}
		public static function set paused(v:Boolean):void{
			setter("paused",v);
		}
		/**
		 * Enable/Disable logging and graphs in Console.
		 * Does not record logs or graphs while disabled.
		 */
		public static function get enabled():Boolean{
			return getter("enabled") as Boolean;
		}
		public static function set enabled(v:Boolean):void{
			setter("enabled",v);
		}
		//
		// Logging settings
		//
		/**
		 * Clear console logs.
		 * @param  (optional) name of log channel to clear, leave blank to clear all.
		 */
		public static function clear(channel:String = null):void{
			if(_console){
				_console.clear(channel);
			}
		}
		/**
		 * Accessor for currently viewing channel.
		 * <p>
		 * Set to null or empty string to view all channels (global channel).
		 * </p>
		 */
		public static function get viewingChannel():String{
			return getter("viewingChannel") as String;
		}
		public static function set viewingChannel(v:String):void{
			setter("viewingChannel",v);
		}
		/**
		 * Accessor for currently viewing channels.
		 * <p>
		 * Set to null or empty array to view all channels (global channel).
		 * </p>
		 */
		public static function get viewingChannels():Array{
			return getter("viewingChannels") as Array;
		}
		public static function set viewingChannels(v:Array):void{
			setter("viewingChannels",v);
		}
		/**
		 * Accessor for filtering text.
		 * <p>
		 * When set, Console will create a new channel called filtered and
		 * show all log lines that match the param text.
		 * 
		 * Same as using /filter (text) in commandLine.
		 * </p>
		 */
		public static function get filterText():String{
			return getter("filterText") as String;
		}
		public static function set filterText(v:String):void{
			setter("filterText",v);
		}
		/**
		 * Enable/disable prefixing channel names infront of log lines.
		 * <p>
		 * When turned on, it shows channel names when multiple channels are visible in the same log view.
		 * Default: true
		 * </p>
		 */
		public static function get prefixChannelNames():Boolean{
			return getter("prefixChannelNames") as Boolean;
		}
		public static function set prefixChannelNames(v:Boolean):void{
			setter("prefixChannelNames",v);
		}
		/**
		 * Maximum number of logs Console should remember.
		 * 0 = unlimited. Setting to very high will slow down performance as it grows
		 */
		public static function get maxLines():int{
			return getter("maxLines") as int;
		}
		public static function set maxLines(v:int):void{
			setter("maxLines",v);
		}
		/**
		 * Frames before repeating line is forced to print to next line.
		 * <p>
		 * Set to -1 to never force. Set to 0 to force every line.
		 * Default = 75;
		 * </p>
		 */
		public static function get maxRepeats():Number{
			return getter("maxRepeats") as Number;
		}
		public static function set maxRepeats(v:Number):void{
			setter("maxRepeats",v);
		}
		/**
		 * Accessor for using flash's build in (or external) trace().
		 * <p>
		 * When turned on, Console will also call trace() for all console logs.
		 * trace function can be replaced with something of your own (such as Flex's logging).
		 * default is trace(...);
		 * </p>
		 * @see #traceCall()
		 */
		public static function get tracing():Boolean{
			return getter("tracing") as Boolean;
		}
		public static function set tracing(v:Boolean):void{
			setter("tracing",v);
		}
		/**
		 * Accessor for channels to call trace.
		 * <p>
		 * When set, console will only call trace for channels that match the channel name.
		 * set to null or empty array to trace on all channels.
		 * C.tracing must be set to true for this to effect
		 * </p>
		 * @see #tracing
		 */
		public static function get tracingChannels():Array{
			return getter("tracingChannels") as Array;
		}
		public static function set tracingChannels(v:Array):void{
			setter("tracingChannels",v);
		}
		/**
		 * Accessor for minimum priority required to call trace.
		 * <p>
		 * set to zero (default) to call on all priorities.
		 * C.tracing must be set to true for this to effect
		 * </p>
		 * @see #tracing
		 */
		public static function get tracingPriority():int{
			return getter("tracingChannels") as int;
		}
		public static function set tracingPriority(v:int):void{
			setter("tracingPriority",v);
		}
		/**
		 * Assign custom trace function.
		 * <p>
		 * Strong reference to function. Console will only call this when C.tracing is true.
		 * </p>
		 * @see #tracing
		 *
		 * @param  Custom function to use, must accept at least 1 parameter as String.
		 * @return Current trace function, default is flash's build in trace.
		 * 
		 */
		public static function get traceCall():Function{
			return getter("traceCall") as Function;
		}
		public static function set traceCall(f:Function):void{
			setter("traceCall",f);
		}
		//
		// Panel settings
		//
		/**
		 * Set panel position and size.
		 * <p>
		 * See panel names in Console.PANEL_MAIN, Console.PANEL_FPS, etc...
		 * No effect if panel of that name doesn't exist.
		 * </p>
		 * @param	Name of panel to set
		 * @param	Rectangle area for panel size and position. Leave any property value zero to keep as is.
		 *  		For example, if you don't want to change the height of the panel, pass rect.height = 0;
		 */
		public static function setPanelArea(panelname:String, rect:Rectangle):void{
			if(_console){
				_console.setPanelArea(panelname, rect);
			}
		}
		/**
		 * Start/stop FPS monitor graph.
		 */
		public static function get fpsMonitor():Boolean{
			return getter("fpsMonitor") as Boolean;
		}
		public static function set fpsMonitor(v:Boolean):void{
			setter("fpsMonitor", v);
		}
		/**
		 * Start/stop Memory monitor graph.
		 */
		public static function get memoryMonitor():Boolean{
			return getter("memoryMonitor") as Boolean;
		}
		public static function set memoryMonitor(v:Boolean):void{
			setter("memoryMonitor", v);
		}
		/**
		 * Start/stop Display Roller.
		 */
		public static function get displayRoller():Boolean{
			return getter("displayRoller") as Boolean;
		}
		public static function set displayRoller(v:Boolean):void{
			setter("displayRoller", v);
		}
		/**
		 * Determine if Console should hide the mouse cursor when using Ruler tool.
		 * <p>
		 * You may want to turn it off if your app/game don't use system mouse.
		 * Default: true
		 * </p>
		 */
		public static function get rulerHidesMouse():Boolean{
			return getter("rulerHidesMouse") as Boolean;
		}
		public static function set rulerHidesMouse(v:Boolean):void{
			setter("rulerHidesMouse",v);
		}
		/**
		 * width of main console panel
		 */
		public static function get width():Number{
			return getter("width") as Number;
		}
		public static function set width(v:Number):void{
			setter("width",v);
		}
		/**
		 * height of main console panel
		 */
		public static function get height():Number{
			return getter("height") as Number;
		}
		public static function set height(v:Number):void{
			setter("height",v);
		}
		/**
		 * x position of main console panel
		 */
		public static function get x():Number{
			return getter("x") as Number;
		}
		public static function set x(v:Number):void{
			setter("x",v);
		}
		/**
		 * y position of main console panel
		 */
		public static function get y():Number{
			return getter("y") as Number;
		}
		public static function set y(v:Number):void{
			setter("y",v);
		}
		/**
		 * visibility of all console panels
		 */
		public static function get visible():Boolean{
			return getter("visible") as Boolean;
		}
		public static function set visible(v:Boolean):void{
			setter("visible",v);
		}
		/**
		 * When set to true, Console will *try* not to trace too much info about it self.
		 * <p>
		 * It will stop tracing about start of storing and watching objects - and a few others.
		 * If not sure, keep it to false.
		 * Default: false;
		 * </p>
		 */
		public static function get quiet():Boolean{
			return getter("quiet") as Boolean;
		}
		public static function set quiet(v:Boolean):void{
			setter("quiet",v);
		}
		/**
		 * Accessor for keeping Console on top of display list.
		 * <p>
		 * When turned on (by default), console will always try to put it self on top of the parent's display list.
		 * For example, if console is started in root, when a child display is added in root, console will move it self to the 
		 * top of root's display list to try to overlay the new child display. - making sure that console don't get covered.
		 * </p>
		 * <p>
		 * However, if Console's parent display (root in example) is covered by another display (example: adding a child directly to stage), 
		 * console will not be able to pull it self above it as it is in root, not stage.
		 * If console is added on stage in the first place, there won't be an issue as described above. Use C.startOnStage(...).
		 * </p>
		 * <p>
		 * Keeping it turned on may have other side effects if another display is also trying to put it self on top, 
		 * they could be jumping layers as they fight for the top layer.
		 * </p>
		 */
		public static function get alwaysOnTop():Boolean{
			return getter("alwaysOnTop") as Boolean;
		}
		public static function set alwaysOnTop(v:Boolean):void{
			setter("alwaysOnTop",v);
		}
		//
		// Remoting
		//
		/**
		 * Accessor for remoting (sender).
		 * When turned on, Console will periodically broadcast logs, FPS history and memory usage
		 * for another Console remote to receive. 
		 * <p>
		 * Can not be remoting (sender) and remote (reciever) at the same time.
		 * The broadcast interval can be changed through C.remoteDelay.
		 * </p>
		 * @see #remoteDelay
		 */
		public static function get remoting():Boolean{
			return getter("remoting") as Boolean;
		}
		public static function set remoting(v:Boolean):void{
			setter("remoting",v);
		}
		/**
		 * Accessor for remote (reciever).
		 * When turned on, Console will listen for broadcast of logs/FPS/memory usage from another Console.
		 * Can not be remoting (sender) and remote (reciever) at the same time
		 */
		public static function get remote():Boolean{
			return getter("remote") as Boolean;
		}
		public static function set remote(v:Boolean):void{
			setter("remote",v);
		}
		/**
		 * Accessor for remoter's broadcast interval in frames.
		 * Default = 20 
		 */
		public static function get remoteDelay():int{
			return getter("remoteDelay") as int;
		}
		public static function set remoteDelay(v:int):void{
			setter("remoteDelay",v);
		}
		/**
		 * Set Password required to connect from remote.
		 * <p>
		 * By default this is the same as the password used in C.start() / C.startOnStage();
		 * </p>
		 */
		public static function set remotingPassword(v:String):void{
			setter("remotingPassword",v);
		}
		//
		// Command line tools
		//
		/**
		 * Output an object's info such as it's variables, methods (if any), properties,
		 * superclass, children displays (if Display), parent displays (if Display), etc.
		 * commandLine: /inspect  OR  /inspectfull
		 * 
		 * @param Object to inspect
		 * @param Set true to ouput in more detailed, such as the value of properties and variables
		 * 
		 */
		public static function inspect(obj:Object, detail:Boolean = true):void {
			if(_console){
				_console.inspect(obj,detail);
			}
		}
		/**
		 * CommandLine UI's visibility.
		 * CommandLine will still be avaviable to use through code.
		 */
		public static function get commandLine ():Boolean{
			return getter("commandLine") as Boolean;
		}
		public static function set commandLine (v:Boolean):void{
			setter("commandLine",v);
		}
		/**
		 * Command line usage allowance.
		 * <p>
		 * CommandLine is a big security hole for your code and flash. It is a very good
		 * practice to disable it after development phase.
		 * On the other hand having it on full access will let you debug the code easier.
		 * </p>
		 */
		public static function get commandLineAllowed ():Boolean{
			return getter("commandLineAllowed") as Boolean;
		}
		public static function set commandLineAllowed (b:Boolean):void{
			setter("commandLineAllowed",b);
		}
		/**
		 * Command line base.
		 * The value returned from /base in commandLine.
		 * Default is set to console's parent DisplayContainer.
		 */
		public static function get commandBase():Object{
			return getter("commandBase") as Object;
		}
		public static function set commandBase(v:Object):void{
			setter("commandBase",v);
		}
		/**
		 * Accessor for using strong referencing in CommandLine.
		 * Default is false; Which means all outside references Console store are weak referenced,
		 * allowing them to be garbage collected when required.
		 * 
		 * @param  new value
		 * @return Current strong referencing setting
		 * 
		 */
		public static function get strongRef():Boolean{
			return getter("strongRef") as Boolean;
		}
		public static function set strongRef(v:Boolean):void{
			setter("strongRef",v);
		}
		/**
		 * Store a reference in Console for use in CommandLine.
		 * (same as /save in commandLine)
		 * 
		 * @param  name to save as
		 * @param  Object reference to save, pass null to remove previous save.
		 * @param  (optional) if set to true Console will hard reference the object, making sure it will not get garbage collected.
		 */
		public static function store(n:String, obj:Object, strong:Boolean = false):void{
			if(_console ){
				_console.store(n, obj, strong);
			}
		}
		/**
		 * Print the display list map
		 * (same as /map in commandLine)
		 * 
		 * @param  Display object to start maping from
		 * @param  (optional) maximum child depth. 0 = unlimited
		 */
		public static function map(base:DisplayObjectContainer, maxstep:uint = 0):void{
			if(_console ){
				_console.map(base, maxstep);
			}
		}
		/**
		 * Run a commandLine string
		 *
		 * @param  String to run
		 */
		public static function runCommand(str:String):*{
			if(_console){
				return _console.runCommand(str);
			}
			return null;
		}
		//
		// Memory management tools
		//
		/**
		 * Watch an object to be notified in console when it is being garbage collected
		 *
		 * @param  Object to watch
		 * @param  Object's identification/name
		 * 
		 * @return	Name console used to identify the object - this can be different to param n if another object of the same name is already being watched
		 */
		public static function watch(obj:Object,n:String = null):String{
			if(_console){
				return _console.watch(obj,n);
			}
			return null;
		}
		/**
		 * Stop watching an object from garbage collection
		 *
		 * @param	identification/name given to the object for watch
		 */
		public static function unwatch(n:String):void{
			if(_console){
				_console.unwatch(n);
			}
		}
		/**
		 * Force Garbage collect.
		 * Requires debugger version of flash player
		 */
		public static function gc():void {
			if(_console){
				_console.gc();
			}
		}
		//
		// Graphing utilites
		//
		/**
		 * Add graph.
		 * Creates a new graph panel (or use an already existing one) and
		 * graphs numeric values every frame. 
		 * <p>
		 * Reference to the object is weak, so when the object is garbage collected 
		 * graph will also remove that particular graph line. (hopefully)
		 * </p>
		 * <p>
		 * Example: To graph both mouseX and mouseY of stage:
		 * C.addGraph("mouse", stage, "mouseX", 0xFF0000, "x");
		 * C.addGraph("mouse", stage, "mouseY", 0x0000FF, "y");
		 * </p>
		 *
		 * @param  Name of graph, if same name already exist, graph line will be added to it.
		 * @param  Object of interest.
		 * @param  Property name of interest belonging to obj.
		 * @param  (optional) Color of graph line (If not passed it will randomally generate).
		 * @param  (optional) Key string to use as identifier (If not passed, it will use string from 'prop' param).
		 * @param  (optional) Rectangle area for size and position of graph.
		 * @param  (optional) If set it will invert the graph, meaning the highest value at the bottom and lowest at the top.
		 * 
		 */
		public static function addGraph(n:String, obj:Object, prop:String, col:Number = -1, key:String = null, rect:Rectangle = null, inverse:Boolean = false):void{
			if(_console){
				_console.addGraph(n,obj,prop,col,key,rect,inverse);
			}
		}
		/**
		 * Fix graph's range.
		 * When fixed, graph will only show within the fixed value however offset the real values may be.
		 * <p>
		 * For example: if the graph is fixed between 100 and 200, and the graph value at one point is 300, 
		 * graph will not expand to accompany up to value 10, but remain fixed to 100 - 200 range.
		 * Pass NaN to min or max to unfix graph.
		 * No effect if no graph of the name exists.
		 * </p>
		 *
		 * @param  Name of graph
		 * @param  Minimum value. pass NaN to unfix.
		 * @param  Maximum value. pass NaN to unfix.
		 * 
		 */
		public static function fixGraphRange(n:String, min:Number = NaN, max:Number = NaN):void{
			if(_console){
				_console.fixGraphRange(n, min, max);
			}
		}
		/**
		 * Remove graph.
		 * Leave obj and prop params blank to remove the whole graph.
		 *
		 * @param  Name of graph.
		 * @param  Object of interest to remove (optional).
		 * @param  Property name of interest to remove (optional).
		 * 
		 */
		public static function removeGraph(n:String, obj:Object = null, prop:String = null):void{
			if(_console){
				_console.removeGraph(n, obj, prop);
			}
		}
		/**
		 * Bind keyboard key to a function.
		 * <p>
		 * WARNING: key binding hard references the function. 
		 * This should only be used for development purposes.
		 * Pass null Function to unbind.
		 * </p>
		 *
		 * @param  Keyboard character, must be ASCII.
		 * @param  Set to true if CTRL key press is required to trigger.
		 * @param  Set to true if ALT key press is required to trigger.
		 * @param  Set to true if SHIFT key press is required to trigger.
		 * @param  Function to call on trigger. pass null to unbind previous.
		 * @param  Arguments to pass when calling the Function.
		 * 
		 */
		public static function bindKey(char:String, ctrl:Boolean = false, alt:Boolean = false, shift:Boolean = false, fun:Function = null,args:Array = null):void{
			if(_console){
				_console.bindKey(char, ctrl, alt, shift, fun ,args);
			}
		}
		/**
		 * Assign key binding to capture Display roller's display mapping.
		 * <p>
		 * Pressing the key will output whatever display roller is mapping into console.
		 * You can then press on each display name in Console to get reference to that display for CommandLine use.
		 * Only activates when Display Roller is enabled.
		 * Default: null (not assigned)
		 * </p>
		 *
		 * @param  Keyboard character, must be ASCII. (pass null to remove binding)
		 * @param  Set to true if CTRL key press is required to trigger.
		 * @param  Set to true if ALT key press is required to trigger.
		 * @param  Set to true if SHIFT key press is required to trigger.
		 * 
		 */
		public static function setRollerCaptureKey(char:String, ctrl:Boolean = false, alt:Boolean = false, shift:Boolean = false):void{
			if(_console){
				_console.setRollerCaptureKey(char, ctrl, alt, shift);
			}
		}
		/**
		 * Console already exists?
		 * @return true if console is already running
		 * 
		 */
		public static function get exists():Boolean{
			var e:Boolean = _console? true: false;
			return e;
		}
		//
		private static function addedToStageHandle(e:Event):void{
			var mc:DisplayObjectContainer = e.currentTarget as DisplayObjectContainer;
			mc.removeEventListener(Event.ADDED_TO_STAGE, addedToStageHandle);
			if(_console && _console.parent == null){
				mc.stage.addChild(_console);
			}
		}
		/*private static function canRunWithBrowserSetup(s:Stage, setup:uint):Boolean{
			if(setup>0 && s && (Capabilities.playerType == "PlugIn" || Capabilities.playerType == "ActiveX")){
				var flashVars:Object = s.loaderInfo.parameters;
				if(flashVars["allowConsole"] != "true" && (setup == 1 || (setup == 2 && !Console.remoteIsRunning)) ){
					return false;
				}
			}
			return true;
		}*/
		private static function getter(str:String):*{
			if(_console)return _console[str];
			else return null;
		}
		private static function setter(str:String,v:*):void{
			if(_console){
				_console[str] = v;
			}
		}
		
		
		/**
		 * Get all logs
		 * This is incase you want all logs for use somewhere.
		 * For example, send logs to server or email to someone.
		 * 
		 * @param (optional) line splitter, default is '\n'
		 * @return All log lines in console
		 */
		public static function getAllLog(splitter:String = "\n"):String{
			if(_console)return _console.getAllLog(splitter);
			else return "";
		}
		/**
		 * Get instance to Console
		 * This is for debugging of console.
		 * PLEASE avoid using it!
		 * 
		 * @return Console class instance
		 */
		public static function get instance():Console{
			return _console;
		}
	}
}