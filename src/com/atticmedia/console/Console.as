/*
* 
* Copyright (c) 2008 Atticmedia
* 
* @author 		Lu Aye Oo
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
*/
package com.atticmedia.console {
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.StatusEvent;
	import flash.events.TextEvent;
	import flash.geom.Rectangle;
	import flash.net.LocalConnection;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	import flash.utils.getQualifiedClassName;
	
	import com.atticmedia.console.core.*;	

	public class Console extends Sprite {

		public static const NAME:String = "Console";
		public static const VERSION:Number = 1.03;

		public static const REMOTE_CONN_NAME:String = "ConsoleRemote";
		public static const REMOTER_CONN_NAME:String = "ConsoleRemoter";
		
		public static const CONSOLE_CHANNEL:String = "C";
		public static const FILTERED_CHANNEL:String = "Filtered";
		public static const GLOBAL_CHANNEL:String = "global";
		public static const MINIMUM_HEIGHT:int = 16;
		public static const MINIMUM_WIDTH:int = 20;
		
		public var quiet:Boolean;
		public var tracing:Boolean;
		public var maxLines:int = 500;
		public var deleteLines:int = 1;
		public var prefixChannelNames:Boolean = true;
		public var alwaysOnTop:Boolean = true;
		public var maxRepeats:Number = 100;
		public var memoryMonitor:int = 0;
		public var remoteDelay:int = 25;
		public var moveable:Boolean = true;
		
		private var _traceField:TextField;
		private var _menuField:TextField;
		private var _commandField:TextField;
		private var _commandBackground:Shape;
		private var _background:Shape;
		private var _scaler:Sprite;
		private var _ruler:Shape;
		private var _bottomLine:Shape;
		
		private var _enabled:Boolean;
		private var _password:String;
		private var _passwordIndex:int;
		private var _priority:int;
		private var _isPaused:Boolean;
		private var _menuMode:int;
		private var _isMinimised:Boolean;
		private var _isScaling:Boolean;
		private var _keyBinds:Object;
		
		private var _isRemoting:Boolean;
		private var _isRemote:Boolean;
		private var _sharedConnection:LocalConnection;
		private var _remoteDelayed:int;
		private var _remoteLinesQueue:Array;
		private var _remoteFPS:int;
		private var _remoteMem:int;
		
		private var _menuText:String;
		private var _tracingChannels:Array;
		private var _lines:Array;
		private var _linesChanged:Boolean;
		private var _channels:Array;
		private var _isRepeating:Boolean;
		private var _repeated:int;
		private var _viewingChannel:Array;
		private var _currentChannel:String;
		
		private var _commandsHistory:Array;
		private var _commandsInd:int;
		private var _mm:MemoryMonitor;
		private var _fps:FpsMonitor;
		private var _CL:CommandLine;
		private var _ui:UserInterface;
		private var _timers:Timers;
		private var _channelsPanel:ChannelsPanel;
		private var _channelsPinned:Boolean;
		private var _shift:Boolean;
		
		public function Console(pass:String = "") {
			name = NAME;
			_password = pass;
			_keyBinds = new Object();
			//
			_background = new Shape();
			_background.name = "background";
			_background.graphics.beginFill(0xFFFFFF);
			_background.graphics.drawRoundRect(0, 0, 100, 100,10,10);
			var grid:Rectangle = new Rectangle(10, 10, 80, 80);
			_background.scale9Grid = grid ;
			addChild(_background);
			//
			var corner:Shape = new Shape();
			corner.name = "rulerCorner";
			corner.graphics.lineStyle(1, 0xFF0000);
			corner.graphics.moveTo(MINIMUM_WIDTH-1, 0);
			corner.graphics.lineTo(MINIMUM_WIDTH-1, MINIMUM_HEIGHT-1);
			corner.graphics.moveTo(0, MINIMUM_HEIGHT-1);
			corner.graphics.lineTo(MINIMUM_WIDTH-1, MINIMUM_HEIGHT-1);
			addChild(corner);
			//
			var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = 11;
			_traceField = new TextField();
			_traceField.name = "traceField";
			_traceField.wordWrap = true;
			_traceField.background  = false;
			_traceField.multiline = true;
			_traceField.defaultTextFormat = format;
			addChild(_traceField);
			//
			_menuField = new TextField();
			_menuField.name = "menuField";
			_menuField.selectable = false;
			_menuField.height = 18;
			_menuField.addEventListener(MouseEvent.MOUSE_DOWN, onMenuMouseDown, false, 0, true);
			_menuField.addEventListener(MouseEvent.MOUSE_UP,onMenuMouseUp, false, 0, true);
			_menuField.y = -2;
			_menuField.selectable = false;
			addChild(_menuField);
			//
			_commandBackground = new Shape();
			_commandBackground.name = "commandBackground";
			_commandBackground.graphics.beginFill(0xFFFFFF);
			_commandBackground.graphics.drawRoundRect(0, 0, 100, 18,8,8);
			grid = new Rectangle(10, 8, 80, 8);
			_commandBackground.scale9Grid = grid ;
			_commandBackground.visible = false;
			addChild(_commandBackground);
			//
			_commandField = new TextField();
			_commandField.name = "commandField";
			_commandField.type  = TextFieldType.INPUT;
			_commandField.height = 18;
			_commandField.addEventListener(KeyboardEvent.KEY_DOWN, commandKeyDown, false, 0, true);
			_commandField.addEventListener(KeyboardEvent.KEY_UP, commandKeyUp, false, 0, true);
			_commandField.visible = false;
			addChild(_commandField);
			
			addEventListener(TextEvent.LINK, linkHandler, false, 0, true);
			
			//
			_ruler = new Shape();
			_ruler.name = "ruler";
			_ruler.graphics.lineStyle(1, 0xFF0000);
			_ruler.graphics.moveTo(MINIMUM_WIDTH-1, -5);
			_ruler.graphics.lineTo(MINIMUM_WIDTH-1, 37);
			_ruler.graphics.moveTo(-5, MINIMUM_HEIGHT-1);
			_ruler.graphics.lineTo(45, MINIMUM_HEIGHT-1);
			_ruler.visible = false;
			addChild(_ruler);
			
			//
			_scaler = new Sprite();
			_scaler.name = "scaler";
			_scaler.graphics.beginFill(0x000000, 0.6);
            _scaler.graphics.lineTo(-10, 0);
            _scaler.graphics.lineTo(0, -10);
            _scaler.graphics.endFill();
			_scaler.buttonMode = true;
			_scaler.doubleClickEnabled = true;
			_scaler.addEventListener(MouseEvent.MOUSE_DOWN,onScalerMouseDown, false, 0, true);
			_scaler.addEventListener(MouseEvent.MOUSE_UP,onScalerMouseUp, false, 0, true);
			_scaler.addEventListener(MouseEvent.DOUBLE_CLICK, onScalerDoubleClick, false, 0, true);
            addChild(_scaler);
			
			//
			_bottomLine = new Shape();
			_bottomLine.name = "blinkLine";
			addChild(_bottomLine);
			//
			_ui = new UserInterface(_background, _menuField, _traceField, _commandBackground, _commandField);
			_fps = new FpsMonitor();
			_mm = new MemoryMonitor();
			_timers = new Timers(addLogLine);
			_lines = new Array();
			_linesChanged = false;
			_channels = new Array(GLOBAL_CHANNEL);
			_currentChannel = "traces";
			_viewingChannel = [GLOBAL_CHANNEL];
			_isRepeating = false;
			_isPaused = false;
			_enabled = true;
			_menuMode = 1;
			
			_commandsHistory = new Array();
			_commandsInd = 0;
			_CL = new CommandLine(null, addLogLine);
			_CL.store("C",this);
			_CL.reserved.push("C");
			_CL.addEventListener(CommandLine.SEARCH_REQUEST, onCommandSearch, false, 0, true);
			//
			addEventListener(Event.ENTER_FRAME, _onEnterFrame, false, 0, true);
			//
			if(_password != ""){
				if(stage){
					stageAddedHandle();
				}
				visible = false;
			}
			addEventListener(Event.ADDED_TO_STAGE, stageAddedHandle, false, 0, true);
			addEventListener(Event.REMOVED_FROM_STAGE, stageRemovedHandle, false, 0, true);
			addLine("<b>v"+VERSION+", Happy bug fixing!</b>",-2,CONSOLE_CHANNEL);
			//
			updateMenu();
			width = 520;
			height = 16;
		}
		private function stageAddedHandle(e:Event=null):void{
			if(_CL.base == null && root){
				_CL.base = root;
			}
			stage.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler, false, 0, true);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler, false, 0, true);
		}
		private function stageRemovedHandle(e:Event=null):void{
			stage.removeEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
		}
		
		private function keyDownHandler(e:KeyboardEvent):void{
			if(e.keyCode == Keyboard.SHIFT){
				_shift = true;
			}
		}
		private function keyUpHandler(e:KeyboardEvent):void{
			if(e.keyCode == Keyboard.SHIFT){
				_shift = false;
			}
			if(!_enabled) return;
			if(e.keyLocation == 0){
				var char:String = String.fromCharCode(e.charCode);
				if(char == _password.substring(_passwordIndex,_passwordIndex+1)){
					_passwordIndex++;
					if(_passwordIndex >= _password.length){
						toogleVisible();
						_passwordIndex = 0;
					}
				}else{
					_passwordIndex = 0;
					
					if(stage && stage.focus == _commandField){
						return;
					}
					var key:String = char.toLowerCase()+(e.ctrlKey?"0":"1")+(e.altKey?"0":"1")+(e.shiftKey?"0":"1");
					if(_keyBinds[key]){
						var bind:Array = _keyBinds[key];
						bind[0].apply(this, bind[1]);
					}
				}
			}
		}
		private function toogleVisible():void{
			visible = !visible;
			if(visible && stage){
				stage.focus = _commandField;
			}
		}
		private function linkHandler(e:TextEvent):void{
			stopDrag();
			if(e.text == "resetFPS"){
				if(_fps){
					_fps.reset();
				}
			}else if(e.text == "help"){
				help();
			}else if(e.text == "clear"){
				clear();
			}else if(e.text == "fps"){
				cycleFPS();
			}else if(e.text == "memory"){
				memoryMonitor++;
				if(memoryMonitor>2){
					memoryMonitor = 0;
				}
			}else if(e.text == "scrollUp"){
				_traceField.scrollV -= 3;
			}else if(e.text == "scrollDown"){
				_traceField.scrollV += 3;
			}else if(e.text == "close"){
				visible = false;
			}else if(e.text == "pause"){
				paused = !paused;
			}else if(e.text == "priority"){
				cyclePriorities();
			}else if(e.text == "command"){
				commandLine = !commandLine;
			}else if(e.text == "menu"){
				_menuMode++;
				if(_menuMode>2){
					_menuMode = 0;
				}
			}else if(e.text == "gc"){
				gc();
			}else if(e.text == "trace"){
				tracing = !tracing;
				if(tracing){
					addLine("Tracing turned [<b>On</b>]",-1,CONSOLE_CHANNEL);
				}else{
					addLine("Tracing turned [<b>Off</b>]",-1,CONSOLE_CHANNEL);
				}
			}else if(e.text == "alpha"){
				cycleAlpha();
			}else if(e.text == "channels"){
				showChannelsPanel();
			}else if(e.text == "pinChannels"){
				_channelsPinned = !_channelsPinned;
			}else if(e.text.substring(0,8) == "channel_"){
				var chn:String = e.text.substring(8);
				if(_shift && viewingChannel != GLOBAL_CHANNEL && chn != GLOBAL_CHANNEL){
					var ind:int = _viewingChannel.indexOf(chn);
					if(ind>=0){
						_viewingChannel.splice(ind,1);
						if(_viewingChannel.length == 0){
							_viewingChannel = [GLOBAL_CHANNEL];
						}
					}else{
						_viewingChannel.push(chn);
					}
					viewingChannel = String(_viewingChannel);
				}else{
					viewingChannel = chn;
				}
				if(_channelsPanel && !_channelsPinned){
					showChannelsPanel();
				}
			}else if(e.text.substring(0,5) == "clip_"){
				var str:String = "/remap "+e.text.substring(5);
				if(_isRemote){
					_sharedConnection.send(REMOTER_CONN_NAME, "runCommand", str);
				}else{
					runCommand(str);
				}
			}
			e.stopPropagation();
		}
		private function showChannelsPanel():void{
			if(_channelsPanel && contains(_channelsPanel)){
				removeChild(_channelsPanel);
				_channelsPanel = null;
			}else{
				_channelsPanel = new ChannelsPanel();
				addChild(_channelsPanel);
				_channelsPanel.x = mouseX;
				_channelsPanel.y = 14;
				_channelsPanel.update(_channels, _viewingChannel, _currentChannel, _channelsPinned);
			}
		}
		private function cycleFPS():void{
			if(_fps.running){
				if(_fps.format == 1){
					_fps.format = 2;
				}else if(_fps.format == 2){
					_fps.format = 3;
				}else if(_fps.format == 3){
					_fps.format = 4;
				}else{
					_fps.pause();
				}
			}else {
				_fps.start();
				_fps.format = 1;
			}
			updateMenu();
		}
		private function cyclePriorities():void{
			if(_priority<10){
				_priority++;
			}else{
				_priority = 0;
			}
			updateMenu();
			refreshPage();
		}
		private function cycleAlpha():void{
			if(_ui.backgroundAlpha<1){
				_ui.backgroundAlpha += 0.15;
			}else{
				_ui.backgroundAlpha = 0;
			}
		}
		private function help():void{
			addLine("___HELP_________________",-1);
			addLine("[ R=Reset FPS, F=FPS, M=Memory, G=Garbage Collect, CL=CommandLine, C=Clear, T=Tracing, P#=Priortiy filter level, A=Background Alpha, P=Pause, H=Help, X=Close ]",10);
			addLine("",0);
			addLine("Use the arrow at bottom right to scale this window.", 1);
			addLine("",0);
			addLine("Use the tabs at the top to switch between channels.",1);
			addLine("'Global' channel show outputs from all channels",1);
			addLine("________________________",-1);
		}
		private function scaleByScaler():void{
			width = _scaler.x;
			height = _scaler.y+(_commandBackground.visible?_commandBackground.height:0);
		}
		private function minimise():void{
			_isMinimised = true;
			_traceField.y = -2;
			_traceField.x = 18;
			_traceField.scrollH = 0;
		}
		private function maximise():void{
			_isMinimised = false;
			_traceField.y = 12;
			_traceField.x = 0;
		}
		private function onMenuMouseDown(e:Event):void{
			if(moveable){
				startDrag();
				_ruler.visible = true;
			}
		}
		private function onMenuMouseUp(e:Event):void{
			stopDrag();
			_ruler.visible = false;
		}
		private function onScalerDoubleClick(e:Event):void{
			height =  height<= (MINIMUM_HEIGHT+(_commandBackground.visible?_commandBackground.height:0)+1) ? 180 : MINIMUM_HEIGHT;
			if(width < 100){
				width = 200;
			}
		}
		private function onScalerMouseDown(e:Event):void{
			_scaler.startDrag(false, new Rectangle(MINIMUM_WIDTH, MINIMUM_HEIGHT, 1280, 1280));
			_isScaling = true;
			_ruler.visible = true;
		}
		private function onScalerMouseUp(e:Event):void{
			stopDrag();
			_isScaling = false;
			_ruler.visible = false;
			scaleByScaler();
			traceRulerData();
		}
		private function traceRulerData():void{
			var w:int = Math.round(_scaler.x-MINIMUM_WIDTH);
			var h:int = Math.round(_scaler.y-MINIMUM_HEIGHT);
			var d:Number = Math.round(Math.sqrt((w*w)+(h*h))*10)/10;
			addLine("Ruler Width:<b>"+w +"</b>, Height:<b>"+h +"</b>, Diagonal:<b>"+d +"</b>.",-1,CONSOLE_CHANNEL);
		}
		//
		//
		private function refreshPage():void{
			var str:String = "";
			for each (var line:LogLineVO in _lines ){
				if((_viewingChannel.indexOf(FILTERED_CHANNEL)>=0 || line.c!=FILTERED_CHANNEL) && ((_CL.searchTerm && line.c != CONSOLE_CHANNEL && line.c != FILTERED_CHANNEL && line.text.toLowerCase().indexOf(_CL.searchTerm.toLowerCase())>=0 )|| (_viewingChannel.indexOf(line.c)>=0 || _viewingChannel.indexOf(GLOBAL_CHANNEL)>=0) && (line.p >= _priority || _priority == 0) )){
					str += makeLine(line)+"<br>";
				}
			}
			var sd:Boolean = _traceField.scrollV == _traceField.maxScrollV;
			_traceField.htmlText = str;
			if(sd){
				_traceField.scrollV = _traceField.maxScrollV;
			}
		}
		private function makeLine(line:LogLineVO):String{
			var colour:String = _ui.getPriorityHex(line.p);
			var str:String = "";
			if(line.p >= 10){
				str += "<b>";
			}
			var txt:String = line.text;
			if(prefixChannelNames && (_viewingChannel.indexOf(GLOBAL_CHANNEL)>=0 || _viewingChannel.length>1) && line.c != _currentChannel){
				txt = "<a href=\"event:channel_"+line.c+"\">["+line.c+"</a>] "+txt;
			}
			str += "<font face=\"Verdana\" size=\"10\" color=\""+colour+"\">"+txt+"</font>";
			if(line.p >= 10){
				str += "</b>";
			}
			return str;
		}
		private function addLogLine(line:LogLineVO, quiet:Boolean = false):void{
			if(!(this.quiet && quiet)){
				addLine(line.text, line.p, line.c==null?CONSOLE_CHANNEL:line.c, line.r, line.s);
			}
		}
		private function addLine(obj:Object,priority:Number = 0,channel:String = "",isRepeating:Boolean = false, skipSafe:Boolean = false):void{
			if(!_enabled){
				return;
			}
			var txt:String = String(obj);
			var tmpText:String = txt;
			if(!skipSafe){
				var unSafeHtml:RegExp = /<(.*?)>/gim;
				var safeHtml:RegExp = /&lt;([\/]{0,1}[ ]*(b|i|br|p|font)([ ]{1}.*?)*)&gt;/gim;
 				txt = txt.replace(unSafeHtml, "&lt;$1&gt;");
 				txt = txt.replace(safeHtml, "<$1>");
			}
			//
			if(channel == ""){
				channel = _currentChannel;
			}
			if(_channels.indexOf(channel) <0 ){
				_channels.push(channel);
			}
			var line:LogLineVO = new LogLineVO(txt,channel,priority, isRepeating, skipSafe);
			_linesChanged = true;
			if(isRepeating && _isRepeating){
				_lines.pop();
				_lines.push(line);
			}else{
				_repeated = 0;
				_lines.push(line);
				if(_lines.length > maxLines && maxLines > 0 ){
					_lines.splice(0,deleteLines);
					//addLine("Maximum lines ["+maxLines+"] reached. Deleted the first ["+_deleteLines+"] lines.",-1,CONSOLE_CHANNEL);
				}
				if( tracing && (_tracingChannels == null || _tracingChannels.indexOf(channel)>=0) ){
					trace("["+channel+"] "+tmpText);
				}
			}
			_isRepeating = isRepeating;
			
			if(_isRemoting){
				_remoteLinesQueue.push(line);
			}
		}
		private function _onEnterFrame(e:Event):void{
			if(!_enabled){
				return;
			}
			if(_isScaling){
				scaleByScaler();
			}
			if(alwaysOnTop && parent &&  parent.getChildIndex(this) < (parent.numChildren-1)){
				parent.setChildIndex(this,(parent.numChildren-1));
				if(!quiet){
					addLine("Attempted to move console on top (alwaysOnTop enabled)",-1,CONSOLE_CHANNEL);
				}
			}
			if( _isRepeating ){
				_repeated++;
				if(_repeated > maxRepeats && maxRepeats >= 0){
					_isRepeating = false;
				}
			}
			if(!_isPaused && visible){
				_fps.update();
				var arr:Array = _mm.update();
				if(arr.length>0){
					addLine("GARBAGE COLLECTED: "+arr.join(", "),10,CONSOLE_CHANNEL);
				}
			}
			if(_isMinimised){
				if(_fps.running){
					_menuField.htmlText = Math.round(_fps.averageFPS) +"]";
				}else{
					_menuField.htmlText = "";
				}
			}else{
				var str:String ="<p align=\"right\">";
				
				// memory
				if(_isRemote){
					if(memoryMonitor > 0){
						str += "<b>"+Math.round(_remoteMem/1024)+"kb </b> ";
					}
				}else{
					if(memoryMonitor == 1){
						str += "<b>"+Math.round(_mm.currentMemory/1024)+"kb </b> ";
					}else if(memoryMonitor > 1){
						str += Math.round(_mm.minMemory/1024)+"kb-";
						str += "<b>"+Math.round(_mm.currentMemory/1024)+"kb</b>-";
						str += ""+Math.round(_mm.maxMemory/1024)+"kb ";
					}
				}
				// FPS
				if(_fps.running){
					str += (_isRemote?_remoteFPS:_fps.get)+" ";
				}
				// channels
				
				if(_channelsPanel){
					_channelsPanel.update(_channels, _viewingChannel, _currentChannel, _channelsPinned);
				}else{
					if(_menuMode != 2){
						for(var ci:int = 0; (ci<_channels.length&& ci<= 5);  ci++){
							var channel:String = _channels[ci];
							var channelTxt:String = (_viewingChannel.indexOf(channel)>=0) ? "<font color=\"#0099CC\"><b>"+channel+"</b></font>" : channel;
							channelTxt = channel==_currentChannel ? "<i>"+channelTxt+"</i>" : channelTxt;
							str += "<a href=\"event:channel_"+channel+"\">["+channelTxt+"]</a> ";
						}
					}
				}
				if(_channelsPanel || _menuMode == 2 || _channels.length > 5){
					str += "<font color=\"#0099CC\"><a href=\"event:channels\"><b>...</b>"+(_channelsPanel?"^":"v")+" </a></font> ";
				}
				
				// MENU
				if(_menuMode != 1){
					str += _menuText;
				}
				str += "<font color=\"#77D077\"><b><a href=\"event:menu\">@</a></b></font>"; 
				if(_traceField.scrollV > 1){
					str += " <a href=\"event:scrollUp\">^</a>";
				}else{
					str += " -";
				}
				if(_traceField.scrollV< _traceField.maxScrollV){
					str += " <a href=\"event:scrollDown\">v</a>";
				}else{
					str += " -";
				}
				str += "</p>";
				_menuField.htmlText = str;
			}
			if(!_isPaused && visible){
				if(_bottomLine.alpha>0){
					_bottomLine.alpha -= 0.2;
				}
				if(_linesChanged){
					_bottomLine.alpha = 1;
					refreshPage();
					_linesChanged = false;
				}
			}
			if(_isRemoting){
				_remoteDelayed++;
				if(_remoteDelayed > remoteDelay){
					updateRemote();
					_remoteDelayed = 0;
				}
			}
		}
		private function updateMenu():void{
			_menuText = "<font color=\"#FF8800\">[";
			if(_fps.running && !_isRemote){
				_menuText += "<a href=\"event:resetFPS\">R</a> ";
			}
			_menuText += "<a href=\"event:fps\">F</a> <a href=\"event:memory\">M</a> <a href=\"event:gc\">G</a> <a href=\"event:command\">CL</a> <a href=\"event:clear\">C</a> <a href=\"event:trace\">T</a> <a href=\"event:priority\">P"+_priority+"</a> <a href=\"event:alpha\">A</a> <a href=\"event:pause\">P</a> <a href=\"event:help\">H</a> <a href=\"event:close\">X</a>] </font>";
		}
		public function destroy():void{
			enabled = false;
			closeSharedConnection();
			removeEventListener(Event.ENTER_FRAME, _onEnterFrame);
			if(stage){
				stage.removeEventListener(KeyboardEvent.KEY_UP, keyDownHandler);
			}
			_mm = null;
			_fps.destory();
			_fps = null;
			_ui = null;
			_lines = null;
			_channels = null;
			_CL.destory();
			_timers = null;
		}
		//
		// WARNING: key binding hard references the function. 
		// This should only be used for development purposes only.
		//
		public function bindKey(char:String, ctrl:Boolean, alt:Boolean, shift:Boolean, fun:Function ,args:Array = null):void{
			if(!char || char.length!=1){
				addLine("Binding key must be a single character. You gave ["+char+"]", 10,CONSOLE_CHANNEL);
				return;
			}
			var key:String = char.toLowerCase()+(ctrl?"0":"1")+(alt?"0":"1")+(shift?"0":"1");
			if(fun is Function){
				_keyBinds[key] = [fun,args];
			}else{
				delete _keyBinds[key];
			}
			if(!quiet){
				addLine((fun is Function?"Bined":"Unbined")+" key <b>"+ char.toUpperCase() +"</b>"+ (ctrl?"+ctrl":"")+(alt?"+alt":"")+(shift?"+shift":"")+".",-1,CONSOLE_CHANNEL);
			}
		}
		public function get timers():Timers{
			return _timers;
		}
		
		public function set enabled(newB:Boolean):void{
			if(_enabled && !newB){
				addLine("Console is now [<b>Disabled</b>]",10,CONSOLE_CHANNEL);
			}
			var pre:Boolean = _enabled;
			_enabled = newB;
			if(!pre && newB){
				addLine("Console is now [<b>Enabled</b>]",-1,CONSOLE_CHANNEL);
			}
		}
		public function get enabled():Boolean{
			return _enabled;
		}
		public function get paused():Boolean{
			return _isPaused;
		}
		public function set paused(newV:Boolean):void{
			if(newV){
				this.addLine("Paused",10,CONSOLE_CHANNEL);
				// refresh page here to show the message before it pauses.
				refreshPage();
			}else{
				this.addLine("Resumed",-1,CONSOLE_CHANNEL);
			}
			_isPaused = newV;
			refreshPage();
		}
		//
		// UI CUSTOMIZATION
		//
		public function setPriorityColour(p:int, col:String):void{
			_ui.setPriorityHex(p, col);
		}
		public function set uiPreset(p:int):void{
			_ui.preset = p;
		}
		public function get uiPreset():int{
			return _ui.preset;
		}
		override public function get width():Number{
			return _background.width;
		}
		override public function set width(newW:Number):void{
			if(newW <= 50){
				_traceField.visible = false;
				newW = newW <MINIMUM_WIDTH ? MINIMUM_WIDTH: newW;
				if(newW == MINIMUM_WIDTH){
					commandLine = false;
				}
			}else{
				_traceField.visible = true;
			}
			_traceField.width = newW;
			_menuField.width = newW;
			_scaler.x = newW;
			_background.width = newW;
			_commandField.width = newW;
			_commandBackground.width = newW;
			
			_bottomLine.graphics.clear();
			_bottomLine.graphics.lineStyle(1, 0xFF0000);
			_bottomLine.graphics.moveTo(5, 0);
			_bottomLine.graphics.lineTo(newW-10, 0);
		}
		override public function set height(newW:Number):void{
			if(_commandBackground.visible){
				newW -= _commandBackground.height;
			}
			if(newW <MINIMUM_HEIGHT){
				newW = MINIMUM_HEIGHT;
			}
			if(!this._isMinimised && newW <= 40){
				this.minimise();
			}
			if(this._isMinimised && newW > 40){
				this.maximise();
			}
			if(this._isMinimised){
				_traceField.height = newW+6;
			}else{
				_traceField.height = newW-12;
			}
			_commandField.y = newW;
			_commandBackground.y = newW;
			_scaler.y = newW;
			_bottomLine.y = newW-1;
			_background.height = newW;
			_traceField.scrollV = _traceField.maxScrollV;
		}
		override public function get height():Number{
			return _background.height+(_commandBackground.visible?_commandBackground.height:0);
		}
		//
		//
		public function get currentChannel():String{
			return _currentChannel;
		}
		public function set currentChannel(newV:String):void{
			_currentChannel = newV ;
		}
		public function get viewingChannel():String{
			return String(_viewingChannel);
		}
		public function set viewingChannel(newV:String):void{
			if(newV.length>0){
				_viewingChannel = newV.split(",");
				refreshPage();
			}
		}
		public function clear(channel:String = null):void{
			if(channel){
				for(var i:int=(_lines.length-1);i>=0;i--){
					if(_lines[i] && _lines[i].c == channel){
						delete _lines[i];
					}
				}
			}else{
				_lines = new Array();
				_channels = new Array(GLOBAL_CHANNEL);
			}
			refreshPage();
		}
		public function set tracingChannels(newVar:String):void{
			if(newVar.length>0){
				_tracingChannels = newVar.split(",");
			}
		}
		public function get tracingChannels():String{
			return String(_tracingChannels);
		}
		public function get menuMode():int{
			return _menuMode;
		}
		public function set menuMode(newV:int):void{
			if(newV >= 0 && newV <= 2){
				_menuMode = newV ;
			}
		}
		//
		// FPS
		//
		public function get fpsMode ():int{
			return _fps.running?_fps.format:0;
		}
		public function set fpsMode (v:int):void{
			if(v == 0 && _fps.running){
				_fps.pause();
			}else if(!_fps.running && v>0){
				_fps.start();
			}
			if(v>0){
				_fps.format = v;
			}
			updateMenu();
		}
		public function fpsReset():void{
			_fps.reset();
		}
		public function get fpsBase():int{
			return _fps.base;
		}
		public function set fpsBase(v:int):void{
			_fps.base = v;
		}
		public function get fps():Number{
			return _fps.current;
		}
		public function get averageFPS ():Number{
			return _fps.averageFPS;
		}
		public function get mspf ():Number{
			return _fps.mspf;
		}
		public function get averageMsPF ():Number{
			return _fps.averageMsPF;
		}
		//
		// Memory Monitor
		//
		public function watch(o:Object,n:String = null):String{
			var nn:String = _mm.watch(o,n);
			if(!quiet){
				addLine("Watching <b>"+o+"</b> as <font color=\"#FF0000\"><b>"+ nn +"</b></font>.",-1,CONSOLE_CHANNEL);
			}
			return nn;
		}
		public function unwatch(n:String):void{
			_mm.unwatch(n);
		}
		public function get minMemory():uint {
			return _mm.minMemory;
		}
		public function get maxMemory():uint {
			return _mm.maxMemory;
		}
		public function get currentMemory():uint {
			return _mm.currentMemory;
		}
		public function gc():void{
			var ok:Boolean = _mm.gc();
			var str:String = "Manual garbage collection "+(ok?"successful.":"FAILED. You need debugger version of flash player.");
			addLine(str,(ok?-1:10),CONSOLE_CHANNEL);
		}
		//
		//
		// COMMAND LINE
		//
		public function set commandLine (newB:Boolean):void{
			if(newB){
				_commandField.visible = true;
				_commandBackground.visible = true;
				if(!quiet){
					addLine("<b>/help</b> for CommandLine help",-1,CONSOLE_CHANNEL);
				}
			}else{
				_commandField.visible = false;
				_commandBackground.visible = false;
			}
		}
		public function get commandLine ():Boolean{
			return _commandField.visible;
		}
		public function runCommand(line:String):void{
			_CL.run(line);
		}
		public function store(n:String, obj:Object, strong:Boolean = false):void{
			var nn:String = _CL.store(n, obj, strong);
			if(!quiet && nn){
				var str:String = obj is Function?"using <b>STRONG</b> reference":("for <b>"+obj+"</b> using WEAK reference");
				addLine("Stored <font color=\"#FF0000\"><b>$"+nn+"</b></font> in commandLine for "+ getQualifiedClassName(str) +".",-1,CONSOLE_CHANNEL);
			}
		}
		public function inspect(obj:Object, detail:Boolean = true):void{
			add("INSPECT: "+ _CL.inspect(obj,detail));
		}
		public function get strongRef():Boolean{
			return _CL.useStrong;
		}
		public function set strongRef(obj:Boolean):void{
			_CL.useStrong = obj;
		}
		public function get commandBase():Object{
			return _CL.base;
		}
		public function set commandBase(obj:Object):void{
			_CL.base = obj;
		}
		private function commandKeyDown(e:KeyboardEvent):void{
			e.stopPropagation();
		}
		private function commandKeyUp(e:KeyboardEvent):void{
			if(!_enabled){
				return;
			}
			if( e.keyCode == 13){
				if(_isRemote){
					addLine("Run command at remote: <b>"+_commandField.text+"</b>",-2,CONSOLE_CHANNEL);
					try{
						_sharedConnection.send(REMOTER_CONN_NAME, "runCommand", _commandField.text);
					}catch(err:Error){
						addLine("Command could not be sent to client: " + err, 10,CONSOLE_CHANNEL);
					}
				}else{
					runCommand(_commandField.text);
				}
				_commandsHistory.unshift(_commandField.text);
				_commandsInd = -1;
				_commandField.text = "";
				// maximum 20 commands history
				if(_commandsHistory.length>20){
					_commandsHistory.splice(20);
				}
			}else if( e.keyCode == 38 ){
				if(_commandsInd<(_commandsHistory.length-1)){
					_commandsInd++;
					_commandField.text = _commandsHistory[_commandsInd];
					_commandField.setSelection(_commandField.text.length, _commandField.text.length);
				}else{
					_commandsInd = _commandsHistory.length;
					_commandField.text = "";
				}
			}else if( e.keyCode == 40){
				if(_commandsInd>0){
					_commandsInd--;
					_commandField.text = _commandsHistory[_commandsInd];
					_commandField.setSelection(_commandField.text.length, _commandField.text.length);
				}else{
					_commandsInd = -1;
					_commandField.text = "";
				}
			}
			e.stopPropagation();
		}
		private function onCommandSearch(e:Event=null):void{
			clear(FILTERED_CHANNEL);
			addLine("Filtering ["+_CL.searchTerm+"]", 10,FILTERED_CHANNEL);
			viewingChannel = FILTERED_CHANNEL;
		}
		//
		// REMOTING
		//
		private function updateRemote():void{
			if(_remoteLinesQueue.length==0) return;
			try{
				_sharedConnection.send(REMOTE_CONN_NAME, "remoteLogSend", [_remoteLinesQueue,averageFPS, currentMemory]);
			}catch(e:Error){
				// don't care
			}
			_remoteLinesQueue = new Array();
		}
		public function get remoting():Boolean{
			return _isRemoting;
		}
		public function set remoting(newV:Boolean):void{
			_isRemoting = newV ;
			_remoteLinesQueue = null;
			if(newV){
				_isRemote = false;
				_remoteDelayed = 0;
				_remoteLinesQueue = new Array();
				startSharedConnection();
				addLine("Remoting started",10,CONSOLE_CHANNEL);
				try{
                	_sharedConnection.connect(REMOTER_CONN_NAME);
           		}catch (error:Error){
					addLine("Could not create client service. You will not be able to control this console with remote.", 10,CONSOLE_CHANNEL);
           		}
			}else{
				closeSharedConnection();
			}
		}
		public function get isRemote():Boolean{
			return _isRemote;
		}
		public function set isRemote(newV:Boolean):void{
			_isRemote = newV ;
			if(newV){
				_isRemoting = false;
				startSharedConnection();
				try{
                	_sharedConnection.connect(REMOTE_CONN_NAME);
					addLine("Remote started",10,CONSOLE_CHANNEL);
           		}catch (error:Error){
					_isRemoting = false;
					addLine("Could not create remote service. You might have a console remote already running.", 10,CONSOLE_CHANNEL);
           		}
			}else{
				closeSharedConnection();
			}
		}
		private function startSharedConnection():void{
			closeSharedConnection();
			_sharedConnection = new LocalConnection();
			_sharedConnection.addEventListener(StatusEvent.STATUS, onSharedStatus);
			_sharedConnection.client = this;
		}
		private function closeSharedConnection():void{
			if(_sharedConnection){
				try{
					_sharedConnection.close();
				}catch(error:Error){
					//
				}
			}
			_sharedConnection = null;
		}
		private function onSharedStatus(e:StatusEvent):void{
			// this will get called quite often if there is no actual remote server running...
		}
		public static function get remoteIsRunning():Boolean{
			var sCon:LocalConnection = new LocalConnection();
			try{
				sCon.connect(REMOTE_CONN_NAME);
			}catch(error:Error){
				return true;
			}
			sCon.close();
			return false;
		}
		public function remoteLogSend(obj:Array):void{
			if(!_isRemote || !obj) return;
			var lines:Array = obj[0];
			for each( var line:Object in lines){
				if(line){
					var p:int = line["p"]?line["p"]:5;
					var channel:String = line["c"]?line["c"]:"";
					var r:Boolean = line["r"];
					var safe:Boolean = line["s"];
					addLine(line["text"],p,channel,r,safe);
				}
			}
			_remoteFPS = obj[1];
			_remoteMem = obj[2];
		}
		//
		// LOGGING
		//
		public function ch(channel:Object, newLine:Object, priority:Number = 2, isRepeating:Boolean = false):void{
			var chn:String;
			if(channel is String){
				chn = String(channel);
			}else if(channel){
				chn = getQualifiedClassName(channel);
				var ind:int = chn.lastIndexOf("::");
				chn = chn.substring(ind>=0?(ind+2):0);
			}else{
				chn = _currentChannel;
			}
			addLine(newLine,priority,chn, isRepeating);
		}
		public function pk(channel:Object, newLine:Object, priority:Number = 2, isRepeating:Boolean = false):void{
			var chn:String = getQualifiedClassName(channel);
			var ind:int = chn.lastIndexOf("::");
			if(ind>=0){
				chn = chn.substring(0,ind);
			}
			addLine(newLine,priority,chn, isRepeating);
		}
		public function add(newLine:Object, priority:Number = 2, isRepeating:Boolean = false):void{
			addLine(newLine,priority, _currentChannel, isRepeating);
		}
	}
}