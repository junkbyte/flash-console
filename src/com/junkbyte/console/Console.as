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
	import com.junkbyte.console.view.RollerPanel;
	import com.junkbyte.console.core.Logs;
	import com.junkbyte.console.core.ConsoleCentral;
	import com.junkbyte.console.core.ConsoleCore;
	import com.junkbyte.console.core.Remoting;
	import com.junkbyte.console.vos.Log;

	import flash.display.DisplayObjectContainer;
	import flash.display.LoaderInfo;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	/**
	 * Console is the main class. 
	 * Please see com.junkbyte.console.Cc for documentation as it shares the same properties and methods structure.
	 * @see http://code.google.com/p/flash-console/
	 * @see com.junkbyte.console.Cc
	 */
	public class Console extends ConsoleCore{

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
		private var _rollerKey:KeyBind;
		
		/**
		 * Console is the main class. However please use Cc for singleton Console adapter.
		 * Using Console through Cc will also make sure you can remove console in a later date
		 * by simply removing Cc.start() or Cc.startOnStage()
	 	 * See com.junkbyte.console.Cc for documentation as it shares the same properties and methods structure.
		 * 
		 * @see com.junkbyte.console.Cc
		 * @see http://code.google.com/p/flash-console/
		 */
		public function Console(password:String = "", config:ConsoleConfig = null) {
			
			if(config == null) config = new ConsoleConfig();
			
			super(createCentral(config));
			
			report("<b>Console v"+VERSION+VERSION_STAGE+"</b> build "+BUILD+". "+Capabilities.playerType+" "+Capabilities.version+".", -2);
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
			report(str, FATAL, false);
		}
		

		public function addGraph(name:String, obj:Object, property:String, color:Number = -1, key:String = null, rect:Rectangle = null, inverse:Boolean = false):void{
			_central.graphing.add(name, obj, property, color, key, rect, inverse);
		}
		public function fixGraphRange(name:String, min:Number = NaN, max:Number = NaN):void{
			_central.graphing.fixRange(name, min, max);
		}
		public function removeGraph(name:String, obj:Object = null, property:String = null):void{
			_central.graphing.remove(name, obj, property);
		}
		
		//
		// WARNING: key binding hard references the function and arguments.
		// This should only be used for development purposes only.
		//
		public function bindKey(key:KeyBind, callback:Function ,args:Array = null):void{
			if(key) _central.kb.bindKey(key, callback, args);
		}
		//
		// WARNING: Add menu hard references the function and arguments.
		//
		public function addMenu(key:String, callback:Function, args:Array = null, rollover:String = null):void{
			panels.mainPanel.addMenu(key, callback, args, rollover);
		}
		//
		// Panel settings
		// basically passing through to panels manager to save lines
		//
		public function get displayRoller():Boolean{
			return panels.displayRoller;
		}
		public function set displayRoller(b:Boolean):void{
			panels.displayRoller = b;
		}

		public function setRollerCaptureKey(char:String, shift:Boolean = false, ctrl:Boolean = false, alt:Boolean = false):void{
			if(_rollerKey){
				_central.kb.bindKey(_rollerKey, null);
				_rollerKey = null;
			}
			if(char && char.length==1) {
				_rollerKey = new KeyBind(char, shift, ctrl, alt);
				_central.kb.bindKey(_rollerKey, onRollerCaptureKey);
			}
		}
		private function onRollerCaptureKey():void{
			if(displayRoller){
				report("Display Roller Capture:<br/>"+RollerPanel(panels.getPanel(RollerPanel.NAME)).getMapString(true), -1);
			}
		}
		public function get rollerCaptureKey():KeyBind{
			return _rollerKey;
		}
		//
		public function get fpsMonitor():Boolean{
			return _central.graphing.fpsMonitor;
		}
		public function set fpsMonitor(b:Boolean):void{
			_central.graphing.fpsMonitor = b;
		}
		//
		public function get memoryMonitor():Boolean{
			return _central.graphing.memoryMonitor;
		}
		public function set memoryMonitor(b:Boolean):void{
			_central.graphing.memoryMonitor = b;
		}
		
		//
		public function watch(object:Object,name:String = null):String{
			return _central.mm.watch(object, name);
		}
		public function unwatch(name:String):void{
			_central.mm.unwatch(name);
		}
		public function gc():void{
			_central.mm.gc();
		}
		public function store(name:String, obj:Object, strong:Boolean = false):void{
			_central.cl.store(name, obj, strong);
		}
		public function map(container:DisplayObjectContainer, maxstep:uint = 0):void{
			_central.tools.map(container, maxstep, Logs.DEFAULT_CHANNEL);
		}
		public function mapch(channel:*, container:DisplayObjectContainer, maxstep:uint = 0):void{
			_central.tools.map(container, maxstep, ConsoleCentral.MakeChannelName(channel));
		}
		public function inspect(obj:Object, showInherit:Boolean = true):void{
			_central.refs.inspect(obj, showInherit, Logs.DEFAULT_CHANNEL);
		}
		public function inspectch(channel:*, obj:Object, showInherit:Boolean = true):void{
			_central.refs.inspect(obj, showInherit, ConsoleCentral.MakeChannelName(channel));
		}
		public function explode(obj:Object, depth:int = 3):void{
			addLine(new Array(_central.tools.explode(obj, depth)), 1, null, false, true);
		}
		public function explodech(channel:*, obj:Object, depth:int = 3):void{
			addLine(new Array(_central.tools.explode(obj, depth)), 1, channel, false, true);
		}
		public function get paused():Boolean{
			return _central.paused;
		}
		public function set paused(newV:Boolean):void{
			_central.paused = newV;
		}
		//
		//
		//
		public function get width():Number{
			return panels.mainPanel.width;
		}
		public function set width(newW:Number):void{
			panels.mainPanel.width = newW;
		}
		public function set height(newW:Number):void{
			panels.mainPanel.height = newW;
		}
		public function get height():Number{
			return panels.mainPanel.height;
		}
		public function get x():Number{
			return panels.mainPanel.x;
		}
		public function set x(newW:Number):void{
			panels.mainPanel.x = newW;
		}
		public function set y(newW:Number):void{
			panels.mainPanel.y = newW;
		}
		public function get y():Number{
			return panels.mainPanel.y;
		}
		public function set visible(v:Boolean):void{
			panels.visible = v;
			if(v) panels.mainPanel.visible = true;
		}
		//
		// REMOTING
		//
		public function get remoting():Boolean{
			return _central.remoter.remoting == Remoting.SENDER;
		}
		public function set remoting(b:Boolean):void{
			_central.remoter.remoting = b?Remoting.SENDER:Remoting.NONE;
		}
		public function remotingSocket(host:String, port:int):void{
			_central.remoter.remotingSocket(host, port);
		}
		public function set remotingPassword(password:String):void{
			_central.remoter.remotingPassword = password;
		}
		//
		//
		//
		public function setViewingChannels(...channels:Array):void{
			panels.mainPanel.setViewingChannels.apply(this, channels);
		}
		public function setIgnoredChannels(...channels:Array):void{
			panels.mainPanel.setIgnoredChannels.apply(this, channels);
		}
		public function set minimumPriority(level:uint):void{
			panels.mainPanel.priority = level;
		}
		public function addLine(strings:Array, priority:int = 0, channel:* = null,isRepeating:Boolean = false, html:Boolean = false, stacks:int = -1):void{
			var txt:String = "";
			var len:int = strings.length;
			for(var i:int = 0; i < len; i++){
				txt += (i?" ":"")+_central.refs.makeString(strings[i], null, html);
			}
			
			if(priority >= config.autoStackPriority && stacks<0) stacks = config.defaultStackDepth;
			
			if(!html && stacks>0){
				txt += _central.tools.getStack(stacks, priority);
			}
			_central.logs.add(new Log(txt, ConsoleCentral.MakeChannelName(channel), priority, isRepeating, html));
		}
		//
		// COMMAND LINE
		//
		public function set commandLine(b:Boolean):void{
			panels.mainPanel.commandLine = b;
		}
		public function get commandLine ():Boolean{
			return panels.mainPanel.commandLine;
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
			addLine([string], priority, Logs.DEFAULT_CHANNEL, false, false, depth>=0?depth:config.defaultStackDepth);
		}
		public function stackch(channel:*, string:*, depth:int = -1, priority:int = 5):void{
			addLine([string], priority, channel, false, false, depth>=0?depth:config.defaultStackDepth);
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
			return _central;
		}
		//
		//
		//
		public function clear(channel:String = null):void{
			_central.logs.clear(channel);
			if(!paused) panels.mainPanel.updateToBottom();
			panels.updateMenu();
		}
		public function getAllLog(splitter:String = "\r\n"):String{
			return _central.logs.getLogsAsString(splitter);
		}
		
	}
}