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
package com.junkbyte.console 
{
	import flash.display.DisplayObject;
	import com.junkbyte.console.view.MainPanel;
	import com.junkbyte.console.core.ConsoleCentral;
	import com.junkbyte.console.core.Logs;
	import com.junkbyte.console.core.Remoting;
	import com.junkbyte.console.events.ConsoleEvent;
	import com.junkbyte.console.view.ConsoleLayer;
	import com.junkbyte.console.vos.Log;

	import flash.display.DisplayObjectContainer;
	import flash.display.LoaderInfo;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	/**
	 * Console is the main class. 
	 * Please see com.junkbyte.console.Cc for documentation as it shares the same properties and methods structure.
	 * @see http://code.google.com/p/flash-console/
	 * @see com.junkbyte.console.Cc
	 */
	public class Console extends EventDispatcher{

		public static const VERSION:Number = 2.6;
		public static const VERSION_STAGE:String = "IN DEV";
		public static const BUILD:int = 593;
		public static const BUILD_DATE:String = "2011/06/15 00:27";
		//
		public static const LOG:uint = 1;
		public static const INFO:uint = 3;
		public static const DEBUG:uint = 6;
		public static const WARN:uint = 8;
		public static const ERROR:uint = 9;
		public static const FATAL:uint = 10;
		//
		protected var _central:ConsoleCentral;
		protected var _config:ConsoleConfig;
		
		
		[Event(name="consoleStarted", type="com.junkbyte.console.events.ConsoleEvent")]
		public function Console()
		{
		}
		
		public function start(container:DisplayObjectContainer = null, password:String = ""):void
		{
			if(started) throw new Error("Console already started.");
			
			if (password)
			{
				config.keystrokePassword = password;
			}
			
			_central = createCentral(config);
			_central.init();
			_central.report("<b>Console v"+VERSION+VERSION_STAGE+"</b> build "+BUILD+". "+Capabilities.playerType+" "+Capabilities.version+".", -2);

			if(container) 
			{
				container.addChild(display);
			}
			dispatchEvent(ConsoleEvent.create(ConsoleEvent.CONSOLE_STARTED));
		}
		
		public function startOnStage(target:DisplayObject, password:String = ""):void{
			if (password)
			{
				config.keystrokePassword = password;
			}
			if(!started)
			{
				start();
			}
			if(target)
			{
				if(target.stage) 
				{
					target.stage.addChild(display);
				}
				else 
				{
					target.addEventListener(Event.ADDED_TO_STAGE, addedToStageHandle, false, 0, true);
				}
			}
		}
		
		private function addedToStageHandle(e:Event):void{
			var mc:DisplayObjectContainer = e.currentTarget as DisplayObjectContainer;
			mc.removeEventListener(Event.ADDED_TO_STAGE, addedToStageHandle);
			mc.stage.addChild(display);
		}
		
		public function get started():Boolean
		{
			return _central != null;
		}
		
		protected function createCentral(config:ConsoleConfig):ConsoleCentral
		{
			return new ConsoleCentral(this, config);
		}
		
		// requires flash player target to be 10.1
		public function listenUncaughtErrors(loaderinfo:LoaderInfo):void {
			try{
				var uncaughtErrorEvents:IEventDispatcher = loaderinfo["uncaughtErrorEvents"];
				if(uncaughtErrorEvents){
					uncaughtErrorEvents.addEventListener("uncaughtError", uncaughtErrorHandle, false, 0, true);
				}
			}catch(err:Error){
				// seems uncaughtErrorEvents is not avaviable on this player/target, which is fine.
			}
		}
		
		private function uncaughtErrorHandle(e:Event):void{
			var error:* = e.hasOwnProperty("error")?e["error"]:e; // for flash 9 compatibility
			var str:String;
			if (error is Error){
				str = _central.refs.makeString(error);
			}else if (error is ErrorEvent){
				str = ErrorEvent(error).text;
			}
			if(!str){
				str = String(error);
			}
			_central.report(str, FATAL, false);
		}
		

		public function addGraph(name:String, obj:Object, property:String, color:Number = -1, key:String = null, rect:Rectangle = null, inverse:Boolean = false):void{
			throwErrorIfNotStarted("addGraph()");
			_central.graphing.add(name, obj, property, color, key, rect, inverse);
		}
		public function fixGraphRange(name:String, min:Number = NaN, max:Number = NaN):void{
			throwErrorIfNotStarted("fixGraphRange()");
			_central.graphing.fixRange(name, min, max);
		}
		public function removeGraph(name:String, obj:Object = null, property:String = null):void{
			throwErrorIfNotStarted("removeGraph()");
			_central.graphing.remove(name, obj, property);
		}
		
		//
		// WARNING: key binding hard references the function and arguments.
		// This should only be used for development purposes only.
		//
		public function bindKey(key:KeyBind, callback:Function ,args:Array = null):void{
			throwErrorIfNotStarted("bindKey()");
			if(key) _central.keyBinder.bindKey(key, callback, args);
		}
		//
		// WARNING: Add menu hard references the function and arguments.
		//
		public function addMenu(key:String, callback:Function, args:Array = null, rollover:String = null):void{
			throwErrorIfNotStarted("addMenu()");
			_central.display.mainPanel.addMenu(key, callback, args, rollover);
		}
		//
		// Panel settings
		/* 
		// NO LONGER SUPPOPRTED. USE DisplayRollerModule .start() ...
		//
		public function get displayRoller():Boolean{
			return _central.panels.displayRoller;
		}
		public function set displayRoller(b:Boolean):void{
			_central.panels.displayRoller = b;
		}
		*/
		
		//
		public function get fpsMonitor():Boolean{
			throwErrorIfNotStarted("fpsMonitor");
			return _central.graphing.fpsMonitor;
		}
		public function set fpsMonitor(b:Boolean):void{
			throwErrorIfNotStarted("fpsMonitor");
			_central.graphing.fpsMonitor = b;
		}
		//
		public function get memoryMonitor():Boolean{
			throwErrorIfNotStarted("memoryMonitor");
			return _central.graphing.memoryMonitor;
		}
		public function set memoryMonitor(b:Boolean):void{
			throwErrorIfNotStarted("memoryMonitor");
			_central.graphing.memoryMonitor = b;
		}
		
		/*
		// NO LONGER SUPPOPRTED. USE GarbageCollectionMonitor Module...
		public function watch(object:Object,name:String = null):String{
			return _central.mm.watch(object, name);
		}
		public function unwatch(name:String):void{
			_central.mm.unwatch(name);
		}*/
		
		
		public function store(name:String, obj:Object, strong:Boolean = false):void{
			throwErrorIfNotStarted("store()");
			_central.cl.store(name, obj, strong);
		}
		public function map(container:DisplayObjectContainer, maxstep:uint = 0):void{
			throwErrorIfNotStarted("map()");
			_central.tools.map(container, maxstep, Logs.DEFAULT_CHANNEL);
		}
		public function mapch(channel:*, container:DisplayObjectContainer, maxstep:uint = 0):void{
			throwErrorIfNotStarted("mapch()");
			_central.tools.map(container, maxstep, ConsoleCentral.MakeChannelName(channel));
		}
		public function inspect(obj:Object, showInherit:Boolean = true):void{
			throwErrorIfNotStarted("inspect()");
			_central.refs.inspect(obj, showInherit, Logs.DEFAULT_CHANNEL);
		}
		public function inspectch(channel:*, obj:Object, showInherit:Boolean = true):void{
			throwErrorIfNotStarted("inspectch()");
			_central.refs.inspect(obj, showInherit, ConsoleCentral.MakeChannelName(channel));
		}
		public function explode(obj:Object, depth:int = 3):void{
			addLine(new Array(_central.tools.explode(obj, depth)), 1, null, false, true);
		}
		public function explodech(channel:*, obj:Object, depth:int = 3):void{
			addLine(new Array(_central.tools.explode(obj, depth)), 1, channel, false, true);
		}
		public function get paused():Boolean{
			throwErrorIfNotStarted("minimumPriority");
			return _central.paused;
		}
		public function set paused(newV:Boolean):void{
			throwErrorIfNotStarted("minimumPriority");
			_central.paused = newV;
		}
		//
		//
		//
		/*
		// USE Cc.display.x, Cc.display.width, etc
		public function get width():Number{
			return _central.display.mainPanel.width;
		}
		public function set width(newW:Number):void{
			_central.display.mainPanel.width = newW;
		}
		public function set height(newW:Number):void{
			_central.display.mainPanel.height = newW;
		}
		public function get height():Number{
			return _central.display.mainPanel.height;
		}
		public function get x():Number{
			return _central.display.mainPanel.x;
		}
		public function set x(newW:Number):void{
			_central.display.mainPanel.x = newW;
		}
		public function set y(newW:Number):void{
			_central.display.mainPanel.y = newW;
		}
		public function get y():Number{
			return _central.display.mainPanel.y;
		}
		public function set visible(v:Boolean):void{
			_central.display.visible = v;
			if(v) _central.display.mainPanel.visible = true;
		}*/
		//
		// REMOTING
		//
		//
		// REMOTING
		//
		public function get remoting():Boolean{
			throwErrorIfNotStarted("minimumPriority");
			return _central.remoter.remoting == Remoting.SENDER;
		}
		public function set remoting(b:Boolean):void{
			throwErrorIfNotStarted("minimumPriority");
			_central.remoter.remoting = b?Remoting.SENDER:Remoting.NONE;
		}
		public function remotingSocket(host:String, port:int):void{
			throwErrorIfNotStarted("minimumPriority");
			_central.remoter.remotingSocket(host, port);
		}
		//
		//
		//
		public function setViewingChannels(...channels:Array):void{
			throwErrorIfNotStarted("minimumPriority");
			_central.display.mainPanel.setViewingChannels.apply(this, channels);
		}
		public function setIgnoredChannels(...channels:Array):void{
			throwErrorIfNotStarted("minimumPriority");
			_central.display.mainPanel.setIgnoredChannels.apply(this, channels);
		}
		public function set minimumPriority(level:uint):void{
			throwErrorIfNotStarted("minimumPriority");
			_central.display.mainPanel.priority = level;
		}
		public function addLine(strings:Array, priority:int = 0, channel:* = null,isRepeating:Boolean = false, html:Boolean = false, stacks:int = -1):void{
			throwErrorIfNotStarted();
			
			var txt:String = "";
			var len:int = strings.length;
			for(var i:int = 0; i < len; i++){
				txt += (i?" ":"")+_central.refs.makeString(strings[i], null, html);
			}
			
			if(priority >= _central.config.autoStackPriority && stacks<0) stacks = _central.config.defaultStackDepth;
			
			if(!html && stacks>0){
				txt += _central.tools.getStack(stacks, priority);
			}
			_central.logs.add(new Log(txt, ConsoleCentral.MakeChannelName(channel), priority, isRepeating, html));
		}
		//
		// COMMAND LINE
		//
		public function set commandLine(b:Boolean):void{
			_central.display.mainPanel.commandLine = b;
		}
		public function get commandLine ():Boolean{
			return _central.display.mainPanel.commandLine;
		}
		public function addSlashCommand(name:String, callback:Function, desc:String = "", alwaysAvailable:Boolean = true, endOfArgsMarker:String = ";"):void{
			_central.cl.addSlashCommand(name, callback, desc, alwaysAvailable, endOfArgsMarker);
		}
		//
		// LOGGING
		//
		public function add(string:*, priority:int = 2, isRepeating:Boolean = false):void{
			addLine([string], priority, Logs.DEFAULT_CHANNEL, isRepeating);
		}
		public function stack(string:*, depth:int = -1, priority:int = 5):void{
			addLine([string], priority, Logs.DEFAULT_CHANNEL, false, false, depth>=0?depth:_central.config.defaultStackDepth);
		}
		public function stackch(channel:*, string:*, depth:int = -1, priority:int = 5):void{
			addLine([string], priority, channel, false, false, depth>=0?depth:_central.config.defaultStackDepth);
		}
		
		public function set visible(v:Boolean):void{
			display.visible = v;
		}
		public function get visible():Boolean{
			return display.visible;
		}
		
		public function log(...strings):void{
			addLine(strings, LOG);
		}
		public function info(...strings):void{
			addLine(strings, INFO);
		}
		public function debug(...strings):void{
			addLine(strings, DEBUG);
		}
		public function warn(...strings):void{
			addLine(strings, WARN);
		}
		public function error(...strings):void{
			addLine(strings, ERROR);
		}
		public function fatal(...strings):void{
			addLine(strings, FATAL);
		}
		public function ch(channel:*, string:*, priority:Number = 2, isRepeating:Boolean = false):void{
			addLine([string], priority, channel, isRepeating);
		}
		public function logch(channel:*, ...strings):void{
			addLine(strings, LOG, channel);
		}
		public function infoch(channel:*, ...strings):void{
			addLine(strings, INFO, channel);
		}
		public function debugch(channel:*, ...strings):void{
			addLine(strings, DEBUG, channel);
		}
		public function warnch(channel:*, ...strings):void{
			addLine(strings, WARN, channel);
		}
		public function errorch(channel:*, ...strings):void{
			addLine(strings, ERROR, channel);
		}
		public function fatalch(channel:*, ...strings):void{
			addLine(strings, FATAL, channel);
		}
		public function addCh(channel:*, strings:Array, priority:int = 2, isRepeating:Boolean = false):void{
			addLine(strings, priority, channel, isRepeating);
		}
		public function addHTML(...strings):void{
			addLine(strings, 2, Logs.DEFAULT_CHANNEL, false, testHTML(strings));
		}
		public function addHTMLch(channel:*, priority:int, ...strings):void{
			addLine(strings, priority, channel, false, testHTML(strings));
		}
		private function testHTML(args:Array):Boolean{
			try{
				new XML("<p>"+args.join("")+"</p>"); // OR use RegExp?
			}catch(err:Error){
				return false;
			}
			return true;
		}
		
		//
		public function get central():ConsoleCentral{
			throwErrorIfNotStarted("central");
			return _central;
		}
		public function get display():ConsoleLayer{
			throwErrorIfNotStarted("display");
			return _central.display;
		}
		public function get mainPanel():MainPanel{
			throwErrorIfNotStarted("mainPanel");
			return display.mainPanel;
		}
		public function get config():ConsoleConfig{
			if(_config == null) _config = new ConsoleConfig();
			return _config;
		}
		
		private function throwErrorIfNotStarted(propName:String = null):void{
			if(!started)
			{
				if(propName)
				{
					propName = "\""+propName+"\"";
				}
				throw new Error("Call to console "+propName+" before Console have started.");
			}
		}
		//
		//
		//
		public function clear(channel:String = null):void{
			if(!started) return;
			_central.logs.clear(channel);
			if(!paused) _central.display.mainPanel.updateToBottom();
			_central.display.updateMenu();
		}
		public function getAllLog(splitter:String = "\r\n"):String{
			throwErrorIfNotStarted("getAllLog()");
			return _central.logs.getLogsAsString(splitter);
		}
		
	}
}