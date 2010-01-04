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
	import com.luaye.console.core.Log;
	import com.luaye.console.core.Logs;
	import com.luaye.console.core.MemoryMonitor;
	import com.luaye.console.core.Remoting;
	import com.luaye.console.utils.Utils;
	import com.luaye.console.view.ChannelsPanel;
	import com.luaye.console.view.FPSPanel;
	import com.luaye.console.view.MainPanel;
	import com.luaye.console.view.PanelsManager;
	import com.luaye.console.view.RollerPanel;
	import com.luaye.console.view.Style;

	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.geom.Rectangle;
	import flash.net.LocalConnection;
	import flash.system.System;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getTimer;

	public class Console extends Sprite {

		public static const VERSION:Number = 2.31;
		public static const VERSION_STAGE:String = "";
		//
		public static const NAME:String = "Console";
		public static const PANEL_MAIN:String = "mainPanel";
		public static const PANEL_CHANNELS:String = "channelsPanel";
		public static const PANEL_FPS:String = "fpsPanel";
		public static const PANEL_MEMORY:String = "memoryPanel";
		public static const PANEL_ROLLER:String = "rollerPanel";
		//
		// You can change this if you don't want to use default channel
		// Other remotes with different remoting channel won't be able to connect your flash.
		// Start with _ to work in any domain + platform (air/swf - local / network)
		// Change BEFORE starting remote / remoting
		public static var REMOTING_CONN_NAME:String = "_Console";
		//
		public static const CONSOLE_CHANNEL:String = "C";
		public static const FILTERED_CHANNEL:String = "~";
		public static const GLOBAL_CHANNEL:String = " * ";
		public static const DEFAULT_CHANNEL:String = "-";
		//
		public static const LOG_LEVEL:uint = 2;
		public static const INFO_LEVEL:uint = 4;
		public static const DEBUG_LEVEL:uint = 6;
		public static const WARN_LEVEL:uint = 8;
		public static const ERROR_LEVEL:uint = 10;
		public static const FATAL_LEVEL:uint = 100;
		//
		public static const FPS_MAX_LAG_FRAMES:uint = 25;
		public static const MAPPING_SPLITTER:String = "|";
		//
		public var style:Style;
		public var panels:PanelsManager;
		public var cl:CommandLine;
		private var mm:MemoryMonitor;
		private var remoter:Remoting;
		//
		public var quiet:Boolean;
		public var maxLines:int = 1000;
		public var prefixChannelNames:Boolean = true;
		public var alwaysOnTop:Boolean = true;
		public var moveTopAttempts:int = 50;
		public var maxRepeats:Number = 75;
		public var remoteDelay:int = 20;
		public var tracingPriority:int = 0;
		public var rulerHidesMouse:Boolean = true;
		//
		private var _isPaused:Boolean;
		private var _enabled:Boolean = true;
		private var _password:String;
		private var _passwordIndex:int;
		private var _remotingPassword:String = "";
		private var _tracing:Boolean = false;
		private var _filterText:String;
		private var _keyBinds:Object = {};
		private var _mspf:Number;
		private var _previousTime:Number;
		private var _traceCall:Function = trace;
		private var _rollerCaptureKey:String;
		private var _needToMoveTop:Boolean;
		private var _commandLineAllowed:Boolean = true;
		private var _strongRef:Boolean;
		
		private var _channels:Array = [GLOBAL_CHANNEL, DEFAULT_CHANNEL];
		private var _viewingChannels:Array = [GLOBAL_CHANNEL];
		private var _tracingChannels:Array = [];
		private var _isRepeating:Boolean;
		private var _priority:int;
		private var _repeated:int;
		private var _lines:Logs;
		private var _lineAdded:Boolean;
		
		/**
		 * Console is the main class. However please use C for singleton Console adapter.
		 * Using Console through C will also make sure you can remove console in a later date
		 * by simply removing C.start() or C.startOnStage()
		 * 
		 * @see com.luaye.console.C
		 * @see http://code.google.com/p/flash-console/
		 */
		public function Console(pass:String = "", uiset:int = 1) {
			name = NAME;
			if(pass == null) pass = "";
			_password = pass;
			_remotingPassword = pass;
			tabChildren = false; // Tabbing is not supported
			//
			_lines = new Logs();
			cl = new CommandLine(this);
			remoter = new Remoting(this, remoteLogSend);
			mm = new MemoryMonitor();
			style = new Style(uiset);
			panels = new PanelsManager(this, new MainPanel(this, _lines, _channels));
			//
			report("<b>Console v"+VERSION+(VERSION_STAGE?(" "+VERSION_STAGE):"")+", Happy bug fixing!</b>", -2);
			addEventListener(Event.ADDED_TO_STAGE, stageAddedHandle, false, 0, true);
			addEventListener(Event.REMOVED_FROM_STAGE, stageRemovedHandle, false, 0, true);
			if(_password) visible = false;
		}
		private function stageAddedHandle(e:Event=null):void{
			if(cl.base == null){
				cl.base = parent;
			}
			addEventListener(Event.ENTER_FRAME, _onEnterFrame, false, 0, true);
			parent.addEventListener(Event.ADDED, onParentDisplayAdded, false, 0, true);
			stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave, false, 0, true);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyUpHandler, false, 0, true);
		}
		private function stageRemovedHandle(e:Event=null):void{
			removeEventListener(Event.ENTER_FRAME, _onEnterFrame);
			parent.removeEventListener(Event.ADDED, onParentDisplayAdded);
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyUpHandler);
		}
		private function onParentDisplayAdded(e:Event):void{
			if((e.target as DisplayObject).parent == parent) _needToMoveTop = true;
		}
		private function onStageMouseLeave(e:Event):void{
			panels.tooltip(null);
		}
		private function keyUpHandler(e:KeyboardEvent):void{
			if(!_enabled) return;
			if(e.keyLocation == 0){
				var char:String = String.fromCharCode(e.charCode);
				if(char == _password.substring(_passwordIndex,_passwordIndex+1)){
					_passwordIndex++;
					if(_passwordIndex >= _password.length){
						_passwordIndex = 0;
						if(visible && !panels.mainPanel.visible){
							panels.mainPanel.visible = true;
						}else{
							visible = !visible;
						}
					}
				}else{
					_passwordIndex = 0;
					var key:String = char.toLowerCase()+(e.ctrlKey?"0":"1")+(e.altKey?"0":"1")+(e.shiftKey?"0":"1");
					if(_keyBinds[key]){
						var bind:Array = _keyBinds[key];
						bind[0].apply(this, bind[1]);
					}
				}
			}
		}
		public function destroy():void{
			enabled = false;
			remoter.close();
			removeEventListener(Event.ENTER_FRAME, _onEnterFrame);
			cl.destory();
			if(stage){
				stageRemovedHandle();
			}
		}
		public static function get remoteIsRunning():Boolean{
			var sCon:LocalConnection = new LocalConnection();
			try{
				sCon.allowInsecureDomain("*");
				sCon.connect(REMOTING_CONN_NAME+Remoting.REMOTE_PREFIX);
			}catch(error:Error){
				return true;
			}
			sCon.close();
			return false;
		}
		public function addGraph(n:String, obj:Object, prop:String, col:Number = -1, key:String = null, rect:Rectangle = null, inverse:Boolean = false):void{
			if(obj == null) {
				report("ERROR: Graph ["+n+"] received a null object to graph property ["+prop+"].", 10);
				return;
			}
			panels.addGraph(n,obj,prop,col,key,rect,inverse);
		}
		public function fixGraphRange(n:String, min:Number = NaN, max:Number = NaN):void{
			panels.fixGraphRange(n, min, max);
		}
		public function removeGraph(n:String, obj:Object = null, prop:String = null):void{
			panels.removeGraph(n, obj, prop);
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
			bindByKey(getKey(char, ctrl, alt, shift), fun, args);
			if(!quiet){
				report((fun is Function?"Bined":"Unbined")+" key <b>"+ char.toUpperCase() +"</b>"+ (ctrl?"+ctrl":"")+(alt?"+alt":"")+(shift?"+shift":"")+".",-1);
			}
		}
		private function bindByKey(key:String, fun:Function ,args:Array = null):void{
			if(fun==null){
				delete _keyBinds[key];
			}else{
				_keyBinds[key] = [fun,args];
			}
		}
		private function getKey(char:String, ctrl:Boolean = false, alt:Boolean = false, shift:Boolean = false):String{
			return char.toLowerCase()+(ctrl?"0":"1")+(alt?"0":"1")+(shift?"0":"1");
		}
		public function setPanelArea(panelname:String, rect:Rectangle):void{
			panels.setPanelArea(panelname, rect);
		}
		//
		// Panel settings
		// basically passing through to panels manager to save lines
		//
		public function get channelsPanel():Boolean{
			return panels.channelsPanel;
		}
		public function set channelsPanel(b:Boolean):void{
			panels.channelsPanel = b;
			if(b){
				var chPanel:ChannelsPanel = panels.getPanel(PANEL_CHANNELS) as ChannelsPanel;
				chPanel.start(_channels);
			}
			panels.updateMenu();
		}
		//
		public function get displayRoller():Boolean{
			return panels.displayRoller;
		}
		public function set displayRoller(b:Boolean):void{
			panels.displayRoller = b;
		}
		public function setRollerCaptureKey(char:String, ctrl:Boolean = false, alt:Boolean = false, shift:Boolean = false):void{
			if(_rollerCaptureKey){
				bindByKey(_rollerCaptureKey, null);
			}
			if(char && char.length==1){
				_rollerCaptureKey = getKey(char, ctrl, alt, shift);
				bindByKey(_rollerCaptureKey, onRollerCaptureKey);
			}
		}
		private function onRollerCaptureKey():void{
			if(displayRoller){
				report("Display Roller Capture:"+RollerPanel(panels.getPanel(PANEL_ROLLER)).capture(), -1);
			}
		}
		//
		public function get fpsMonitor():Boolean{
			return panels.fpsMonitor;
		}
		public function set fpsMonitor(b:Boolean):void{
			panels.fpsMonitor = b;
		}
		//
		public function get memoryMonitor():Boolean{
			return panels.memoryMonitor;
		}
		public function set memoryMonitor(b:Boolean):void{
			panels.memoryMonitor = b;
		}
		//
		public function watch(o:Object,n:String = null):String{
			var className:String = getQualifiedClassName(o);
			if(!n) n = className+"@"+getTimer();
			var nn:String = mm.watch(o,n);
			if(!quiet)
				report("Watching <b>"+className+"</b> as <p5>"+ nn +"</p5>.",-1);
			return nn;
		}
		public function unwatch(n:String):void{
			mm.unwatch(n);
		}
		public function gc():void{
			if(remote){
				try{
					report("Sending garbage collection request to client",-1);
					remoter.send("gc");
				}catch(e:Error){
					report(e,10);
				}
			}else{
				var ok:Boolean = mm.gc();
				var str:String = "Manual garbage collection "+(ok?"successful.":"FAILED. You need debugger version of flash player.");
				report(str,(ok?-1:10));
			}
		}
		public function store(n:String, obj:Object, strong:Boolean = false):void{
			cl.store(n, obj, strong);
		}
		public function map(base:DisplayObjectContainer, maxstep:uint = 0):void{
			cl.map(base, maxstep);
		}
		public function get strongRef():Boolean{
			return _strongRef;
		}
		public function set strongRef(b:Boolean):void{
			_strongRef= b;
		}
		public function inspect(obj:Object, detail:Boolean = true):void{
			cl.inspect(obj,detail);
		}
		public function set enabled(newB:Boolean):void{
			if(_enabled == newB) return;
			if(_enabled && !newB){
				report("Disabled",10);
			}
			var pre:Boolean = _enabled;
			_enabled = newB;
			if(!pre && newB){
				report("Enabled",-1);
			}
		}
		public function get enabled():Boolean{
			return _enabled;
		}
		public function get paused():Boolean{
			return _isPaused;
		}
		public function set paused(newV:Boolean):void{
			if(_isPaused == newV) return;
			if(newV){
				report("Paused", 10);
			}else{
				report("Resumed", -1);
			}
			_isPaused = newV;
			panels.mainPanel.setPaused(newV);
		}
		//
		//
		//
		override public function get width():Number{
			return panels.mainPanel.width;
		}
		override public function set width(newW:Number):void{
			panels.mainPanel.width = newW;
		}
		override public function set height(newW:Number):void{
			panels.mainPanel.height = newW;
		}
		override public function get height():Number{
			return panels.mainPanel.height;
		}
		override public function get x():Number{
			return panels.mainPanel.x;
		}
		override public function set x(newW:Number):void{
			panels.mainPanel.x = newW;
		}
		override public function set y(newW:Number):void{
			panels.mainPanel.y = newW;
		}
		override public function get y():Number{
			return panels.mainPanel.y;
		}
		//
		//
		//
		private function _onEnterFrame(e:Event):void{
			if(!_enabled){
				return;
			}
			var time:int = getTimer();
			_mspf = time-_previousTime;
			_previousTime = time;
			
			if(_needToMoveTop && alwaysOnTop && moveTopAttempts>0  && parent){
				_needToMoveTop = false;
				moveTopAttempts--;
				parent.setChildIndex(this,(parent.numChildren-1));
				if(!quiet){
					report("Moved console on top (alwaysOnTop enabled), "+moveTopAttempts+" attempts left.",-1);
				}
			}
			if( _isRepeating ){
				_repeated++;
				if(_repeated > maxRepeats && maxRepeats >= 0){
					_isRepeating = false;
				}
			}
			if(!_isPaused){
				var arr:Array = mm.update();
				if(arr.length>0){
					report("<b>GARBAGE COLLECTED "+arr.length+" item(s): </b>"+arr.join(", "),-2);
				}
			}
			if(visible){
				panels.mainPanel.update(!_isPaused && _lineAdded);
				if(_lineAdded) {
					var chPanel:ChannelsPanel = panels.getPanel(PANEL_CHANNELS) as ChannelsPanel;
					if(chPanel){
						chPanel.update();
					}
					_lineAdded = false;
				}
			}
			if(remoter.remoting){
				remoter.update(_mspf, stage?stage.frameRate:0);
			}
		}
		public function get fps():Number{
			return 1000/_mspf;
		}
		public function get mspf():Number{
			return _mspf;
		}
		public function get currentMemory():uint {
			return remoter.isRemote?remoter.remoteMem:System.totalMemory;
		}
		//
		// REMOTING
		//
		public function get remoting():Boolean{
			return remoter.remoting;
		}
		public function set remoting(newV:Boolean):void{
			remoter.remoting = newV;
		}
		public function get remote():Boolean{
			return remoter.isRemote;
		}
		public function set remote(newV:Boolean):void{
			remoter.isRemote = newV;
			panels.updateMenu();
		}
		public function sendLogin(pass:String):void{
			remoter.login(pass);
		}
		public function checkLogin(pass:String):Boolean{
			return (!_remotingPassword || _remotingPassword == pass);
		}
		public function set remotingPassword(str:String):void{
			_remotingPassword = str;
			remoter.login(str);
		}
		//
		// this is sent from client for remote...
		// obj[0] = array of log lines (text, priority, channel, repeating, safeHTML)
		// obj[1] = array of 'milliseconds per frame' since previous logsend - for FPS display
		// obj[2] = client's current memory usage
		// obj[3] = client's command line scope - string
		private function remoteLogSend(obj:Array):void{
			if(!remoter.isRemote || !obj) return;
			var lines:Array = obj[0];
			for each( var line:Object in lines){
				if(line){
					addLine(line.text,line.p,line.c,line.r,line.s);
				}
			}
			var remoteMSPFs:Array = obj[1];
			if(remoteMSPFs){
				var fpsp:FPSPanel = panels.getPanel(PANEL_FPS) as FPSPanel;
				if(fpsp){
					// the first value is stage.FrameRate
					var highest:Number = remoteMSPFs[0];
					fpsp.highest = highest;
					fpsp.averaging = highest;
					var len:int = remoteMSPFs.length;
					for(var i:int = 1; i<len;i++){
						var fps:Number = 1000/remoteMSPFs[i];
						if(fps > highest) fps = highest;
						fpsp.addCurrent(fps);
					}
					fpsp.updateKeyText();
					fpsp.drawGraph();
				}
			}
			remoter.remoteMem = obj[2];
			if(obj[3]){ 
				// older clients don't send CL scope
				panels.mainPanel.updateCLScope(obj[3]);
			}
		}
		//
		//
		//
		public function set viewingChannel(str:String):void{
			if(str) viewingChannels = [str];
			else viewingChannels = [GLOBAL_CHANNEL];
		}
		public function get viewingChannel():String{
			return _viewingChannels.join(",");
		}
		public function get viewingChannels():Array{
			return _viewingChannels.concat();
		}
		public function set viewingChannels(a:Array):void{
			_viewingChannels.splice(0);
			if(a && a.length) _viewingChannels.push.apply(this, a);
			else _viewingChannels.push(GLOBAL_CHANNEL);
			panels.mainPanel.updateToBottom();
			panels.updateMenu();
		}
		public function set tracingChannels(newVar:Array):void{
			_tracingChannels = newVar?newVar.concat():[];
		}
		public function get tracingChannels():Array{
			return _tracingChannels;
		}
		//
		public function get tracing():Boolean{
			return _tracing;
		}
		public function set tracing(b:Boolean):void{
			_tracing = b;
			panels.mainPanel.updateMenu();
		}
		public function set traceCall (f:Function):void{
			if(f==null){
				report("C.traceCall function setter can not be null.", 10);
			}else{
				_traceCall = f;
			}
		}
		public function get traceCall ():Function{
			return _traceCall;
		}
		public function report(obj:*,priority:Number = 0, skipSafe:Boolean = true):void{
			addLine(obj, priority, CONSOLE_CHANNEL, false, skipSafe);
		}
		private function addLine(obj:*,priority:Number = 0,channel:String = null,isRepeating:Boolean = false, skipSafe:Boolean = false):void{
			if(!_enabled){
				return;
			}
			var isRepeat:Boolean = (isRepeating && _isRepeating);
			var txt:String = (obj is XML || obj is XMLList)?obj.toXMLString():String(obj);
			if(!channel || channel == GLOBAL_CHANNEL){
				channel = DEFAULT_CHANNEL;
			}
			if( _tracing && !isRepeat && (_tracingChannels.length==0 || _tracingChannels.indexOf(channel)>=0) ){
				if(tracingPriority <= priority || tracingPriority <= 0){
					_traceCall("["+channel+"] "+txt);
				}
			}
			if(!skipSafe){
				txt = txt.replace(/</gim, "&lt;");
 				txt = txt.replace(/>/gim, "&gt;");
			}
			if(_channels.indexOf(channel) < 0){
				_channels.push(channel);
			}
			var line:Log = new Log(txt,channel,priority, isRepeating, skipSafe);
			if(isRepeat){
				_lines.pop();
				_lines.push(line);
			}else{
				_repeated = 0;
				_lines.push(line);
				if(maxLines > 0 ){
					var off:int = _lines.length - maxLines;
					if(off > 0){
						_lines.shift(off);
					}
				}
			}
			_lineAdded = true;
			_isRepeating = isRepeating;
			
			if(remoter.remoting){
				remoter.addLineQueue(line);
			}
		}
		public function lineShouldShow(line:Log):Boolean{
			return (
				(
					_viewingChannels.indexOf(Console.GLOBAL_CHANNEL)>=0
			 		|| _viewingChannels.indexOf(line.c)>=0 
			 		|| (_filterText && _viewingChannels.indexOf(Console.FILTERED_CHANNEL)>=0 && line.text.toLowerCase().indexOf(_filterText.toLowerCase())>=0 )
			 	) 
			 	&& ( _priority <= 0 || line.p >= _priority)
			);
		}
		public function set priority (i:int):void{
			_priority = i;
			panels.mainPanel.updateToBottom();
			panels.updateMenu();
		}
		public function get priority ():int{
			return _priority;
		}
		//
		// COMMAND LINE
		//
		public function set commandLine (newB:Boolean):void{
			if(newB && !_commandLineAllowed){
				panels.updateMenu();
				report("CommandLine is disabled. Set commandLineAllowed from source code to allow.");
			}else{
				panels.mainPanel.commandLine = newB;
			}
		}
		public function get commandLine ():Boolean{
			return panels.mainPanel.commandLine;
		}
		public function set commandLineAllowed (v:Boolean):void{
			_commandLineAllowed = v;
			if(v==0 && commandLine){
				commandLine = false;
			}
		}
		public function get commandLineAllowed ():Boolean{
			return _commandLineAllowed;
		}
		public function set commandBase (v:Object):void{
			if(v) cl.base = v;
		}
		public function get commandBase ():Object{
			return cl.base;
		}
		public function runCommand(line:String):*{
			if(remoter.isRemote){
				report("Run command at remote: "+line,-2);
				try{
					remoter.send("runCommand", line);
				}catch(err:Error){
					report("Command could not be sent to client: " + err, 10);
				}
			}else{
				return cl.run(line);
			}
			return null;
		}
		//
		// LOGGING
		//
		public function ch(channel:*, newLine:*, priority:Number = 2, isRepeating:Boolean = false):void{
			var chn:String;
			if(channel is String){
				chn = channel as String;
			}else if(channel){
				chn = Utils.shortClassName(channel);
			}else{
				chn = DEFAULT_CHANNEL;
			}
			addLine(newLine,priority,chn, isRepeating);
		}
		public function add(newLine:*, priority:Number = 2, isRepeating:Boolean = false):void{
			addLine(newLine,priority, DEFAULT_CHANNEL, isRepeating);
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
		public function joinArgs(args:Array):String{
			for(var X:String in args){
				if(args[X] is XML || args[X] is XMLList){
					args[X] = args[X].toXMLString();
				}
			}
			return args.join(" ");
		}
		//
		public function set filterText(str:String):void{
			_filterText = str;
			if(str){
				clear(FILTERED_CHANNEL);
				_channels.splice(1,0,FILTERED_CHANNEL);
				addLine("Filtering ["+str+"]", 10,FILTERED_CHANNEL);
				viewingChannels = [FILTERED_CHANNEL];
			}else if(viewingChannel == FILTERED_CHANNEL){
				viewingChannels = [GLOBAL_CHANNEL];
			}
		}
		public function get filterText():String{
			return _filterText;
		}
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
			panels.mainPanel.updateToBottom();
			panels.updateMenu();
		}
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
			//return _lines.join(splitter);
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