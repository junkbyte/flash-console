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
*/
package com.luaye.console {
	import com.luaye.console.core.CommandLine;
	import com.luaye.console.core.CommandTools;
	import com.luaye.console.core.Graphing;
	import com.luaye.console.core.KeyBinder;
	import com.luaye.console.core.MemoryMonitor;
	import com.luaye.console.core.ObjectsMonitor;
	import com.luaye.console.core.Remoting;
	import com.luaye.console.core.UserData;
	import com.luaye.console.utils.GetCSSfromStyle;
	import com.luaye.console.utils.Utils;
	import com.luaye.console.view.MainPanel;
	import com.luaye.console.view.PanelsManager;
	import com.luaye.console.view.RollerPanel;
	import com.luaye.console.vos.Log;
	import com.luaye.console.vos.Logs;

	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.geom.Rectangle;
	import flash.text.StyleSheet;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getTimer;

	/**
	 * Console is the main class. 
	 * Please see com.luaye.console.C for documentation as it shares the same properties and methods structure.
	 * @see http://code.google.com/p/flash-console/
	 * @see com.luaye.console.C
	 */
	public class Console extends Sprite {

		public static const VERSION:Number = 2.4;
		public static const VERSION_STAGE:String = "WIP";
		//
		public static const NAME:String = "Console";
		public static const PANEL_MAIN:String = "mainPanel";
		public static const PANEL_CHANNELS:String = "channelsPanel";
		public static const PANEL_FPS:String = "fpsPanel";
		public static const PANEL_MEMORY:String = "memoryPanel";
		public static const PANEL_ROLLER:String = "rollerPanel";
		//
		public static const GLOBAL_CHANNEL:String = " * ";
		public static const CONSOLE_CHANNEL:String = "C";
		public static const FILTERED_CHANNEL:String = "~";
		public static const DEFAULT_CHANNEL:String = "-";
		//
		public static const LOG_LEVEL:uint = 1;
		public static const INFO_LEVEL:uint = 3;
		public static const DEBUG_LEVEL:uint = 5;
		public static const WARN_LEVEL:uint = 7;
		public static const ERROR_LEVEL:uint = 9;
		public static const FATAL_LEVEL:uint = 10;
		//
		public static const FPS_MAX_LAG_FRAMES:uint = 25;
		public static const MAPPING_SPLITTER:String = "|";
		//
		// You can change this if you don't want to use default channel
		// Other remotes with different remoting channel won't be able to connect your flash.
		// Start with _ to work in any domain + platform (air/swf - local / network)
		// Change BEFORE starting remote / remoting
		public static var RemotingConnectionName:String = "_Console";
		// You can change this if you want to use different Shared data. set to null to avoid using.
		// Change BEFORE starting console.
		public static var SharedObjectName:String = "com/luaye/Console/UserData";
		//
		public var quiet:Boolean;
		public var maxLines:int = 1000;
		public var alwaysOnTop:Boolean = true;
		public var moveTopAttempts:int = 50;
		public var maxRepeats:uint = 75;
		public var rulerHidesMouse:Boolean = true;
		public var autoStackPriority:int = FATAL_LEVEL;
		public var defaultStackDepth:int = 3;
		//
		private var _style:ConsoleStyle;
		private var _css:StyleSheet;
		private var _panels:PanelsManager;
		private var _cl:CommandLine;
		private var _ud:UserData;
		private var _kb:KeyBinder;
		private var _om:ObjectsMonitor;
		private var _mm:MemoryMonitor;
		private var _graphing:Graphing;
		private var _remoter:Remoting;
		//
		private var _paused:Boolean;
		private var _tracing:Boolean;
		private var _mspf:Number;
		private var _previousTime:Number;
		private var _traceCall:Function = trace;
		private var _rollerCaptureKey:String;
		private var _commandLineAllowed:Boolean;
		private var _channels:Array = [GLOBAL_CHANNEL, DEFAULT_CHANNEL];
		private var _tracingChannels:Array = [];
		private var _repeating:uint;
		private var _lines:Logs;
		private var _lineAdded:Boolean;
		
		/**
		 * Console is the main class. However please use C for singleton Console adapter.
		 * Using Console through C will also make sure you can remove console in a later date
		 * by simply removing C.start() or C.startOnStage()
		 * 
		 * 
		 * @see com.luaye.console.C
		 * @see http://code.google.com/p/flash-console/
		 */
		public function Console(pass:String = "", skin:ConsoleStyle = null) {
			name = NAME;
			tabChildren = false; // Tabbing is not supported
			//
			_lines = new Logs();
			_ud = new UserData(SharedObjectName,"/");
			_om = new ObjectsMonitor();
			_cl = new CommandLine(this);
			_graphing = new Graphing(report);
			_remoter = new Remoting(this, pass);
			_kb = new KeyBinder(pass);
			_kb.addEventListener(KeyBinder.PASSWORD_ENTERED, passwordEnteredHandle, false, 0, true);
			//
			// VIEW setup
			_style = skin?skin:new ConsoleStyle();
			_css = GetCSSfromStyle(_style);
			var mainPanel:MainPanel = new MainPanel(this, _lines, _channels);
			mainPanel.addEventListener(Event.CONNECT, onMainPanelConnectRequest, false, 0, true);
			_panels = new PanelsManager(this, mainPanel, _channels);
			//
			report("<b>Console v"+VERSION+(VERSION_STAGE?(" "+VERSION_STAGE):"")+", Happy coding!</b>", -2);
			addEventListener(Event.ADDED_TO_STAGE, stageAddedHandle);
			if(pass) visible = false;
			// must have enterFrame here because user can start without a parent display and use remoting.
			addEventListener(Event.ENTER_FRAME, _onEnterFrame);
		}
		private function stageAddedHandle(e:Event=null):void{
			if(_cl.base == null) _cl.base = parent;
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
		public function bindKey(char:String, ctrl:Boolean, alt:Boolean, shift:Boolean, fun:Function ,args:Array = null):void{
			if(!char || char.length!=1){
				report("Binding key must be a single character. You gave ["+char+"]", 10);
				return;
			}
			_kb.bindKey(char, ctrl, alt, shift, fun, args);
			if(!quiet) report((fun ==null?"Unbined":"Bined")+" key <b>"+ char.toUpperCase() +"</b>"+ (ctrl?"+ctrl":"")+(alt?"+alt":"")+(shift?"+shift":"")+".",-1);
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
		public function setRollerCaptureKey(char:String, ctrl:Boolean = false, alt:Boolean = false, shift:Boolean = false):void{
			if(_rollerCaptureKey){
				_kb.bindByKey(_rollerCaptureKey, null);
				_rollerCaptureKey = null;
			}
			if(char && char.length==1) _rollerCaptureKey = _kb.bindKey(char, ctrl, alt, shift, onRollerCaptureKey);
		}
		public function get rollerCaptureKey():String{
			return _rollerCaptureKey;
		}
		private function onRollerCaptureKey():void{
			if(displayRoller){
				report("Display Roller Capture:<br/>"+RollerPanel(_panels.getPanel(PANEL_ROLLER)).capture(), -1);
			}
		}
		//
		public function get fpsMonitor():Boolean{
			if(_remoter.isRemote) return panels.fpsMonitor;
			return _graphing.fpsMonitor;
		}
		public function set fpsMonitor(b:Boolean):void{
			if(_remoter.isRemote){
				_remoter.send("fps", b);
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
				_remoter.send("mem", b);
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
			if(!quiet) report("Watching <b>"+className+"</b> as <p5>"+ nn +"</p5>.",-1);
			return nn;
		}
		public function unwatch(n:String):void{
			if(_mm) _mm.unwatch(n);
		}
		public function gc():void{
			if(remote){
				try{
					report("Sending garbage collection request to client",-1);
					_remoter.send("gc");
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
		public function monitor(obj:Object, n:String = null):void{
			if(obj == null || typeof obj != "object"){
				report("Can not monitor "+getQualifiedClassName(obj)+".", 10);
				return;
			}
			_om.monitor(obj, n);
		}
		public function unmonitor(i:String = null):void{
			_om.unmonitor(i);
		}
		public function monitorIn(i:String, n:String):void{
			_om.monitorIn(i,n);
		}
		public function monitorOut(i:String):void{
			_om.monitorOut(i);
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
		//
		//
		//
		private function _onEnterFrame(e:Event):void{
			var time:int = getTimer();
			_mspf = time-_previousTime;
			_previousTime = time;
			
			if(_repeating > 0) _repeating--;
			
			var om:Object;
			var graphsList:Array;
			if(!_paused){
				if(_mm!=null){
					var arr:Array = _mm.update();
					if(arr.length>0){
						report("<b>GARBAGE COLLECTED "+arr.length+" item(s): </b>"+arr.join(", "),-2);
						if(!_mm.haveItemsWatching) _mm = null;
					}
				}
				om = _om.update();
				if(!_remoter.isRemote) graphsList = _graphing.update(stage?stage.frameRate:0);
				if(_remoter.remoting) _remoter.update(graphsList);
			}
			// VIEW UPDATES ONLY
			if(visible && parent!=null){
				if(alwaysOnTop && parent.getChildAt(parent.numChildren-1) != this && moveTopAttempts>0){
					moveTopAttempts--;
					parent.addChild(this);
					if(!quiet) report("Moved console on top (alwaysOnTop enabled), "+moveTopAttempts+" attempts left.",-1);
				}
				_panels.mainPanel.update(!_paused && _lineAdded);
				_panels.update(_paused, _lineAdded);
				if(om != null) _panels.updateObjMonitors(om);
				if(graphsList) _panels.updateGraphs(graphsList); 
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
		public function get remoteDelay():uint{ return _remoter.delay; };
		public function set remoteDelay(i:uint):void{ _remoter.delay = i; };
		//
		//
		//
		public function get viewingChannels():Array{
			return _panels.mainPanel.viewingChannels;
		}
		public function set viewingChannels(a:Array):void{
			_panels.mainPanel.viewingChannels = a;
		}
		public function set tracingChannels(a:Array):void{
			_tracingChannels.splice(0);
			if(a){
				if(a.indexOf(Console.GLOBAL_CHANNEL)>=0) a = [];
				for each(var item:Object in a) _tracingChannels.push(item is Ch?(Ch(item).name):String(item));
			}
		}
		public function get tracingChannels():Array{
			return _tracingChannels.concat();
		}
		//
		public function get tracing():Boolean{
			return _tracing;
		}
		public function set tracing(b:Boolean):void{
			_tracing = b;
			_panels.mainPanel.updateMenu();
		}
		public function set traceCall (f:Function):void{
			if(f==null) report("C.traceCall function setter can not be null.", 10);
			else _traceCall = f;
		}
		public function get traceCall ():Function{
			return _traceCall;
		}
		public function report(obj:*,priority:Number = 0, skipSafe:Boolean = true):void{
			addLine(obj, priority, CONSOLE_CHANNEL, false, skipSafe, 0);
		}
		public function addLine(obj:*,priority:Number = 0,channel:String = null,isRepeating:Boolean = false, skipSafe:Boolean = false, stacks:int = -1):void{
			var isRepeat:Boolean = (isRepeating && _repeating > 0);
			var txt:String = (obj is XML || obj is XMLList)?obj.toXMLString():String(obj);
			if(!channel || channel == GLOBAL_CHANNEL) channel = DEFAULT_CHANNEL;
			if(priority >= autoStackPriority && stacks<0) stacks = defaultStackDepth;
			var stackArr:Array = stacks>0?getStack(stacks):null;
			
			if( _tracing && !isRepeat && (_tracingChannels.length==0 || _tracingChannels.indexOf(channel)>=0) ){
				_traceCall("["+channel+"] "+(stackArr==null?txt:(txt+"\n @ "+stackArr.join("\n @ "))));
			}
			if(!skipSafe){
				txt = txt.replace(/</gm, "&lt;");
 				//txt = txt.replace(/>/gm, "&gt;");
			}
			if(stackArr != null) {
				var tp:int = priority;
				for each(var sline:String in stackArr) {
					txt += "\n<p"+tp+"> @ "+sline+"</p"+tp+">";
					if(tp>0) tp--;
				}
			}
			if(_channels.indexOf(channel) < 0){
				_channels.push(channel);
			}
			var line:Log = new Log(txt,channel,priority, isRepeating);
			if(isRepeat){
				_lines.pop();
				_lines.push(line);
			}else{
				_repeating = isRepeating?maxRepeats:0;
				_lines.push(line);
				if(maxLines > 0 ){
					var off:int = _lines.length - maxLines;
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
			var reg:RegExp = new RegExp("Function|"+getQualifiedClassName(this)+"|"+getQualifiedClassName(C));
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
			if(b) _commandLineAllowed = true;
			_panels.mainPanel.commandLine = b;
		}
		public function get commandLine ():Boolean{
			return _panels.mainPanel.commandLine;
		}
		public function set commandLineAllowed (b:Boolean):void{
			_commandLineAllowed = b;
			if(!b && commandLine) commandLine = false;
		}
		public function get commandLineAllowed ():Boolean{
			return _commandLineAllowed;
		}
		public function set commandBase (v:Object):void{
			if(v) _cl.base = v;
		}
		public function get commandBase ():Object{
			return _cl.base;
		}
		public function runCommand(line:String):*{
			if(_remoter.isRemote){
				report("Run command at remote: "+line,-2);
				try{
					_remoter.send("runCommand", line);
				}catch(err:Error){
					report("Command could not be sent to client: " + err, 10);
				}
			}else{
				return _cl.run(line);
			}
			return null;
		}
		//
		// LOGGING
		//
		public function ch(channel:*, newLine:*, priority:Number = 2, isRepeating:Boolean = false):void{
			var chn:String;
			if(channel is String) chn = channel as String;
			else if(channel) chn = Utils.shortClassName(channel);
			else chn = DEFAULT_CHANNEL;
			addLine(newLine,priority,chn, isRepeating);
		}
		public function add(newLine:*, priority:Number = 2, isRepeating:Boolean = false):void{
			addLine(newLine,priority, DEFAULT_CHANNEL, isRepeating);
		}
		public function stack(newLine:*, depth:int = -1, priority:Number = 5, ch:String = null):void{
			addLine(newLine,priority, ch, false, false, depth>=0?depth:defaultStackDepth);
		}
		public function log(...args):void{
			addLine(joinArgs(args), LOG_LEVEL);
		}
		public function info(...args):void{
			addLine(joinArgs(args), INFO_LEVEL);
		}
		public function debug(...args):void{
			addLine(joinArgs(args), DEBUG_LEVEL);
		}
		public function warn(...args):void{
			addLine(joinArgs(args), WARN_LEVEL);
		}
		public function error(...args):void{
			addLine(joinArgs(args), ERROR_LEVEL);
		}
		public function fatal(...args):void{
			addLine(joinArgs(args), FATAL_LEVEL);
		}
		public function logch(channel:*, ...args):void{
			ch(channel, joinArgs(args), LOG_LEVEL);
		}
		public function infoch(channel:*, ...args):void{
			ch(channel, joinArgs(args), INFO_LEVEL);
		}
		public function debugch(channel:*, ...args):void{
			ch(channel, joinArgs(args), DEBUG_LEVEL);
		}
		public function warnch(channel:*, ...args):void{
			ch(channel, joinArgs(args), WARN_LEVEL);
		}
		public function errorch(channel:*, ...args):void{
			ch(channel, joinArgs(args), ERROR_LEVEL);
		}
		public function fatalch(channel:*, ...args):void{
			ch(channel, joinArgs(args), FATAL_LEVEL);
		}
		private function joinArgs(args:Array):String{
			for(var X:String in args){
				if(args[X] is XML || args[X] is XMLList) args[X] = args[X].toXMLString();
			}
			return args.join(" ");
		}
		//
		//
		//
		public function set filterText(str:String):void{
			_panels.mainPanel.filterText = str;
		}
		public function get filterText():String{
			return _panels.mainPanel.filterText;
		}
		public function set filterRegExp(exp:RegExp):void{
			_panels.mainPanel.filterRegExp = exp;
		}
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
				_channels.push(GLOBAL_CHANNEL, DEFAULT_CHANNEL);
			}
			if(!_paused) _panels.mainPanel.updateToBottom();
			_panels.updateMenu();
		}
		//
		public function get css():StyleSheet{return _css;}
		public function get style():ConsoleStyle{return _style;}
		public function get panels():PanelsManager{return _panels;}
		public function get cl():CommandLine{return _cl;}
		public function get ud():UserData{return _ud;}
		public function get om():ObjectsMonitor{return _om;}
		public function get graphing():Graphing{return _graphing;}
		//
		public function getLogsAsObjects():Array{
			var a:Array = [];
			var line:Log = _lines.first;
			while(line){
				a.push(line.toObject());
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