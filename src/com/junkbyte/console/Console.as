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
	import flash.utils.getTimer;
	import flash.system.Capabilities;
	import com.junkbyte.console.core.CommandLine;
	import com.junkbyte.console.core.ConsoleTools;
	import com.junkbyte.console.core.Graphing;
	import com.junkbyte.console.core.KeyBinder;
	import com.junkbyte.console.core.LogReferences;
	import com.junkbyte.console.core.Logs;
	import com.junkbyte.console.core.MemoryMonitor;
	import com.junkbyte.console.core.Remoting;
	import com.junkbyte.console.view.PanelsManager;
	import com.junkbyte.console.view.RollerPanel;
	import com.junkbyte.console.vos.Log;

	import flash.display.DisplayObjectContainer;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.KeyboardEvent;
	import flash.geom.Rectangle;
	import flash.net.SharedObject;
	/**
	 * Console is the main class. 
	 * Please see com.junkbyte.console.Cc for documentation as it shares the same properties and methods structure.
	 * @see http://code.google.com/p/flash-console/
	 * @see com.junkbyte.console.Cc
	 */
	public class Console extends Sprite {

		public static const VERSION:Number = 2.6;
		public static const VERSION_STAGE:String = "";
		public static const BUILD:int = 611;
		public static const BUILD_DATE:String = "2012/02/22 00:11";
		//
		public static const LOG:uint = 1;
		public static const INFO:uint = 3;
		public static const DEBUG:uint = 6;
		public static const WARN:uint = 8;
		public static const ERROR:uint = 9;
		public static const FATAL:uint = 10;
		//
		public static const GLOBAL_CHANNEL:String = " * ";
		public static const DEFAULT_CHANNEL:String = "-";
		public static const CONSOLE_CHANNEL:String = "C";
		public static const FILTER_CHANNEL:String = "~";
		//
		private var _config:ConsoleConfig;
		private var _panels:PanelsManager;
		private var _cl:CommandLine;
		private var _kb:KeyBinder;
		private var _refs:LogReferences;
		private var _mm:MemoryMonitor;
		private var _graphing:Graphing;
		private var _remoter:Remoting;
		private var _tools:ConsoleTools;
		//
		private var _topTries:int = 50;
		private var _paused:Boolean;
		private var _rollerKey:KeyBind;
		private var _logs:Logs;
		
		private var _so:SharedObject;
		private var _soData:Object = {};
		
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
			name = "Console";
			if(config == null) config = new ConsoleConfig();
			_config = config;
			if (password) {
				_config.keystrokePassword = password;
			}
			//
			_remoter = new Remoting(this);
			_logs = new Logs(this);
			_refs = new LogReferences(this);
			_cl = new CommandLine(this);
			_tools =  new ConsoleTools(this);
			_graphing = new Graphing(this);
			_mm = new MemoryMonitor(this);
			_kb = new KeyBinder(this);
			
			cl.addCLCmd("remotingSocket", function(str:String = ""):void{
				var args:Array = str.split(/\s+|\:/);
				remotingSocket(args[0], args[1]);
			}, "Connect to socket remote. /remotingSocket ip port");
			
			if(_config.sharedObjectName){
				try{
					_so = SharedObject.getLocal(_config.sharedObjectName, _config.sharedObjectPath);
					_soData = _so.data;
				}catch(e:Error){
					
				}
			}
			
			_config.style.updateStyleSheet();
			_panels = new PanelsManager(this);
			if(password) visible = false;
			
			//report("<b>Console v"+VERSION+VERSION_STAGE+" b"+BUILD+". Happy coding!</b>", -2);
			report("<b>Console v"+VERSION+VERSION_STAGE+"</b> build "+BUILD+". "+Capabilities.playerType+" "+Capabilities.version+".", -2);
			
			// must have enterFrame here because user can start without a parent display and use remoting.
			addEventListener(Event.ENTER_FRAME, _onEnterFrame);
			addEventListener(Event.ADDED_TO_STAGE, stageAddedHandle);
		}
		private function stageAddedHandle(e:Event=null):void{
			if(_cl.base == null) _cl.base = parent;
			if(loaderInfo){
				listenUncaughtErrors(loaderInfo);
			}
			removeEventListener(Event.ADDED_TO_STAGE, stageAddedHandle);
			addEventListener(Event.REMOVED_FROM_STAGE, stageRemovedHandle);
			stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave, false, 0, true);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, _kb.keyDownHandler, false, 0, true);
			stage.addEventListener(KeyboardEvent.KEY_UP, _kb.keyUpHandler, false, 0, true);
		}
		private function stageRemovedHandle(e:Event=null):void{
			_cl.base = null;
			removeEventListener(Event.REMOVED_FROM_STAGE, stageRemovedHandle);
			addEventListener(Event.ADDED_TO_STAGE, stageAddedHandle);
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, _kb.keyDownHandler);
			stage.removeEventListener(KeyboardEvent.KEY_UP, _kb.keyUpHandler);
		}
		private function onStageMouseLeave(e:Event):void{
			_panels.tooltip(null);
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#listenUncaughtErrors()
		 */
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
				str = _refs.makeString(error);
			}else if (error is ErrorEvent){
				str = ErrorEvent(error).text;
			}
			if(!str){
				str = String(error);
			}
			report(str, FATAL, false);
		}
		
		
		/**
		 * @copy com.junkbyte.console.Cc#addGraph()
		 */
		public function addGraph(name:String, obj:Object, property:String, color:Number = -1, key:String = null, rect:Rectangle = null, inverse:Boolean = false):void{
			_graphing.add(name, obj, property, color, key, rect, inverse);
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#fixGraphRange()
		 */
		public function fixGraphRange(name:String, min:Number = NaN, max:Number = NaN):void{
			_graphing.fixRange(name, min, max);
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#removeGraph()
		 */
		public function removeGraph(name:String, obj:Object = null, property:String = null):void{
			_graphing.remove(name, obj, property);
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#bindKey()
		 */
		public function bindKey(key:KeyBind, callback:Function ,args:Array = null):void{
			if(key) _kb.bindKey(key, callback, args);
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#addMenu()
		 */
		public function addMenu(key:String, callback:Function, args:Array = null, rollover:String = null):void{
			panels.mainPanel.addMenu(key, callback, args, rollover);
		}
		//
		// Panel settings
		// basically passing through to panels manager to save lines
		//
		
		/**
		 * @copy com.junkbyte.console.Cc#displayRoller
		 */
		public function get displayRoller():Boolean{
			return _panels.displayRoller;
		}
		public function set displayRoller(b:Boolean):void{
			_panels.displayRoller = b;
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#setRollerCaptureKey()
		 */
		public function setRollerCaptureKey(char:String, shift:Boolean = false, ctrl:Boolean = false, alt:Boolean = false):void{
			if(_rollerKey){
				bindKey(_rollerKey, null);
				_rollerKey = null;
			}
			if(char && char.length==1) {
				_rollerKey = new KeyBind(char, shift, ctrl, alt);
				bindKey(_rollerKey, onRollerCaptureKey);
			}
		}
		
		public function get rollerCaptureKey():KeyBind{
			return _rollerKey;
		}
		
		private function onRollerCaptureKey():void{
			if(displayRoller){
				report("Display Roller Capture:<br/>"+RollerPanel(_panels.getPanel(RollerPanel.NAME)).getMapString(true), -1);
			}
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#fpsMonitor
		 */
		public function get fpsMonitor():Boolean{
			return _graphing.fpsMonitor;
		}
		public function set fpsMonitor(b:Boolean):void{
			_graphing.fpsMonitor = b;
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#memoryMonitor
		 */
		public function get memoryMonitor():Boolean{
			return _graphing.memoryMonitor;
		}
		public function set memoryMonitor(b:Boolean):void{
			_graphing.memoryMonitor = b;
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#watch()
		 */
		public function watch(object:Object,name:String = null):String{
			return _mm.watch(object, name);
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#unwatch()
		 */
		public function unwatch(name:String):void{
			_mm.unwatch(name);
		}
		public function gc():void{
			_mm.gc();
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#store()
		 */
		public function store(name:String, obj:Object, strong:Boolean = false):void{
			_cl.store(name, obj, strong);
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#map()
		 */
		public function map(container:DisplayObjectContainer, maxstep:uint = 0):void{
			_tools.map(container, maxstep, DEFAULT_CHANNEL);
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#mapch()
		 */
		public function mapch(channel:*, container:DisplayObjectContainer, maxstep:uint = 0):void{
			_tools.map(container, maxstep, MakeChannelName(channel));
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#inspect()
		 */
		public function inspect(obj:Object, showInherit:Boolean = true):void{
			_refs.inspect(obj, showInherit, DEFAULT_CHANNEL);
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#inspectch()
		 */
		public function inspectch(channel:*, obj:Object, showInherit:Boolean = true):void{
			_refs.inspect(obj, showInherit, MakeChannelName(channel));
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#explode()
		 */
		public function explode(obj:Object, depth:int = 3):void{
			addLine(new Array(_tools.explode(obj, depth)), 1, null, false, true);
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#explodech()
		 */
		public function explodech(channel:*, obj:Object, depth:int = 3):void{
			addLine(new Array(_tools.explode(obj, depth)), 1, channel, false, true);
		}
		
		public function get paused():Boolean{
			return _paused;
		}
		public function set paused(newV:Boolean):void{
			if(_paused == newV) return;
			if(newV) report("Paused", 10);
			else report("Resumed", -1);
			_paused = newV;
			_panels.mainPanel.setPaused(newV);
		}
		//
		//
		//
		override public function get width():Number{
			return _panels.mainPanel.width;
		}
		override public function set width(newW:Number):void{
			_panels.mainPanel.width = newW;
		}
		override public function set height(newW:Number):void{
			_panels.mainPanel.height = newW;
		}
		override public function get height():Number{
			return _panels.mainPanel.height;
		}
		override public function get x():Number{
			return _panels.mainPanel.x;
		}
		override public function set x(newW:Number):void{
			_panels.mainPanel.x = newW;
		}
		override public function set y(newW:Number):void{
			_panels.mainPanel.y = newW;
		}
		override public function get y():Number{
			return _panels.mainPanel.y;
		}
		override public function set visible(v:Boolean):void{
			super.visible = v;
			if(v) _panels.mainPanel.visible = true;
		}
		//
		//
		//
		private function _onEnterFrame(e:Event):void{
			var time:int = getTimer();
			var hasNewLog:Boolean = _logs.update(time);
			_refs.update(time);
			_mm.update();
			var graphsList:Array;
			if(remoter.remoting != Remoting.RECIEVER)
			{
			 	graphsList = _graphing.update(stage?stage.frameRate:0);
			}
			_remoter.update();
			
			// VIEW UPDATES ONLY
			if(visible && parent){
				if(config.alwaysOnTop && parent.getChildAt(parent.numChildren-1) != this && _topTries>0){
					_topTries--;
					parent.addChild(this);
					report("Moved console on top (alwaysOnTop enabled), "+_topTries+" attempts left.",-1);
				}
				_panels.update(_paused, hasNewLog);
				if(graphsList) _panels.updateGraphs(graphsList);
			}
		}
		//
		// REMOTING
		//
		
		/**
		 * @copy com.junkbyte.console.Cc#remoting
		 */
		public function get remoting():Boolean{
			return _remoter.remoting == Remoting.SENDER;
		}
		public function set remoting(b:Boolean):void{
			_remoter.remoting = b?Remoting.SENDER:Remoting.NONE;
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#remotingSocket()
		 */
		public function remotingSocket(host:String, port:int):void{
			_remoter.remotingSocket(host, port);
		}
		//
		//
		//
		
		/**
		 * @copy com.junkbyte.console.Cc#setViewingChannels()
		 */
		public function setViewingChannels(...channels:Array):void{
			_panels.mainPanel.setViewingChannels.apply(this, channels);
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#setIgnoredChannels()
		 */
		public function setIgnoredChannels(...channels:Array):void{
			_panels.mainPanel.setIgnoredChannels.apply(this, channels);
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#minimumPriority
		 */
		public function set minimumPriority(level:uint):void{
			_panels.mainPanel.priority = level;
		}
		
		public function report(obj:*, priority:int = 0, skipSafe:Boolean = true, channel:String = null):void{
			if(!channel) channel = _panels.mainPanel.reportChannel;
			addLine([obj], priority, channel, false, skipSafe, 0);
		}
		
		public function addLine(strings:Array, priority:int = 0, channel:* = null,isRepeating:Boolean = false, html:Boolean = false, stacks:int = -1):void{
			var txt:String = "";
			var len:int = strings.length;
			for(var i:int = 0; i < len; i++){
				txt += (i?" ":"")+_refs.makeString(strings[i], null, html);
			}
			
			if(priority >= _config.autoStackPriority && stacks<0) stacks = _config.defaultStackDepth;
			
			if(!html && stacks>0){
				txt += _tools.getStack(stacks, priority);
			}
			_logs.add(new Log(txt, MakeChannelName(channel), priority, isRepeating, html));
		}
		//
		// COMMAND LINE
		//
		
		/**
		 * @copy com.junkbyte.console.Cc#commandLine
		 */
		public function set commandLine(b:Boolean):void{
			_panels.mainPanel.commandLine = b;
		}
		public function get commandLine ():Boolean{
			return _panels.mainPanel.commandLine;
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#addSlashCommand()
		 */
		public function addSlashCommand(name:String, callback:Function, desc:String = "", alwaysAvailable:Boolean = true, endOfArgsMarker:String = ";"):void{
			_cl.addSlashCommand(name, callback, desc, alwaysAvailable, endOfArgsMarker);
		}
		//
		// LOGGING
		//
		
		/**
		 * @copy com.junkbyte.console.Cc#add()
		 */
		public function add(string:*, priority:int = 2, isRepeating:Boolean = false):void{
			addLine([string], priority, DEFAULT_CHANNEL, isRepeating);
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#stack()
		 */
		public function stack(string:*, depth:int = -1, priority:int = 5):void{
			addLine([string], priority, DEFAULT_CHANNEL, false, false, depth>=0?depth:_config.defaultStackDepth);
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#stackch()
		 */
		public function stackch(channel:*, string:*, depth:int = -1, priority:int = 5):void{
			addLine([string], priority, channel, false, false, depth>=0?depth:_config.defaultStackDepth);
		}
		
		
		
		
		/**
		 * @copy com.junkbyte.console.Cc#log()
		 */
		public function log(...strings):void{
			addLine(strings, LOG);
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#info()
		 */
		public function info(...strings):void{
			addLine(strings, INFO);
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#debug()
		 */
		public function debug(...strings):void{
			addLine(strings, DEBUG);
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#warn()
		 */
		public function warn(...strings):void{
			addLine(strings, WARN);
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#error()
		 */
		public function error(...strings):void{
			addLine(strings, ERROR);
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#fatal()
		 */
		public function fatal(...strings):void{
			addLine(strings, FATAL);
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#ch()
		 */
		public function ch(channel:*, string:*, priority:int = 2, isRepeating:Boolean = false):void{
			addLine([string], priority, channel, isRepeating);
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#logch()
		 */
		public function logch(channel:*, ...strings):void{
			addLine(strings, LOG, channel);
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#infoch()
		 */
		public function infoch(channel:*, ...strings):void{
			addLine(strings, INFO, channel);
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#debugch()
		 */
		public function debugch(channel:*, ...strings):void{
			addLine(strings, DEBUG, channel);
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#warnch()
		 */
		public function warnch(channel:*, ...strings):void{
			addLine(strings, WARN, channel);
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#errorch()
		 */
		public function errorch(channel:*, ...strings):void{
			addLine(strings, ERROR, channel);
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#fatalch()
		 */
		public function fatalch(channel:*, ...strings):void{
			addLine(strings, FATAL, channel);
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#addCh()
		 */
		public function addCh(channel:*, strings:Array, priority:int = 2, isRepeating:Boolean = false):void{
			addLine(strings, priority, channel, isRepeating);
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#addHTML()
		 */
		public function addHTML(...strings):void{
			addLine(strings, 2, DEFAULT_CHANNEL, false, testHTML(strings));
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#addHTMLch()
		 */
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
		//
		//
		
		/**
		 * @copy com.junkbyte.console.Cc#clear()
		 */
		public function clear(channel:String = null):void{
			_logs.clear(channel);
			if(!_paused) _panels.mainPanel.updateToBottom();
			_panels.updateMenu();
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#getAllLog()
		 */
		public function getAllLog(splitter:String = "\r\n"):String{
			return _logs.getLogsAsString(splitter);
		}
		
		/**
		 * @copy com.junkbyte.console.Cc#config
		 */
		public function get config():ConsoleConfig{return _config;}
		
		/**
		 * Get panels manager which give access to console panels.
		 */
		public function get panels():PanelsManager{return _panels;}
		
		/**
		 * @private
		 */
		public function get cl():CommandLine{return _cl;}
		/**
		 * @private
		 */
		public function get remoter():Remoting{return _remoter;}
		/**
		 * @private
		 */
		public function get graphing():Graphing{return _graphing;}
		/**
		 * @private
		 */
		public function get refs():LogReferences{return _refs;}
		/**
		 * @private
		 */
		public function get logs():Logs{return _logs;}
		/**
		 * @private
		 */
		public function get mapper():ConsoleTools{return _tools;}
		
		/**
		 * @private
		 */
		public function get so():Object{return _soData;}
		/**
		 * @private
		 */
		public function updateSO(key:String = null):void{
			if(_so) {
				if(key) _so.setDirty(key);
				else _so.clear();
			}
		}
		//
		//
		//
		public static function MakeChannelName(obj:*):String{
			if(obj is String) return obj as String;
			else if(obj) return LogReferences.ShortClassName(obj);
			return DEFAULT_CHANNEL;
		}
	}
}