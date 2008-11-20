package com.atticmedia.console {
	import com.atticmedia.console.core.*;
	import flash.utils.getQualifiedClassName;
	import flash.display.*;
	import flash.events.*;
	import flash.text.*;
	import flash.geom.Rectangle;
	import flash.net.*;
	
	public class Console extends Sprite {

		public static const VERSION:Number = 0.91;
		
		public static const remoteServerName:String = "ConsoleRemoteServer";
		public static const remoteClientName:String = "ConsoleRemoteClient";
		
		public var maxLines:int = 500;
		public var deleteLines:int = 1;
		
		private var _traceField:TextField;
		private var _menuField:TextField;
		private var _commandField:TextField;
		private var _commandBackground:Shape;
		private var _background:Shape;
		private var _scaler:Sprite;
		private var _ruler:Sprite;
		private var _enabled:Boolean;
		
		private var _password:String;
		private var _passwordIndex:int = 0;
		private var _priority:int = 0;
		private var _tracing:Boolean = false;
		private var _tracingChannel:Array = null;
		private var _alwaysOnTop:Boolean = true;
		private var _minHeight:Number = 16;
		private var _minWidth:Number = 20;
		private var _lines:Array;
		private var _lineChanged:Boolean;
		private var _channels:Array;
		private var _isRepeating:Boolean;
		private var _maxRepeats:Number = 100;
		private var _repeated:Number;
		private var _isRemoting:Boolean;
		private var _sharedConnection:LocalConnection;
		
		private var _isRemote:Boolean = false;
		private var _remoteDelayed:int;
		private var _remoteDelay:int = 25;
		private var _remoteLinesQueue:Array;
		
		private var _viewingChannel:Array;
		private var _currentChannel:String;
		private var _consoleChannel:String = "C";
		private var _filterChannel:String = "Filtered";
		private var _mmChannel:String = "C";
		private var _isPaused:Boolean = false;
		private var _prefixChannelNames:Boolean = true;
		private var _memoryMode:int = 0;
		private var _menuMode:int;
		private var _isMinimised:Boolean = false;
		private var _isScaling:Boolean;
		private var _commandsHistory:Array;
		private var _commandsInd:int;
		private var _oMM:MemoryMonitor;
		private var _oFPS:FpsMonitor;
		private var _CL:CommandLine;
		private var _ui:UserInterface;
		private var _timers:Timers;
		private var _keyBinds:Object;
		
		public function Console(pass:String = "") {
			name = "ConsoleComponent";
			_password = pass;
			_keyBinds = new Object();
			//
			_background = new Shape();
			_background.graphics.beginFill(0xFFFFFF);
			_background.graphics.drawRoundRect(0, 0, 100, 100,10,10);
			var grid:Rectangle = new Rectangle(10, 10, 80, 80);
			_background.scale9Grid = grid ;
			addChild(_background);
			//
			var corner:Sprite = new Sprite();
			corner.graphics.lineStyle(1, 0xFF0000);
			corner.graphics.moveTo(_minWidth-1, 0);
			corner.graphics.lineTo(_minWidth-1, _minHeight-1);
			corner.graphics.moveTo(0, _minHeight-1);
			corner.graphics.lineTo(_minWidth-1, _minHeight-1);
			addChild(corner);
			//
			var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = 11;
			_traceField = new TextField();
			_traceField.wordWrap = true;
			_traceField.background  = false;
			_traceField.multiline = true;
			_traceField.defaultTextFormat = format;
			addChild(_traceField);
			//
			_menuField = new TextField();
			_menuField.selectable = false;
			_menuField.height = 18;
			_menuField.doubleClickEnabled = true;
			_menuField.addEventListener(MouseEvent.MOUSE_DOWN, onMenuMouseDown);
			_menuField.addEventListener(MouseEvent.MOUSE_UP,onMenuMouseUp);
			_menuField.y = -2;
			addEventListener(TextEvent.LINK, linkHandler);
			addChild(_menuField);
			//
			_commandBackground = new Shape();
			_commandBackground.graphics.beginFill(0xFFFFFF);
			_commandBackground.graphics.drawRoundRect(0, 0, 100, 18,8,8);
			grid = new Rectangle(10, 8, 80, 8);
			_commandBackground.scale9Grid = grid ;
			_commandBackground.visible = false;
			addChild(_commandBackground);
			//
			_commandField = new TextField();
			_commandField.type  = TextFieldType.INPUT;
			_commandField.height = 18;
			_commandField.addEventListener(KeyboardEvent.KEY_DOWN, commandKeyDown);
			_commandField.visible = false;
			addChild(_commandField);
			
			//
			_ruler = new Sprite();
			_ruler.graphics.lineStyle(1, 0xFF0000);
			_ruler.graphics.moveTo(_minWidth-1, -5);
			_ruler.graphics.lineTo(_minWidth-1, 37);
			_ruler.graphics.moveTo(-5, _minHeight-1);
			_ruler.graphics.lineTo(45, _minHeight-1);
			_ruler.visible = false;
			addChild(_ruler);
			//
			_scaler = new Sprite();
			_scaler.graphics.beginFill(0x000000, 0.6);
            _scaler.graphics.lineTo(-10, 0);
            _scaler.graphics.lineTo(0, -10);
            _scaler.graphics.endFill();
			_scaler.buttonMode = true;
			_scaler.doubleClickEnabled = true;
			_scaler.addEventListener(MouseEvent.MOUSE_DOWN,onScalerMouseDown);
			_scaler.addEventListener(MouseEvent.MOUSE_UP,onScalerMouseUp);
			_scaler.addEventListener(MouseEvent.DOUBLE_CLICK, onScalerDoubleClick);
            addChild(_scaler);
			//
			_ui = new UserInterface(_background, _menuField, _traceField, _commandBackground, _commandField);
			_oFPS = new FpsMonitor(this);
			_oMM = new MemoryMonitor();
			_timers = new Timers(addLogLine);
			_lines = new Array();
			_lineChanged = false;
			_channels = new Array("global");
			_currentChannel = "traces";
			_viewingChannel = ["global"];
			_isRepeating = false;
			_isPaused = false;
			_enabled = true;
			_menuMode = 1;
			
			_commandsHistory = new Array();
			_commandsInd = 0;
			_CL = new CommandLine(this, addLogLine);
			_CL.store("C",c);
			_CL.reserved.push("C");
			_CL.addEventListener(CommandLine.SEARCH_REQUEST, onCommandSearch, false, 0, true);
			//
			addEventListener(Event.ENTER_FRAME, _onEnterFrame, false, 0, true);
			//
			if(_password != ""){
				if(stage){
					stageAddedHandle();
				}else{
					addEventListener(Event.ADDED_TO_STAGE, stageAddedHandle, false, 0, true);
				}
				visible = false;
			}
			addLine("<b>v"+VERSION+", Happy bug fixing !</b>",-2,_consoleChannel);
			//
			width = 420;
			height = 16;
		}
		public function get ui():UserInterface{
			return _ui;
		}
		
		private function stageAddedHandle(e:Event=null):void{
			if(e!=null){
				this.removeEventListener(Event.ADDED_TO_STAGE, stageAddedHandle);
			}
			stage.addEventListener(KeyboardEvent.KEY_UP, keyDownHandler, false, 0, true);
		}
		private function onCommandSearch(e:Event=null):void{
			clear(_filterChannel);
			addLine("Filtering ["+_CL.searchTerm+"]", 10,_filterChannel);
			viewingChannel = _filterChannel;
		}
		
		private function commandKeyDown(e:KeyboardEvent):void{
			if(!_enabled){
				return;
			}
			if( e.keyCode == 13){
				if(_isRemote){
					try{
						_sharedConnection.send(remoteClientName, "remoteRun", _commandField.text);
					}catch(err:Error){
						addLine("Command could not be sent to client: " + err, 10,_consoleChannel);
					}
				}else{
					_CL.run(_commandField.text);
				}
				_commandsHistory.unshift(_commandField.text);
				_commandsInd = -1;
				_commandField.text = "";
				// maximum 50 history commands
				if(_commandsHistory.length>50){
					_commandsHistory.splice(50);
				}
			}else if( e.keyCode == 38 ){
				if(_commandsInd<(_commandsHistory.length-1)){
					_commandsInd++;
					_commandField.text = _commandsHistory[_commandsInd];
				}else{
					_commandsInd = _commandsHistory.length;
					_commandField.text = "";
				}
			}else if( e.keyCode == 40){
				if(_commandsInd>0){
					_commandsInd--;
					_commandField.text = _commandsHistory[_commandsInd];
				}else{
					_commandsInd = -1;
					_commandField.text = "";
				}
			}
		}
		private function refreshPage():void{
			var str:String = "";
			for each (var line:LogLineVO in _lines ){
				
				if((_viewingChannel.indexOf(_filterChannel)>=0 || line.c!=_filterChannel) && ((_CL.searchTerm && line.c != _consoleChannel && line.c != _filterChannel && line.text.toLowerCase().indexOf(_CL.searchTerm.toLowerCase())>=0 )|| (_viewingChannel.indexOf(line.c)>=0 || _viewingChannel.indexOf("global")>=0) && (line.p >= _priority || _priority == 0) )){
					//
					str += makeLine(line)+"<br>";
				}
			}
			_traceField.htmlText = str;
			_traceField.scrollV = _traceField.maxScrollV;
		}
		private function makeLine(line:LogLineVO):String{
			var colour:String = _ui.getPriorityHex(line.p);
			var str:String = "";
			if(line.p >= 10){
				str += "<b>";
			}
			var txt:String = line.text;
			if(_prefixChannelNames && _viewingChannel.indexOf("global")>=0 && line.c != _currentChannel){
				txt = "<a href=\"event:channel_"+line.c+"\">["+line.c+"</a>] "+txt;
			}
			str += "<font face=\"Verdana\" size=\"10\" color=\""+colour+"\">"+txt+"</font>";
			if(line.p >= 10){
				str += "</b>";
			}
			return str;
		}
		protected function addLogLine(line:LogLineVO):void{
			addLine(line.text, line.p, line.c, line.r, line.s);
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
			_lineChanged = true;
			if(isRepeating && _isRepeating){
				_lines.pop();
				_lines.push(line);
			}else{
				_repeated = 0;
				_lines.push(line);
				if(_lines.length > maxLines && maxLines > 0 ){
					_lines.splice(0,deleteLines);
					//addLine("Maximum lines ["+maxLines+"] reached. Deleted the first ["+_deleteLines+"] lines.",-1,_consoleChannel);
				}
				if( _tracing && (_tracingChannel == null || _tracingChannel.indexOf(channel)>=0) ){
					trace("["+channel+"] "+tmpText);
				}
			}
			_isRepeating = isRepeating;
			
			if(_isRemoting){
				_remoteLinesQueue.push(line);
			}
		}
		private function keyDownHandler(e:KeyboardEvent):void{
			if(!_enabled){
				return;
			}
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
					var key:String = char+(e.ctrlKey?"0":"1")+(e.altKey?"0":"1")+(e.shiftKey?"0":"1");
					if(_keyBinds[key]){
						var bind:Array = _keyBinds[key];
						bind[0].apply(this, bind[1]);
					}
				}
			}
		}
		public function bindKey(char:String, ctrl:Boolean, alt:Boolean, shift:Boolean, fun:Function ,args:Array):void{
			var key:String = char+(ctrl?"0":"1")+(alt?"0":"1")+(shift?"0":"1");
			if(fun is Function){
				_keyBinds[key] = [fun,args];
			}else{
				delete _keyBinds[key];
			}
		}
		private function toogleVisible():void{
			visible = !visible;
			paused = !visible;
			if(visible && stage){
				stage.focus = _commandField;
			}
		}
		private function linkHandler(e:TextEvent):void{
			stopDrag();
			if(e.text == "min"){
				height = 18;
			}else if(e.text == "max"){
				height = 200;
			}else if(e.text == "resetFPS"){
				if(_oFPS){
					_oFPS.reset();
				}
			}else if(e.text == "help"){
				help();
			}else if(e.text == "clear"){
				clear();
			}else if(e.text == "fps"){
				cycleFPS();
			}else if(e.text == "memory"){
				_memoryMode++;
				if(_memoryMode>3){
					_memoryMode = 0;
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
				command = !command;
			}else if(e.text == "menu"){
				_menuMode++;
				if(_menuMode>2){
					_menuMode = 0;
				}
			}else if(e.text == "gc"){
				gc();
			}else if(e.text == "trace"){
				_tracing = !_tracing;
				if(_tracing){
					addLine("Tracing turned [<b>On</b>]",-1,_consoleChannel);
				}else{
					addLine("Tracing turned [<b>Off</b>]",-1,_consoleChannel);
				}
			}else if(e.text == "alpha"){
				cycleAlpha();
			}else if(e.text.substring(0,8) == "channel_"){
				changeChannel(e.text.substring(8));
			}else if(e.text.substring(0,5) == "clip_"){
				_CL.reportMapClipInfo(e.text.substring(5));
			}
		}
		private function cycleFPS():void{
			if(_oFPS.running){
				if(_oFPS.format == 1){
					_oFPS.format = 2;
				}else if(_oFPS.format == 2){
					_oFPS.format = 3;
				}else if(_oFPS.format == 3){
					_oFPS.format = 4;
				}else{
					_oFPS.pause();
				}
			}else {
				_oFPS.start();
				_oFPS.format = 1;
			}
		}
		private function changeChannel(channel:String):void{
			//if(channel != _viewingChannel){
				viewingChannel = channel;
				//refreshPage();
			//}
		}
		private function cyclePriorities():void{
			if(_priority<10){
				_priority++;
			}else{
				_priority = 0;
			}
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
			addLine("FPS Metre: Min-<b>Average</b>-Max: <b>current</b>",10);
			addLine("[ R=Reset FPS, F=Toogle FPS, M=Memory, CL=Toogle CommandLine, C=Clear, T=Toogle tracing, P#=Priortiy filter level, A=Background Alpha, P=Pause, H=Help, X=Close ]",10);
			addLine("",0);
			addLine("Use the arrow at bottom right to scale this window.", 10);
			addLine("",0);
			addLine("Use the tabs at the top to switch between channels.",10);
			addLine("'Global' channel show outputs from all channels",8);
			addLine("________________________",-1);
		}
		private function _onEnterFrame(e:Event):void{
			if(!_enabled){
				return;
			}
			if(_isScaling){
				scaleByScaler();
			}
			if(_alwaysOnTop && parent &&  parent.getChildIndex(this) < (parent.numChildren-1)){
				parent.setChildIndex(this,(parent.numChildren-1));
				addLine("Attempted to move console on top (alwaysOnTop enabled)",-1,_consoleChannel);
			}
			if( _isRepeating ){
				_repeated++;
				if(_repeated > _maxRepeats && _maxRepeats >= 0){
					_isRepeating = false;
				}
			}
			if(!_isPaused && visible){
				_oFPS.update();
				var arr:Array = _oMM.update();
				if(arr.length>0){
					addLine("COLLECTED "+arr,10,_mmChannel);
				}
			}
			if(_isMinimised){
				if(_oFPS.running){
					_menuField.htmlText = Math.round(_oFPS.averageFPS) +"]";
				}else{
					_menuField.htmlText = "";
				}
			}else{
				var str:String ="<p align=\"right\">";
				if(_memoryMode == 1){
					str += "<b>"+Math.round(_oMM.currentMemory/1024)+"kb </b> ";
				}else if(_memoryMode > 1){
					str += Math.round(_oMM.minMemory/1024)+"kb-";
					str += "<b>"+Math.round(_oMM.currentMemory/1024)+"kb</b>-";
					str += ""+Math.round(_oMM.maxMemory/1024)+"kb ";
					if(_memoryMode == 3){
						str += "*";
					}
				}
				if(_oFPS.running){
					str += _oFPS.get+" ";
				}
				if(_menuMode != 2){
					for each(var channel in _channels){
						var channelTxt:String = (_viewingChannel.indexOf(channel)>=0) ? "<b>"+channel+"</b>" : channel;
						channelTxt = channel==_currentChannel ? "<i>"+channelTxt+"</i>" : channelTxt;
						str += "<a href=\"event:channel_"+channel+"\">["+channelTxt+"]</a> ";
					}
				}
				if(_menuMode != 1){
					str += "[";
					if(_oFPS.running){
						str += "<a href=\"event:resetFPS\">R</a> ";
					}
					str += "<a href=\"event:fps\">F</a> <a href=\"event:memory\">M</a> <a href=\"event:gc\">G</a> <a href=\"event:command\">CL</a> <a href=\"event:clear\">C</a> <a href=\"event:trace\">T</a> <a href=\"event:priority\">P"+_priority+"</a> <a href=\"event:alpha\">A</a> <a href=\"event:pause\">P</a> <a href=\"event:help\">H</a> <a href=\"event:close\">X</a>] ";
				}
				str += "<a href=\"event:menu\">@</a>"; 
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
			if(_lineChanged && !_isPaused && visible){
				refreshPage();
				_lineChanged = false;
			}
			if(_isRemoting){
				_remoteDelayed++;
				if(_remoteDelayed > _remoteDelay){
					updateRemote();
					_remoteDelayed = 0;
				}
			}
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
			startDrag();
			_ruler.visible = true;
		}
		private function onMenuMouseUp(e:Event):void{
			stopDrag();
			_ruler.visible = false;
		}
		private function onScalerDoubleClick(e:Event):void{
			height =  height<= (_minHeight+(_commandBackground.visible?_commandBackground.height:0)+1) ? 180 : _minHeight;
			if(width < 100){
				width = 200;
			}
		}
		private function onScalerMouseDown(e:Event):void{
			_scaler.startDrag(false, new Rectangle(_minWidth, _minHeight, 1280, 1280));
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
			var w:int = Math.round(_scaler.x-_minWidth);
			var h:int = Math.round(_scaler.y-_minHeight);
			var d:Number = Math.round(Math.sqrt((w*w)+(h*h))*10)/10;
			addLine("Ruler Width:<b>"+w +"</b>, Height:<b>"+h +"</b>, Diagonal:<b>"+d +"</b>.",-1,_consoleChannel);
		}
		private function errorsHandler(e:Event):void{
			add("ERROR: " + e, 5);
		}
		//
		public function get mm():MemoryMonitor{
			return _oMM;
		}
		public function get fps():FpsMonitor{
			return _oFPS;
		}
		public function get timers():Timers{
			return _timers;
		}
		public function gc():void{
			var ok:Boolean = _oMM.gc();
			var str:String = "Manual garbage collection "+(ok?"successful.":"FAILED. You need debugger version of flash player.");
			addLine(str,(ok?-1:10),_consoleChannel);
		}
		override public function get width():Number{
			return _background.width;
		}
		override public function set width(newW:Number):void{
			if(newW <= 50){
				_traceField.visible = false;
				newW = newW <_minWidth ? _minWidth: newW;
			}else{
				_traceField.visible = true;
			}
			_traceField.width = newW;
			_menuField.width = newW;
			_scaler.x = newW;
			_background.width = newW;
			_commandField.width = newW;
			_commandBackground.width = newW;
		}
		override public function set height(newW:Number):void{
			if(_commandBackground.visible){
				newW -= _commandBackground.height;
			}
			if(newW <_minHeight){
				newW = _minHeight;
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
			_background.height = newW;
			_traceField.scrollV = _traceField.maxScrollV;
		}
		override public function get height():Number{
			return _background.height+(_commandBackground.visible?_commandBackground.height:0);
		}
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
		public function get paused():Boolean{
			return _isPaused;
		}
		public function set paused(newV:Boolean):void{
			if(newV){
				this.addLine("Paused",10,_consoleChannel);
				// refresh page here to show the message before it pauses.
				refreshPage();
			}else{
				this.addLine("Resumed",-1,_consoleChannel);
			}
			_isPaused = newV;
			refreshPage();
		}
		public function destroy():void{
			enabled = false;
			closeSharedConnection();
			removeEventListener(Event.ENTER_FRAME, _onEnterFrame);
			if(stage){
				stage.removeEventListener(KeyboardEvent.KEY_UP, keyDownHandler);
			}
			_oMM = null;
			_oFPS.destory();
			_oFPS = null;
			_ui = null;
			_lines = null;
			_channels = null;
			_CL.destory();
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
			}
			refreshPage();
		}
		public function set enabled(newB:Boolean):void{
			if(_enabled && !newB){
				this.addLine("Console is now [<b>Disabled</b>]",10,_consoleChannel);
			}
			var pre:Boolean = _enabled;
			_enabled = newB;
			visible = newB;
			if(!pre && newB){
				this.addLine("Console is now [<b>Enabled</b>]",-1,_consoleChannel);
			}
		}
		public function get enabled():Boolean{
			return _enabled;
		}
		public function set tracing(newVar:Boolean):void{
			_tracing = newVar;
		}
		public function get tracing():Boolean{
			return _tracing;
		}
		public function set tracingChannel(newVar:String):void{
			if(newVar.length>0){
				_tracingChannel = newVar.split(",");
			}
		}
		public function get tracingChannel():String{
			return String(_tracingChannel);
		}
		public function set alwaysOnTop(newVar:Boolean):void{
			_alwaysOnTop = newVar;
		}
		public function get alwaysOnTop():Boolean{
			return _alwaysOnTop;
		}
		public function set memoryMonitor(newVar:int):void{
			_memoryMode = newVar;
		}
		public function get memoryMonitor():int{
			return _memoryMode;
		}
		public function set command (newB:Boolean):void{
			if(newB){
				_commandField.visible = true;
				_commandBackground.visible = true;
			}else{
				_commandField.visible = false;
				_commandBackground.visible = false;
			}
		}
		public function get command ():Boolean{
			return _commandField.visible;
		}
		private function updateRemote():void{
			if(_remoteLinesQueue.length==0) return;
			
			try{
				_sharedConnection.send(remoteServerName, "remoteLogSend", _remoteLinesQueue);
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
				addLine("Remoting started",10,_consoleChannel);
				try{
                	_sharedConnection.connect(remoteClientName);
           		}catch (error:Error){
					addLine("Could not connect to client server", 10,_consoleChannel);
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
                	_sharedConnection.connect(remoteServerName);
					addLine("Remote started",10,_consoleChannel);
           		}catch (error:Error){
					_isRemoting = false;
					addLine("Remoting is not possible", 10,_consoleChannel);
           		}
			}else{
				closeSharedConnection();
			}
		}
		private function startSharedConnection():void{
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
			if(e.level == "error"){
				
			}
			// this will get called quite often if there is no actual remote server running...
		}
		public static function get remoteIsRunning():Boolean{
			var sCon:LocalConnection = new LocalConnection();
			try{
				sCon.connect(remoteServerName);
			}catch(error:Error){
				return true;
			}
			sCon.close();
			return false;
		}
		public function remoteLogSend(lines:Object):void{
			if(!_isRemote) return;
			for each( var line:Object in lines){
				if(line){
					var p:int = line["p"]?line["p"]:5;
					var channel:String = line["c"]?line["c"]:"";
					var r:Boolean = line["r"];
					var safe:Boolean = line["s"];
					addLine(line["text"],p,channel,r,safe);
				}
			}
		}
		public function remoteRun(line:String):void{
			_CL.run(line);
		}
		public function get cl():CommandLine{
			return _CL;
		}
		public function get forceLine():Number{
			return _maxRepeats;
		}
		public function set forceLine(newV:Number):void{
			_maxRepeats = newV ;
		}
		public function get prefixChannelNames():Boolean{
			return _prefixChannelNames;
		}
		public function set prefixChannelNames(newV:Boolean):void{
			_prefixChannelNames = newV ;
		}
		public function get menuMode():int{
			return _menuMode;
		}
		public function set menuMode(newV:int):void{
			if(newV >= 0 && newV <= 2){
				_menuMode = newV ;
			}
		}
		public function ch(channel:Object, newLine:Object, priority:Number = 2, isRepeating:Boolean = false, skipSafe:Boolean = false):void{
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
			addLine(newLine,priority,chn, isRepeating,skipSafe);
		}
		public function pk(channel:Object, newLine:Object, priority:Number = 2, isRepeating:Boolean = false, skipSafe:Boolean = false):void{
			var chn:String = getQualifiedClassName(channel);
			var ind:int = chn.lastIndexOf("::");
			if(ind>=0){
				chn = chn.substring(0,ind);
			}
			addLine(newLine,priority,chn, isRepeating,skipSafe);
		}
		public function add(newLine:Object, priority:Number = 2, isRepeating:Boolean = false, skipSafe:Boolean = false):void{
			addLine(newLine,priority, _currentChannel, isRepeating,skipSafe);
		}
	}
	
}