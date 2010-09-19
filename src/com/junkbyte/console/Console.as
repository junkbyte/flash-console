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
	import com.junkbyte.console.core.CommandLine;
	import com.junkbyte.console.core.CommandTools;
	import com.junkbyte.console.core.Graphing;
	import com.junkbyte.console.core.KeyBinder;
	import com.junkbyte.console.core.MemoryMonitor;
	//import com.junkbyte.console.core.ObjectsMonitor;
	import com.junkbyte.console.core.Remoting;
	import com.junkbyte.console.core.UserData;
	import com.junkbyte.console.utils.CastToString;
	import com.junkbyte.console.utils.ShortClassName;
	import com.junkbyte.console.view.MainPanel;
	import com.junkbyte.console.view.PanelsManager;
	import com.junkbyte.console.view.RollerPanel;
	import com.junkbyte.console.vos.Log;
	import com.junkbyte.console.vos.Logs;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.KeyboardEvent;
	import flash.geom.Rectangle;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getTimer;	

	/**
	 * Console is the main class. 
	 * Please see com.junkbyte.console.Cc for documentation as it shares the same properties and methods structure.
	 * @see http://code.google.com/p/flash-console/
	 * @see com.junkbyte.console.Cc
	 */
	public class Console extends Sprite {

		public static const VERSION:Number = 2.41;
		public static const VERSION_STAGE:String = "WIP";
		public static const BUILD:int = 504;
		public static const BUILD_DATE:String = "2010/09/19 20:53";
		
		public static const LITE:Boolean = false;
		//
		public static const NAME:String = "Console";
		//
		public static const LOG:uint = 1;
		public static const INFO:uint = 3;
		public static const DEBUG:uint = 6;
		public static const WARN:uint = 8;
		public static const ERROR:uint = 9;
		public static const FATAL:uint = 10;
		//
		public static const REMAPSPLIT:String = "|";
		//
		private var _config:ConsoleConfig;
		private var _panels:PanelsManager;
		private var _cl:CommandLine;
		private var _ud:UserData;
		private var _kb:KeyBinder;
		//private var _om:ObjectsMonitor;
		private var _mm:MemoryMonitor;
		private var _graphing:Graphing;
		private var _remoter:Remoting;
		private var _topTries:int = 50;
		//
		private var _paused:Boolean;
		private var _rollerKey:KeyBind;
		private var _channels:Array;
		private var _repeating:uint;
		private var _lines:Logs;
		private var _lineAdded:Boolean;
		
		/**
		 * Console is the main class. However please use C for singleton Console adapter.
		 * Using Console through C will also make sure you can remove console in a later date
		 * by simply removing Cc.start() or Cc.startOnStage()
		 * 
		 * 
		 * @see com.junkbyte.console.Cc
		 * @see http://code.google.com/p/flash-console/
		 */
		public function Console(pass:String = "", config:ConsoleConfig = null) {
			name = NAME;
			tabChildren = false; // Tabbing is not supported
			_config = config?config:new ConsoleConfig();
			//
			_channels = [_config.globalChannel, _config.defaultChannel];
			_lines = new Logs();
			_ud = new UserData(_config.sharedObjectName, _config.sharedObjectPath);
			//_om = new ObjectsMonitor();
			_cl = new CommandLine(this);
			_graphing = new Graphing(report);
			_remoter = new Remoting(this, pass);
			_kb = new KeyBinder(pass);
			_kb.addEventListener(Event.CONNECT, passwordEnteredHandle, false, 0, true);
			//
			// VIEW setup
			_config.style.updateStyleSheet();
			var mainPanel:MainPanel = new MainPanel(this, _lines, _channels);
			mainPanel.addEventListener(Event.CONNECT, onMainPanelConnectRequest, false, 0, true);
			_panels = new PanelsManager(this, mainPanel, _channels);
			//
			report("<b>Console v"+VERSION+VERSION_STAGE+" b"+BUILD+". Happy coding!</b>", -2);
			addEventListener(Event.ADDED_TO_STAGE, stageAddedHandle);
			if(pass) visible = false;
			// must have enterFrame here because user can start without a parent display and use remoting.
			addEventListener(Event.ENTER_FRAME, _onEnterFrame);
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
		}
		private function stageRemovedHandle(e:Event=null):void{
			_cl.base = null;
			removeEventListener(Event.REMOVED_FROM_STAGE, stageRemovedHandle);
			addEventListener(Event.ADDED_TO_STAGE, stageAddedHandle);
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, _kb.keyDownHandler);
		}
		private function onStageMouseLeave(e:Event):void{
			_panels.tooltip(null);
		}
		private function passwordEnteredHandle(e:Event):void{
			if(visible && !_panels.mainPanel.visible){
				_panels.mainPanel.visible = true;
			}else visible = !visible;
		}
		public function destroy():void{
			_remoter.close();
			removeEventListener(Event.ENTER_FRAME, _onEnterFrame);
			removeEventListener(Event.REMOVED_FROM_STAGE, stageRemovedHandle);
			removeEventListener(Event.ADDED_TO_STAGE, stageAddedHandle);
			_cl.destory();
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
			var error:Object = e["error"]; // for flash 9 compatibility
			var str:String;
			if (error is Error){
				str = CastToString(error);
			}else if (error is ErrorEvent){
				str = ErrorEvent(error).text;
			}
			if(!str){
				str = String(error);
			}
			report(str, FATAL, false);
		}
		
		public function addGraph(n:String, obj:Object, prop:String, col:Number = -1, key:String = null, rect:Rectangle = null, inverse:Boolean = false):void{
			if(obj == null) {
				report("ERROR: Graph ["+n+"] received a null object to graph property ["+prop+"].", 10);
				return;
			}
			_graphing.add(n,obj,prop,col,key,rect,inverse);
		}
		public function fixGraphRange(n:String, min:Number = NaN, max:Number = NaN):void{
			_graphing.fixRange(n, min, max);
		}
		public function removeGraph(n:String, obj:Object = null, prop:String = null):void{
			_graphing.remove(n, obj, prop);
		}
		//
		// WARNING: key binding hard references the function. 
		// This should only be used for development purposes only.
		//
		public function bindKey(key:KeyBind, fun:Function ,args:Array = null):void{
			if(!_kb.bindKey(key, fun, args))
			{
				report("Warning: bindKey character ["+key.char+"] is conflicting with Console password.",8);
			}else if(!config.quiet) {
				report((fun ==null?"Unbined":"Bined")+" "+key.toString()+".",-1);
			}
		}
		//
		// Panel settings
		// basically passing through to panels manager to save lines
		//
		public function setPanelArea(panelname:String, rect:Rectangle):void{
			_panels.setPanelArea(panelname, rect);
		}
		//
		public function get displayRoller():Boolean{
			return _panels.displayRoller;
		}
		public function set displayRoller(b:Boolean):void{
			_panels.displayRoller = b;
		}
		public function setRollerCaptureKey(char:String, shift:Boolean = false, ctrl:Boolean = false, alt:Boolean = false):void{
			if(_rollerKey){
				_kb.bindKey(_rollerKey, null);
				_rollerKey = null;
			}
			if(char && char.length==1) {
				_rollerKey = new KeyBind(char, shift, ctrl, alt);
				_kb.bindKey(_rollerKey, onRollerCaptureKey);
			}
		}
		public function get rollerCaptureKey():KeyBind{
			return _rollerKey;
		}
		private function onRollerCaptureKey():void{
			if(displayRoller){
				report("Display Roller Capture:<br/>"+RollerPanel(_panels.getPanel(RollerPanel.NAME)).capture(), -1);
			}
		}
		//
		public function get fpsMonitor():Boolean{
			if(_remoter.isRemote) return panels.fpsMonitor;
			return _graphing.fpsMonitor;
		}
		public function set fpsMonitor(b:Boolean):void{
			if(_remoter.isRemote){
				_remoter.send(Remoting.FPS, b);
			}else{
				_graphing.fpsMonitor = b;
				panels.mainPanel.updateMenu();
			}
		}
		//
		public function get memoryMonitor():Boolean{
			if(_remoter.isRemote) return panels.memoryMonitor;
			return _graphing.memoryMonitor;
		}
		public function set memoryMonitor(b:Boolean):void{
			if(_remoter.isRemote){
				_remoter.send(Remoting.MEM, b);
			}else{
				_graphing.memoryMonitor = b;
				panels.mainPanel.updateMenu();
			}
		}
		
		//
		public function watch(o:Object,n:String = null):String{
			var className:String = getQualifiedClassName(o);
			if(!n) n = className+"@"+getTimer();
			if(!_mm) _mm = new MemoryMonitor();
			var nn:String = _mm.watch(o,n);
			if(!config.quiet) report("Watching <b>"+className+"</b> as <p5>"+ nn +"</p5>.",-1);
			return nn;
		}
		public function unwatch(n:String):void{
			if(_mm) _mm.unwatch(n);
		}
		public function gc():void{
			if(remote){
				try{
					report("Sending garbage collection request to client",-1);
					_remoter.send(Remoting.GC);
				}catch(e:Error){
					report(e,10);
				}
			}else{
				var ok:Boolean = MemoryMonitor.Gc();
				var str:String = "Manual garbage collection "+(ok?"successful.":"FAILED. You need debugger version of flash player.");
				report(str,(ok?-1:10));
			}
		}
		public function store(n:String, obj:Object, strong:Boolean = false):void{
			_cl.store(n, obj, strong);
		}
		public function map(base:DisplayObjectContainer, maxstep:uint = 0):void{
			_cl.map(base, maxstep);
		}
		public function inspect(obj:Object, detail:Boolean = true):void{
			_cl.inspect(obj,detail);
		}
		public function explode(obj:Object, depth:int = 3):void{
			report(CommandTools.explode(obj, depth), 1);
		}
		/*public function monitor(obj:Object, n:String = null):void{
			if(obj == null || typeof obj != "object"){
				report("Can not monitor "+getQualifiedClassName(obj)+".", 10);
				return;
			}
			_om.monitor(obj, n);
		}
		public function unmonitor(i:String = null):void{
			if(_remoter.isRemote){
				_remoter.send(Remoting.CALL_UNMONITOR, i);
			}else{
				_om.unmonitor(i);
			}
		}
		public function monitorIn(i:String, n:String):void{
			if(_remoter.isRemote){
				_remoter.send(Remoting.CALL_MONITORIN, i,n);
			}else{
				_om.monitorIn(i,n);
			}
		}
		public function monitorOut(i:String):void{
			if(_remoter.isRemote){
				_remoter.send(Remoting.CALL_MONITOROUT, i);
			}else{
				_om.monitorOut(i);
			}
		}*/
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
		//
		//
		//
		private function _onEnterFrame(e:Event):void{
			
			if(_repeating > 0) _repeating--;
			
			if(_mm){
				var arr:Array = _mm.update();
				if(arr.length>0){
					report("<b>GARBAGE COLLECTED "+arr.length+" item(s): </b>"+arr.join(", "),-2);
					if(_mm.count == 0) _mm = null;
				}
			}
			var graphsList:Array;
			if(!_remoter.isRemote){
			 	//om = _om.update();
			 	graphsList = _graphing.update(stage?stage.frameRate:0);
			}
			_remoter.update(graphsList);
			
			// VIEW UPDATES ONLY
			if(visible && parent){
				if(config.alwaysOnTop && parent.getChildAt(parent.numChildren-1) != this && _topTries>0){
					_topTries--;
					parent.addChild(this);
					if(!config.quiet) report("Moved console on top (alwaysOnTop enabled), "+_topTries+" attempts left.",-1);
				}
				_panels.update(_paused, _lineAdded);
				//if(!_paused && om != null) _panels.updateObjMonitors(om);
				if(graphsList) _panels.updateGraphs(graphsList, !_paused); 
				_lineAdded = false;
			}
		}
		//
		// REMOTING
		//
		public function get remoting():Boolean{
			return _remoter.remoting;
		}
		public function set remoting(newV:Boolean):void{
			_remoter.remoting = newV;
		}
		public function get remote():Boolean{
			return _remoter.isRemote;
		}
		public function set remote(newV:Boolean):void{
			_remoter.isRemote = newV;
			_panels.updateMenu();
		}
		public function set remotingPassword(str:String):void{
			_remoter.remotingPassword = str;
		}
		private function onMainPanelConnectRequest(e:Event) : void {
			_remoter.login(MainPanel(e.currentTarget).commandLineText);
		}
		//
		//
		//
		public function get viewingChannels():Array{
			return _panels.mainPanel.viewingChannels;
		}
		public function set viewingChannels(a:Array):void{
			_panels.mainPanel.viewingChannels = a;
		}
		public function report(obj:*, priority:Number = 0, skipSafe:Boolean = true):void{
			addLine(obj, priority, _config.consoleChannel, false, skipSafe, 0);
		}
		public function addLine(obj:*, priority:Number = 0,channel:String = null,isRepeating:Boolean = false, skipSafe:Boolean = false, stacks:int = -1):void{
			var txt:String = CastToString(obj);
			var isRepeat:Boolean = (isRepeating && _repeating > 0);
			if(!channel || channel == _config.globalChannel) channel = _config.defaultChannel;
			if(priority >= _config.autoStackPriority && stacks<0) stacks = _config.defaultStackDepth;
			if(skipSafe) stacks = -1;
			var stackArr:Array = stacks>0?getStack(stacks):null;
			
			if( _config.tracing && !isRepeat && _config.traceCall != null){
				_config.traceCall(channel, (stackArr==null?txt:(txt+"\n @ "+stackArr.join("\n @ "))), priority);
			}
			if(!skipSafe){
				txt = txt.replace(/</gm, "&lt;");
 				txt = txt.replace(new RegExp(">", "gm"), "&gt;");
			}
			if(stackArr) {
				var tp:int = priority;
				for each(var sline:String in stackArr) {
					txt += "\n<p"+tp+"> @ "+sline+"</p"+tp+">";
					if(tp>0) tp--;
				}
			}
			if(_channels.indexOf(channel) < 0){
				_channels.push(channel);
			}
			var line:Log = new Log(txt,channel,priority, isRepeating, skipSafe);
			if(isRepeat){
				_lines.pop();
				_lines.push(line);
			}else{
				_repeating = isRepeating?_config.maxRepeats:0;
				_lines.push(line);
				if(_config.maxLines > 0 ){
					var off:int = _lines.length - _config.maxLines;
					if(off > 0){
						_lines.shift(off);
					}
				}
			}
			_lineAdded = true;
			
			_remoter.addLineQueue(line);
		}
		private function getStack(depth:int):Array{
			var e:Error = new Error();
			var str:String = e.hasOwnProperty("getStackTrace")?e.getStackTrace():null;
			if(!str) return null;
			var lines:Array = str.split(/\n\sat\s/);
			var len:int = lines.length;
			var reg:RegExp = new RegExp("Function|"+getQualifiedClassName(this)+"|"+getQualifiedClassName(Cc));
			for (var i:int = 2; i < len; i++){
				if((lines[i].search(reg) != 0)){
					return lines.slice(i, i+depth);
				}
			}
			return null;
		}
		//
		// COMMAND LINE
		//
		public function set commandLine(b:Boolean):void{
			if(b) _config.commandLineAllowed = true;
			_panels.mainPanel.commandLine = b;
		}
		public function get commandLine ():Boolean{
			return _panels.mainPanel.commandLine;
		}
		public function set commandBase (v:Object):void{
			if(v) _cl.base = v;
		}
		public function get commandBase ():Object{
			return _cl.base;
		}
		public function runCommand(line:String):*{
			if(_remoter.isRemote){
				if(line && line.charAt(0) == "~"){
					return _cl.run(line.substring(1));
				}else{
					report("Run command at remote: "+line,-2);
					if(!_remoter.send(Remoting.CMD, line)){
						report("Command could not be sent to client.", 10);
					}
				}
			}else{
				return _cl.run(line);
			}
			return null;
		}
		public function addSlashCommand(n:String, callback:Function):void{
			_cl.addSlashCommand(n, callback);
		}
		//
		// LOGGING
		//
		public function ch(channel:*, newLine:*, priority:Number = 2, isRepeating:Boolean = false):void{
			var chn:String;
			if(channel is String) chn = channel as String;
			else if(channel) chn = ShortClassName(channel);
			else chn = _config.defaultChannel;
			addLine(newLine, priority,chn, isRepeating);
		}
		public function add(newLine:*, priority:Number = 2, isRepeating:Boolean = false):void{
			addLine(newLine, priority, _config.defaultChannel, isRepeating);
		}
		public function stack(newLine:*, depth:int = -1, priority:Number = 5):void{
			addLine(newLine, priority, _config.defaultChannel, false, false, depth>=0?depth:_config.defaultStackDepth);
		}
		public function stackch(ch:String, newLine:*, depth:int = -1, priority:Number = 5):void{
			addLine(newLine, priority, ch, false, false, depth>=0?depth:_config.defaultStackDepth);
		}
		public function log(...args):void{
			addLine(joinArgs(args), LOG);
		}
		public function info(...args):void{
			addLine(joinArgs(args), INFO);
		}
		public function debug(...args):void{
			addLine(joinArgs(args), DEBUG);
		}
		public function warn(...args):void{
			addLine(joinArgs(args), WARN);
		}
		public function error(...args):void{
			addLine(joinArgs(args), ERROR);
		}
		public function fatal(...args):void{
			addLine(joinArgs(args), FATAL);
		}
		public function logch(channel:*, ...args):void{
			ch(channel, joinArgs(args), LOG);
		}
		public function infoch(channel:*, ...args):void{
			ch(channel, joinArgs(args), INFO);
		}
		public function debugch(channel:*, ...args):void{
			ch(channel, joinArgs(args), DEBUG);
		}
		public function warnch(channel:*, ...args):void{
			ch(channel, joinArgs(args), WARN);
		}
		public function errorch(channel:*, ...args):void{
			ch(channel, joinArgs(args), ERROR);
		}
		public function fatalch(channel:*, ...args):void{
			ch(channel, joinArgs(args), FATAL);
		}
		// Need to specifically cast to string in array to produce correct results
		// e.g: new Array("str",null,undefined,0).toString() // traces to: str,,,0, SHOULD BE: str,null,undefined,0
		private function joinArgs(args:Array):String{
			var str:String = "";
			var len:int = args.length;
			for(var i:int = 0; i < len; i++){
				str += (i?" ":"")+CastToString(args[i]);
			}
			return str;
		}
		//
		//
		//
		public function clear(channel:String = null):void{
			if(channel){
				var line:Log = _lines.first;
				while(line){
					if(line.c == channel){
						_lines.remove(line);
					}
					line = line.next;
				}
				var ind:int = _channels.indexOf(channel);
				if(ind>=0) _channels.splice(ind,1);
			}else{
				_lines.clear();
				_channels.splice(0);
				_channels.push(_config.globalChannel, _config.defaultChannel);
			}
			if(!_paused) _panels.mainPanel.updateToBottom();
			_panels.updateMenu();
		}
		//
		public function get config():ConsoleConfig{return _config;}
		public function get panels():PanelsManager{return _panels;}
		public function get cl():CommandLine{return _cl;}
		public function get ud():UserData{return _ud;}
		//public function get om():ObjectsMonitor{return _om;}
		public function get graphing():Graphing{return _graphing;}
		//
		public function getLogsAsBytes():Array{
			var a:Array = [];
			var line:Log = _lines.first;
			while(line){
				a.push(line.toBytes());
				line = line.next;
			}
			return a;
		}
		public function getAllLog(splitter:String = "\n"):String{
			var str:String = "";
			var line:Log = _lines.first;
			while(line){
				str += (line.toString()+(line.next?splitter:""));
				line = line.next;
			}
			return str;
		}
	}
}