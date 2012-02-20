/*
* 
* Copyright (c) 2008-2010 Lu Aye Oo
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
*/
package com.junkbyte.console {
	import flash.display.LoaderInfo;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.geom.Rectangle;

	/**
	 * Cc stands for Console Controller.
	 * It is a singleton controller for <code>Console (com.junkbyte.console.Console)</code>.
	 * <p>
	 * In a later date when Console is no longer needed, remove <code>Cc.start(..)</code> or <code>Cc.startOnStage(..)</code> 
	 * and all other calls through Cc will stop working silently.
	 * </p>
	 * @author  Lu Aye Oo
	 * @version 2.4
	 * @see http://code.google.com/p/flash-console/
	 * @see #start()
	 * @see #startOnStage()
	 */
	public class Cc{
		
		private static var _console:Console;
		private static var _config:ConsoleConfig;
		
		/**
		 * Returns ConsoleConfig used or to be used - to start console.
		 * It is recommended to set the values via <code>Cc.config</code> before starting console.
		 * @see com.junkbyte.console.ConsoleConfig
		 */
		public static function get config():ConsoleConfig{
			if(!_config) _config = new ConsoleConfig();
			return _config;
		}
		
		/**
		 * Start Console inside given Display.
		 * <p>
		 * Calling any other Cc calls before this (or startOnStage(...)) will fail silently (except Cc.config).
		 * When Console is no longer needed, removing this line alone will stop console from working without having any other errors.
		 * In flex, it is more convenient to use Cc.startOnStage() as it will avoid UIComponent typing issue.
		 * </p>
		 * @see #startOnStage()
		 *
		 * @param	container	Display in which console should be added to. Preferably stage or root of your flash document.
		 * @param	password	Password sequence to toggle console's visibility. If password is set, console will start hidden. Set Cc.visible = ture to unhide at start.
		 * 			Must be ASCII chars. Example passwords: ` OR debug.
		 * 			Password will not trigger if you have focus on an input TextField.
		 */
		public static function start(container:DisplayObjectContainer, password:String = ""):void{
			if(_console){
				if(container && !_console.parent) container.addChild(_console);
			}else{
				_console = new Console(password, config);
				// if no parent display, console will always be hidden, but using Cc.remoting is still possible so its not the end.
				if(container) container.addChild(_console);
			}
		}
		/**
		 * Start Console in top level (Stage). 
		 * Starting in stage makes sure console is added at the very top level.
		 * <p>
		 * It will look for stage of mc (first param), if mc isn't a Stage or on Stage, console will be added to stage when mc get added to stage.
		 * <p>
		 * </p>
		 * Calling any other Cc calls before this will fail silently (except Cc.config).
		 * When Console is no longer needed, removing this line alone will stop console from working without having any other errors.
		 * </p>
		 * 
		 * @param	display	Display which is Stage or will be added to Stage.
		 * @param	password	Password sequence to toggle console's visibility. If password is set, console will start hidden. Set Cc.visible = ture to unhide at start.
		 * 			Must be ASCII chars. Example passwords: ` OR debug. Make sure Controls > Disable Keyboard Shortcuts in Flash. 
		 * 			Password will not trigger if you have focus on an input TextField.
		 * 			
		 */
		public static function startOnStage(display:DisplayObject, password:String = ""):void{
			if(_console){
				if(display && display.stage && _console.parent != display.stage) display.stage.addChild(_console);
			}else{
				if(display && display.stage){
					start(display.stage, password);
				}else{
			 		_console = new Console(password, config);
			 		// if no parent display, console will always be hidden, but using Cc.remoting is still possible so its not the end.
					if(display) display.addEventListener(Event.ADDED_TO_STAGE, addedToStageHandle);
				}
			}
		}
		//
		// LOGGING 
		//
		/**
		 * Add log line to default channel
		 *
		 * @param string 	String to add, any type can be passed and will be converted to string or a link if it is an object/class
		 * @param priority 	Priority of line. 0-10, the higher the number the more visibilty it is in the log, and can be filtered through UI
		 * @param isRepeating	When set to true, log line will replace the previously repeated line rather than making a new line (unless it has repeated more than ConsoleConfig -> maxRepeats)
		 */
		public static function add(string:*, priority:int = 2, isRepeating:Boolean = false):void{
			if(_console) _console.add(string, priority, isRepeating);
		}
		/**
		 * Add log line to channel
		 * If channel name doesn't exist it creates one
		 *
		 * @param channel	Name of channel, if a non-string param is passed, it will use the object's class name as channel name.
		 * @param string	String to add, any type can be passed and will be converted to string or a link if it is an object/class
		 * @param priority	Priority of line. 0-10, the higher the number the more visibilty it is in the log, and can be filtered through UI
		 * @param isRepeating	When set to true, log line will replace the previous line rather than making a new line (unless it has repeated more than ConsoleConfig -> maxRepeats)
		 */
		public static function ch(channel:*, string:*, priority:int = 2, isRepeating:Boolean = false):void{
			if(_console) _console.ch(channel, string, priority, isRepeating);
		}
		/**
		 * Add log line with priority 1
		 * Allows multiple arguments for convenience use.
		 *
		 * @param ...strings	Strings to be logged, any type can be passed and will be converted to string or a link if it is an object/class
		 */
		public static function log(...strings):void{
			if(_console) _console.log.apply(null, strings);
		}
		/**
		 * Add log line with priority 3
		 * Allows multiple arguments for convenience use.
		 *
		 * @param ...strings	Strings to be logged, any type can be passed and will be converted to string or a link if it is an object/class
		 */
		public static function info(...strings):void{
			if(_console) _console.info.apply(null, strings);
		}
		/**
		 * Add log line with priority 5
		 * Allows multiple arguments for convenience use.
		 *
		 * @param ...strings	Strings to be logged, any type can be passed and will be converted to string or a link if it is an object/class
		 */
		public static function debug(...strings):void{
			if(_console) _console.debug.apply(null, strings);
		}
		/**
		 * Add log line with priority 7
		 * Allows multiple arguments for convenience use.
		 *
		 * @param ...strings	Strings to be logged, any type can be passed and will be converted to string or a link if it is an object/class
		 */
		public static function warn(...strings):void{
			if(_console) _console.warn.apply(null, strings);
		}
		/**
		 * Add log line with priority 9
		 * Allows multiple arguments for convenience use.
		 *
		 * @param ...strings	Strings to be logged, any type can be passed and will be converted to string or a link if it is an object/class
		 */
		public static function error(...strings):void{
			if(_console) _console.error.apply(null, strings);
		}
		/**
		 * Add log line with priority 10
		 * Allows multiple arguments for convenience use.
		 *
		 * @param ...strings	Strings to be logged, any type can be passed and will be converted to string or a link if it is an object/class
		 */
		public static function fatal(...strings):void{
			if(_console) _console.fatal.apply(null, strings);
		}
		/**
		 * Add log line with priority 1 to channel
		 * Allows multiple arguments for convenience use.
		 *
		 * @param channel	Name of channel, if a non-string param is passed, it will use the object's class name as channel name.
		 * @param ...strings	Strings to be logged, any type can be passed and will be converted to string or a link if it is an object/class.
		 */
		public static function logch(channel:*, ...strings):void{
			if(_console) _console.addCh(channel, strings, Console.LOG);
		}
		/**
		 * Add log line with priority 3 to channel
		 * Allows multiple arguments for convenience use.
		 *
		 * @param channel	Name of channel, if a non-string param is passed, it will use the object's class name as channel name.
		 * @param ...strings	Strings to be logged, any type can be passed and will be converted to string or a link if it is an object/class.
		 */
		public static function infoch(channel:*, ...strings):void{
			if(_console) _console.addCh(channel, strings, Console.INFO);
		}
		/**
		 * Add log line with priority 5 to channel
		 * Allows multiple arguments for convenience use.
		 *
		 * @param channel	Name of channel, if a non-string param is passed, it will use the object's class name as channel name.
		 * @param ...strings	Strings to be logged, any type can be passed and will be converted to string or a link if it is an object/class.
		 */
		public static function debugch(channel:*, ...strings):void{
			if(_console) _console.addCh(channel, strings, Console.DEBUG);
		}
		/**
		 * Add log line with priority 7 to channel
		 * Allows multiple arguments for convenience use.
		 *
		 * @param channel	Name of channel, if a non-string param is passed, it will use the object's class name as channel name.
		 * @param ...strings	Strings to be logged, any type can be passed and will be converted to string or a link if it is an object/class.
		 */
		public static function warnch(channel:*, ...strings):void{
			if(_console) _console.addCh(channel, strings, Console.WARN);
		}
		/**
		 * Add log line with priority 9 to channel
		 * Allows multiple arguments for convenience use.
		 *
		 * @param channel	Name of channel, if a non-string param is passed, it will use the object's class name as channel name.
		 * @param ...strings	Strings to be logged, any type can be passed and will be converted to string or a link if it is an object/class.
		 */
		public static function errorch(channel:*, ...strings):void{
			if(_console) _console.addCh(channel, strings, Console.ERROR);
		}
		/**
		 * Add log line with priority 10 to channel
		 * Allows multiple arguments for convenience use.
		 *
		 * @param channel	Name of channel, if a non-string param is passed, it will use the object's class name as channel name.
		 * @param ...strings	Strings to be logged, any type can be passed and will be converted to string or a link if it is an object/class.
		 */
		public static function fatalch(channel:*, ...strings):void{
			if(_console) _console.addCh(channel, strings, Console.FATAL);
		}
		/**
		 * Add a stack trace of where it is called from at the end of the line. Requires debug player.
		 *
		 * @param string	String to add
		 * @param depth	The depth of stack trace
		 * @param priority	Priority of line. 0-10
		 * 
		 */
		public static function stack(string:*, depth:int = -1, priority:int = 5):void{
			if(_console) _console.stack(string,depth,priority);
		}
		/**
		 * Stack log to channel. Add a stack trace of where it is called from at the end of the line. Requires debug player.
		 *
		 * @param channel	Name of channel, if a non-string param is passed, it will use the object's class name as channel name.
		 * @param string	String to add
		 * @param depth	The depth of stack trace
		 * @param priority	Priority of line. 0-10
		 * 
		 */
		public static function stackch(channel:*, string:*, depth:int = -1, priority:int = 5):void{
			if(_console) _console.stackch(channel, string, depth, priority);
		}
		/**
		 * Output an object's info such as it's variables, methods (if any), properties,
		 * superclass, children displays (if Display), parent displays (if Display), etc.
		 * Similar to clicking on an object link or in commandLine: /inspect  OR  /inspectfull.
		 * However this method does not go to 'inspection' channel but prints on the Console channel.
		 * 
		 * @param obj		Object to inspect
		 * @param showInherit	Set to true to show inherited values.
		 * 
		 */
		public static function inspect(obj:Object, showInherit:Boolean = true):void {
			if(_console) _console.inspect(obj, showInherit);
		}
		/**
		 * Output an object's info such as it's variables, methods (if any), properties,
		 * superclass, children displays (if Display), parent displays (if Display), etc - to channel.
		 * Similar to clicking on an object link or in commandLine: /inspect  OR  /inspectfull.
		 * However this method does not go to 'inspection' channel but prints on the Console channel.
		 * 
		 * @param channel	Name of channel, if a non-string param is passed, it will use the object's class name as channel name.
		 * @param obj		Object to inspect
		 * @param showInherit	Set to true to show inherited values.
		 * 
		 */
		public static function inspectch(channel:*, obj:Object, showInherit:Boolean = true):void {
			if(_console) _console.inspectch(channel, obj, showInherit);
		}
		/**
		 * Expand object values and print in console log channel - similar to JSON encode
		 * 
		 * @param obj	Object to explode
		 * @param depth	Depth of explosion, -1 = unlimited
		 */
		public static function explode(obj:Object, depth:int = 3):void {
			if(_console) _console.explode(obj,depth);
		}
		/**
		 * Expand object values and print in channel - similar to JSON encode
		 * 
		 * @param channel	Name of channel, if a non-string param is passed, it will use the object's class name as channel name.
		 * @param obj	Object to explode
		 * @param depth	Depth of explosion, -1 = unlimited
		 */
		public static function explodech(channel:*, obj:Object, depth:int = 3):void {
			if(_console) _console.explodech(channel, obj, depth);
		}
		/**
		 * Add html formated strings to log in default channel
		 * 
		 * <ul>
		 * <li>Multiple Strings and objects are accepted.</li>
		 * <li>If arguments do not make up a valid XML structure, it will print out as raw HTML text as safety.</li>
		 * <li>Examples</li>
		 * <li><code>Cc.addHTML("Here is HTML &lt;font color='#ff0000'&gt;red &lt;b&gt;bold&lt;/b&gt; &lt;b&gt;&lt;i&gt;and&lt;/i&gt;&lt;/b&gt; &lt;i&gt;italic&lt;/i&gt;&lt;/font&gt; text.");</code></li>
		 * <li><code>Cc.addHTMLch("html", 8, "Mix objects inside html &lt;p9&gt;like this &lt;i&gt;&lt;b&gt;", this,"&lt;/b&gt;&lt;/i&gt;&lt;/p9&gt;");</code></li>
		 * <li>If you need to assign channel or priority level, see Cc.addHTMLch</li>
		 * </ul>
		 * 
		 * @param ...strings	Strings to be logged, any type can be passed and will be converted to string or a link if it is an object/class.
		 */
		public static function addHTML(...strings):void {
			if(_console) _console.addHTML.apply(null, strings);
		}
		/**
		 * Add html formated strings to channel with priority
		 * 
		 * <ul>
		 * <li>Multiple Strings and objects are accepted.</li>
		 * <li>If arguments do not make up a valid XML structure, it will print out as raw HTML text as safety.</li>
		 * <li>Examples</li>
		 * <li><code>Cc.addHTML("Here is HTML &lt;font color='#ff0000'&gt;red &lt;b&gt;bold&lt;/b&gt; &lt;b&gt;&lt;i&gt;and&lt;/i&gt;&lt;/b&gt; &lt;i&gt;italic&lt;/i&gt;&lt;/font&gt; text.");</code></li>
		 * <li><code>Cc.addHTMLch("html", 8, "Mix objects inside html &lt;p9&gt;like this &lt;i&gt;&lt;b&gt;", this,"&lt;/b&gt;&lt;/i&gt;&lt;/p9&gt;");</code></li>
		 * </ul>
		 * 
		 * @param channel	Name of channel, if a non-string param is passed, it will use the object's class name as channel name
		 * @param priority 	Priority of line. 0-10, the higher the number the more visibilty it is in the log, and can be filtered through UI
		 * @param ...strings	Strings to be logged, any type can be passed and will be converted to string or a link if it is an object/class.
		 */
		public static function addHTMLch(channel:*, priority:int, ...strings):void {
			if(_console) _console.addHTMLch.apply(null, new Array(channel, priority).concat(strings));
		}
		/**
		 * Print the display list map
		 * (same as /map in commandLine)
		 * 
		 * @param container	Display object to start mapping from
		 * @param maxDepth	Maximum child depth. 0 = unlimited
		 */
		public static function map(container:DisplayObjectContainer, maxDepth:uint = 0):void{
			if(_console ) _console.map(container, maxDepth);
		}
		/**
		 * Print the display list map to channel
		 * (same as /map in commandLine)
		 * 
		 * @param channel	Name of channel, if a non-string param is passed, it will use the object's class name as channel name.
		 * @param container	Display object to start mapping from
		 * @param maxDepth	Maximum child depth. 0 = unlimited
		 */
		public static function mapch(channel:*, container:DisplayObjectContainer, maxDepth:uint = 0):void{
			if(_console ) _console.mapch(channel, container, maxDepth);
		}
		/**
		 * Clear console logs.
		 * @param channel Name of log channel to clear, leave blank to clear all.
		 */
		public static function clear(channel:String = null):void{
			if(_console) _console.clear(channel);
		}
		//
		// UTILS
		//
		/**
		 * Bind keyboard key to a function.
		 * <p>
		 * WARNING: key binding hard references the function and arguments.
		 * This should only be used for development purposes.
		 * Pass null Function to unbind.
		 * </p>
		 *
		 * @param key KeyBind (char:String, shift:Boolean = false, ctrl:Boolean = false, alt:Boolean = false)
		 * @param callback Function to call on trigger. pass null to unbind previous.
		 * @param args Arguments to pass when calling the Function.
		 * 
		 */
		public static function bindKey(key:KeyBind, callback:Function = null, args:Array = null):void{
			if(_console) _console.bindKey(key, callback ,args);
		}
		/**
		 * Add custom top menu.
		 * <p>
		 * WARNING: It hard references the function and arguments.
		 * Pass null Function to remove previously added menu.
		 * </p>
		 * Example: Cc.addMenu("hi", Cc.log, ["Hello from top menu"], "Says hello!");
		 * This adds a link 'hi' on top menu. Rolling over the link will show the tooltip "Says hello!"
		 * Clicking on the link will log in console "Hello from top menu".
		 *
		 * @param  key	Key string that will show up in top menu.
		 * @param  callback	Function to call on trigger. pass null to remove previous added menu.
		 * @param  args	Array of arguments to pass when calling the Function.
		 * @param  rollover	String to show on rolling over the menu item.
		 */
		public static function addMenu(key:String, callback:Function, args:Array = null, rollover:String = null):void{
			if(_console) _console.addMenu(key, callback, args, rollover);
		}
		/**
		 * Listen for uncaught errors from loaderInfo instance
		 * Only works for flash player target 10.1 or later
		 * @param loaderInfo LoaderInfo instance that can dispatch errors
		 */
		public static function listenUncaughtErrors(loaderinfo:LoaderInfo):void{
			if(_console) _console.listenUncaughtErrors(loaderinfo);
		}
		//
		// Command line tools
		//
		/**
		 * Store a reference in Console for use in CommandLine.
		 * (same as /save in commandLine)
		 * 
		 * <ul>
		 * <li>Example 1 (storing functions)</li>
		 * <li><code>Cc.store("load", function(id:uint){Cc.log("Do some loading with id", id)});</code></li>
		 * <li>User call this function by typing '$load(123);' to load with id 123.</li>
		 * 
		 * <li>Example 2 (storing anything)</li>
		 * <li><code>Cc.store("stage", this.stage); // assuming there is this.stage</code></li>
		 * <li>User manipulate frame rate by typing '$stage.frameRate = 60'</li>
		 * </ul>
		 * NOTE: stage is likely to be your default scope so you wouldn't need to store it as in the example but call directly.
		 * 
		 * @param  name	name to save as
		 * @param  obj	Object reference to save, pass null to remove previous save.
		 * @param  useStrong	If set to true Console will hard reference the object, making sure it will not get garbage collected.
		 */
		public static function store(name:String, obj:Object, useStrong:Boolean = false):void{
			if(_console ) _console.store(name, obj, useStrong);
		}
		/**
		 * Add custom slash command.
		 * WARNING: It will hard reference the function. 
		 * 
		 * <ul>
		 * <li>Example 1:</li>
		 * <li><code>Cc.addSlashCommand("test", function():void{ Cc.log("Do the test!");} );</code></li>
		 * <li>When user type "/test" in commandLine, it will call function with no params.</li>
		 * 
		 * <li>Example 2:</li>
		 * <li><code>Cc.addSlashCommand("test2", function(param:String):void{Cc.log("Do the test2 with param string:", param);});</code></li>
		 * <li>user type "/test2 abc 123" in commandLine to call function with param "abc 123".</li>
		 * </ul>
		 * If you need multiple params or non-string type, you will need to do the conversion inside your call back function.
		 * If you are planning to use complex params, consider using Cc.store instead.
		 * 
		 * @param  name	Name of command
		 * @param  callback	Function to call on trigger. pass null to remove previous
		 * @param  description	Description of command. This shows up in /commands list
		 * @param  alwaysAvailable	If set to false this command will NOT be avaviable when Cc.config.commandLineAllowed is false; default = true
		 * @param  endOfArgsMarker	Marker string used to determine end of command argument so that remaining string can be parsed as next line. 
		 * 							null = whole string always passed as argument. default = ";"
		 */
		public static function addSlashCommand(name:String, callback:Function, description:String = "", alwaysAvailable:Boolean = true, endOfArgsMarker:String = ";"):void{
			if(_console ) _console.addSlashCommand(name, callback, description, alwaysAvailable, endOfArgsMarker);
		}
		//
		// Memory management tools
		//
		/**
		 * Watch an object to be notified in console when it is being garbage collected
		 *
		 * @param obj	Object to watch
		 * @param name	Object's identification/name
		 * 
		 * @return	Name console used to identify the object - this can be different to param n if another object of the same name is already being watched
		 */
		public static function watch(obj:Object, name:String = null):String{
			if(_console) return _console.watch(obj, name);
			return null;
		}
		/**
		 * Stop watching an object from garbage collection
		 *
		 * @param name	identification/name given to the object for watch
		 */
		public static function unwatch(name:String):void{
			if(_console) _console.unwatch(name);
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
		 * Cc.addGraph("mouse", stage, "mouseX", 0xFF0000, "x");
		 * Cc.addGraph("mouse", stage, "mouseY", 0x0000FF, "y");
		 * </p>
		 *
		 * @param panelName Name of graph panel, if same name already exist, graph line will be added to it.
		 * @param obj Object of interest.
		 * @param property Property name of interest belonging to obj. If you wish to call a method, you can end it with (), example: "getValue()"; or it you could be any commandline supported syntex such as "Math.random()". Stored commandLine variables will not be available.
		 * @param color (optional) Color of graph line (If not passed it will randomally generate).
		 * @param idKey (optional) Key string to use as identifier (If not passed, it will use string from 'prop' param).
		 * @param rectArea (optional) Rectangle area for size and position of graph.
		 * @param inverse (optional) invert the graph, meaning the highest value at the bottom and lowest at the top.
		 * 
		 */
		public static function addGraph(panelName:String, obj:Object, property:String, color:Number = -1, idKey:String = null, rectArea:Rectangle = null, inverse:Boolean = false):void{
			if(_console) _console.addGraph(panelName, obj, property, color, idKey, rectArea, inverse);
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
		 * @param panelName Name of graph panel
		 * @param min Minimum value. pass NaN to unfix.
		 * @param max Maximum value. pass NaN to unfix.
		 * 
		 */
		public static function fixGraphRange(panelName:String, min:Number = NaN, max:Number = NaN):void{
			if(_console) _console.fixGraphRange(panelName, min, max);
		}
		/**
		 * Remove graph panel
		 * Leave obj and prop params blank to remove the whole graph.
		 *
		 * @param panelName Name of graph.
		 * @param obj Object of interest to remove (optional).
		 * @param property Property name of interest to remove (optional).
		 * 
		 */
		public static function removeGraph(panelName:String, obj:Object = null, property:String = null):void{
			if(_console) _console.removeGraph(panelName, obj, property);
		}
		//
		// VIEW SETTINGS
		//
		/**
		 * Set currently viewing channels.
		 * Calling this method will reset ignored channels set via setIgnoredChannels().
		 * @param ...channels Channels to view. Send empty to view all channels (global channel).
	 	 * @see #setIgnoredChannels()
		 */
		public static function setViewingChannels(...channels:Array):void{
			if(_console) _console.setViewingChannels.apply(null, channels);
		}
		/**
		 * Set ignored viewing channels.
		 * Calling this method will reset viewing channels set via setViewingChannels().
		 * @param ...channels Channels to view. Send empty to view all channels (global channel).
	 	 * @see #setViewingChannels()
		 */
		public static function setIgnoredChannels(...channels:Array):void{
			if(_console) _console.setIgnoredChannels.apply(null, channels);
		}
		/**
		 * Set minimum viewing priority level.
		 * @param Priority level. The level can be between 0 to 10, which maps back to more widely used info, debug, warn etc.
		 * <ul>
		 * <li>0 = All log levels including console event and status logs.</li>
		 * <li>1 / Console.LOG = Cc.log(...)</li>
		 * <li>3 / Console.INFO = Cc.info(...)</li>
		 * <li>6 / Console.DEBUG = Cc.debug(...)</li>
		 * <li>8 / Console.WARN = Cc.warn(...)</li>
		 * <li>9 / Console.ERROR = Cc.error(...)</li>
		 * <li>10 / Console.FATAL = Cc.fatal(...)</li>
		 * </ul>
		 */
		public static function set minimumPriority(level:uint):void{
			if(_console) _console.minimumPriority = level;
		}
		/**
		 * width of main console panel
		 */
		public static function get width():Number{
			if(_console) return _console.width;
			return 0;
		}
		public static function set width(v:Number):void{
			if(_console) _console.width = v;
		}
		/**
		 * height of main console panel
		 */
		public static function get height():Number{
			if(_console) return _console.height;
			return 0;
		}
		public static function set height(v:Number):void{
			if(_console) _console.height = v;
		}
		/**
		 * x position of main console panel
		 */
		public static function get x():Number{
			if(_console) return _console.x;
			return 0;
		}
		public static function set x(v:Number):void{
			if(_console) _console.x = v;
		}
		/**
		 * y position of main console panel
		 */
		public static function get y():Number{
			if(_console) return _console.y;
			return 0;
		}
		public static function set y(v:Number):void{
			if(_console) _console.y = v;
		}
		/**
		 * visibility of all console panels
		 */
		public static function get visible():Boolean{
			if(_console) return _console.visible;
			return false;
		}
		public static function set visible(v:Boolean):void{
			if(_console) _console.visible = v;
		}
		/**
		 * Start/stop FPS monitor graph.
		 */
		public static function get fpsMonitor():Boolean{
			if(_console) return _console.fpsMonitor;
			return false;
		}
		public static function set fpsMonitor(v:Boolean):void{
			if(_console) _console.fpsMonitor = v;
		}
		/**
		 * Start/stop Memory monitor graph.
		 */
		public static function get memoryMonitor():Boolean{
			if(_console) return _console.memoryMonitor;
			return false;
		}
		public static function set memoryMonitor(v:Boolean):void{
			if(_console) _console.memoryMonitor = v;
		}
		/**
		 * CommandLine UI's visibility.
		 */
		public static function get commandLine():Boolean{
			if(_console) return _console.commandLine;
			return false;
		}
		public static function set commandLine(v:Boolean):void{
			if(_console) _console.commandLine = v;
		}
		/**
		 * Start/stop Display Roller.
		 */
		public static function get displayRoller():Boolean{
			if(_console) return _console.displayRoller;
			return false;
		}
		public static function set displayRoller(v:Boolean):void{
			if(_console) _console.displayRoller = v;
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
		 * @param character Keyboard character, must be ASCII. (pass null to remove binding)
		 * @param ctrl Set to true if CTRL key press is required to trigger.
		 * @param alt Set to true if ALT key press is required to trigger.
		 * @param shift Set to true if SHIFT key press is required to trigger.
		 * 
		 */
		public static function setRollerCaptureKey(character:String, ctrl:Boolean = false, alt:Boolean = false, shift:Boolean = false):void{
			if(_console) _console.setRollerCaptureKey(character, shift, ctrl, alt);
		}
		//
		// Remoting
		//
		/**
		 * Turn on/off remoting feature.
		 * Console will periodically broadcast logs, FPS history and memory usage
		 * for another Console remote to receive.
		 */
		public static function get remoting():Boolean{
			if(_console) return _console.remoting;
			return false;
		}
		public static function set remoting(v:Boolean):void{
			if(_console) _console.remoting = v;
		}
		/**
		 * Connect to console remote via socket.
		 * <ul>
		 * <li>Remote need to be listening for connections at the same ip and port.</li>
		 * <li>Currently only AIR version of console remote can host socket connections.</li>
		 * <li>Use /listen (ip) (port) on AIR ConsoleRemote</li>
		 * <li>While socket connection is connected, default local connection is disabled.</li>
		 * <li>You may also use the command /remotingSocket to start a connection.</li>
		 * <li>Host name as IP address is not supported.</li>
		 * </ul>
		 */
		public static function remotingSocket(host:String, port:int):void{
			if(_console) _console.remotingSocket(host, port);
		}
		//
		// Others
		//
		/**
		 * Remove console from it's parent display
		 */
		public static function remove():void{
			if(_console){
				if(_console.parent){
					_console.parent.removeChild(_console);
				}
				_console = null;
			}
		}
		/**
		 * Get all logs.
		 * <p>
		 * This is incase you want all logs for use somewhere.
		 * For example, send logs to server or email to someone.
		 * </p>
		 * 
		 * @param splitter Line splitter, default is <code>\r\n</code>
		 * @return All log lines in console
		 */
		public static function getAllLog(splitter:String = "\r\n"):String{
			if(_console) return _console.getAllLog(splitter);
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
		
		//
		private static function addedToStageHandle(e:Event):void{
			var mc:DisplayObjectContainer = e.currentTarget as DisplayObjectContainer;
			mc.removeEventListener(Event.ADDED_TO_STAGE, addedToStageHandle);
			if(_console && _console.parent == null){
				mc.stage.addChild(_console);
			}
		}
	}
}