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

package com.junkbyte.console.view {

	import com.junkbyte.console.ConsoleChannel;
	import com.junkbyte.console.Console;
	import com.junkbyte.console.vos.Log;
	import com.junkbyte.console.vos.Logs;

	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Rectangle;
	import flash.system.Security;
	import flash.system.SecurityPanel;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;

	public class MainPanel extends AbstractPanel {
		
		public static const NAME:String = "mainPanel";
		
		private var _traceField:TextField;
		private var _cmdPrefx:TextField;
		private var _cmdField:TextField;
		private var _cmdBG:Shape;
		private var _bottomLine:Shape;
		private var _isMinimised:Boolean;
		private var _shift:Boolean;
		private var _txtscroll:TextScroller;
		
		private var _channels:Array;
		private var _viewingChannels:Array;
		private var _lines:Logs;
		private var _commandsHistory:Array = [];
		private var _commandsInd:int = -1;
		private var _priority:int;
		private var _filterText:String;
		private var _filterRegExp:RegExp;
		
		private var _needUpdateMenu:Boolean;
		private var _needUpdateTrace:Boolean;
		private var _lockScrollUpdate:Boolean;
		private var _atBottom:Boolean = true;
		private var _enteringLogin:Boolean;
		
		public function MainPanel(m:Console, lines:Logs, channels:Array) {
			super(m);
			var fsize:int = style.menuFontSize;
			_channels = channels;
			_viewingChannels = new Array();
			_lines = lines;
			_commandsHistory = m.ud.commandLineHistory;
			
			name = NAME;
			minWidth = 50;
			minHeight = 18;
			
			_traceField = makeTF("traceField");
			_traceField.wordWrap = true;
			_traceField.multiline = true;
			_traceField.y = fsize;
			_traceField.addEventListener(Event.SCROLL, onTraceScroll, false, 0, true);
			addChild(_traceField);
			//
			txtField = makeTF("menuField");
			txtField.height = fsize+6;
			txtField.y = -2;
			registerTFRoller(txtField, onMenuRollOver);
			addChild(txtField);
			//
			_cmdBG = new Shape();
			_cmdBG.name = "commandBackground";
			_cmdBG.graphics.beginFill(style.commandLineColor, 0.1);
			_cmdBG.graphics.drawRoundRect(0, 0, 100, 18,fsize,fsize);
			_cmdBG.scale9Grid = new Rectangle(9, 9, 80, 1);
			addChild(_cmdBG);
			//
			var tf:TextFormat = new TextFormat(style.menuFont, style.menuFontSize, style.highColor);
			_cmdField = new TextField();
			_cmdField.name = "commandField";
			_cmdField.type  = TextFieldType.INPUT;
			_cmdField.x = 40;
			_cmdField.height = fsize+6;
			_cmdField.addEventListener(KeyboardEvent.KEY_DOWN, commandKeyDown, false, 0, true);
			_cmdField.addEventListener(KeyboardEvent.KEY_UP, commandKeyUp, false, 0, true);
			_cmdField.defaultTextFormat = tf;
			addChild(_cmdField);
			
			tf.color = style.commandLineColor;
			_cmdPrefx = new TextField();
			_cmdPrefx.name = "commandPrefx";
			_cmdPrefx.type  = TextFieldType.DYNAMIC;
			_cmdPrefx.x = 2;
			_cmdPrefx.height = fsize+6;
			_cmdPrefx.selectable = false;
			_cmdPrefx.defaultTextFormat = tf;
			_cmdPrefx.text = " ";
			_cmdPrefx.addEventListener(MouseEvent.MOUSE_DOWN, onCmdPrefMouseDown, false, 0, true);
			_cmdPrefx.addEventListener(MouseEvent.MOUSE_MOVE, onCmdPrefRollOverOut, false, 0, true);
			_cmdPrefx.addEventListener(MouseEvent.ROLL_OUT, onCmdPrefRollOverOut, false, 0, true);
			addChild(_cmdPrefx);
			//
			_bottomLine = new Shape();
			_bottomLine.name = "blinkLine";
			_bottomLine.alpha = 0.2;
			addChild(_bottomLine);
			//
			_txtscroll = new TextScroller(null, style.controlColor);
			_txtscroll.y = fsize+4;
			_txtscroll.addEventListener(Event.INIT, startedScrollingHandle, false, 0, true);
			_txtscroll.addEventListener(Event.COMPLETE, stoppedScrollingHandle,  false, 0, true);
			_txtscroll.addEventListener(Event.SCROLL, onScrolledHandle,  false, 0, true);
			_txtscroll.addEventListener(Event.CHANGE, onScrollIncHandle,  false, 0, true);
			addChild(_txtscroll);
			//
			_cmdField.visible = false;
			_cmdPrefx.visible = false;
			_cmdBG.visible = false;
			//
			init(640,100,true);
			registerDragger(txtField);
			//
			addEventListener(TextEvent.LINK, linkHandler, false, 0, true);
			addEventListener(Event.ADDED_TO_STAGE, stageAddedHandle, false, 0, true);
			addEventListener(Event.REMOVED_FROM_STAGE, stageRemovedHandle, false, 0, true);
			
			master.cl.addEventListener(Event.CHANGE, onUpdateCommandLineScope, false, 0, true);
		}
		/*
		public function addMenu(key:String, f:Function, rollover:String):void{
			_extraMenus.push(new ExternalMenu(key, rollover, f));
			_needUpdateMenu = true;
		}
		public function removeMenu(key:String):void{
			_needUpdateMenu = true;
		}*/

		private function stageAddedHandle(e:Event=null):void{
			stage.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler, false, 0, true);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler, false, 0, true);
		}
		private function stageRemovedHandle(e:Event=null):void{
			stage.removeEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
		}
		private function onCmdPrefRollOverOut(e : MouseEvent) : void {
			master.panels.tooltip(e.type==MouseEvent.MOUSE_MOVE?"Current scope::(CommandLine)":"", this);
		}
		private function onCmdPrefMouseDown(e : MouseEvent) : void {
			stage.focus = _cmdField;
			_cmdField.setSelection(_cmdField.text.length, _cmdField.text.length);
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
		}
		public function requestLogin(on:Boolean = true):void{
			var ct:ColorTransform = new ColorTransform();
			if(on){
				master.commandLine = true;
				master.report("//", -2);
				master.report("// <b>Enter remoting password</b> in CommandLine below...", -2);
				updateCLScope("Password");
				ct.color = style.controlColor;
				_cmdBG.transform.colorTransform = ct;
				_traceField.transform.colorTransform = new ColorTransform(0.7,0.7,0.7);
			}else{
				updateCLScope("?");
				_cmdBG.transform.colorTransform = ct;
				_traceField.transform.colorTransform = ct;
			}
			_cmdField.displayAsPassword = on;
			_enteringLogin = on;
		}
		public function update(changed:Boolean):void{
			if(_bottomLine.alpha>0){
				_bottomLine.alpha -= 0.25;
			}
			if(changed){
				_bottomLine.alpha = 1;
				_needUpdateMenu = true;
				_needUpdateTrace = true;
			}
			if(_needUpdateTrace){
				_needUpdateTrace = false;
				_updateTraces(true);
			}
			if(_needUpdateMenu){
				_needUpdateMenu = false;
				_updateMenu();
			}
		}
		public function updateToBottom():void{
			_atBottom = true;
			_needUpdateTrace = true;
		}
		public function updateTraces(instant:Boolean = false):void{
			if(instant){
				_updateTraces();
			}else{
				_needUpdateTrace = true;
			}
		}
		private function _updateTraces(onlyBottom:Boolean = false):void{
			if(_atBottom) {
				updateBottom(); 
			}else if(!onlyBottom){
				updateFull();
			}
		}
		private function updateFull():void{
			var str:String = "";
			var line:Log = _lines.first;
			while(line){
				if(lineShouldShow(line)){
					str += makeLine(line);
				}
				line = line.next;
			}
			_lockScrollUpdate = true;
			_traceField.htmlText = str;
			_lockScrollUpdate = false;
			updateScroller();
		}
		public function setPaused(b:Boolean):void{
			if(b && _atBottom){
				_atBottom = false;
				updateTraces(true);
				_traceField.scrollV = _traceField.maxScrollV;
			}else if(!b){
				_atBottom = true;
				updateBottom();
			}
			updateMenu();
		}
		private function updateBottom():void{
			var lines:Array = new Array();
			var linesLeft:int = Math.round(_traceField.height/style.traceFontSize);
			var maxchars:int = Math.round(_traceField.width*5/style.traceFontSize);
			
			var line:Log = _lines.last;
			while(line){
				if(lineShouldShow(line)){
					var numlines:int = Math.ceil(line.t.length/ maxchars);
					if(line.s || linesLeft >= numlines ){
						lines.push(makeLine(line));
					}else{
						line = line.clone();
						line.t = line.t.substring(Math.max(0,line.t.length-(maxchars*linesLeft)));
						lines.push(makeLine(line));
						break;
					}
					linesLeft-=numlines;
					if(linesLeft<=0){
						break;
					}
				}
				line = line.prev;
			}
			_lockScrollUpdate = true;
			_traceField.htmlText = lines.reverse().join("");
			_traceField.scrollV = _traceField.maxScrollV;
			_lockScrollUpdate = false;
			updateScroller();
		}
		private function lineShouldShow(line:Log):Boolean{
			return (
				(
					_viewingChannels.length == 0
			 		|| _viewingChannels.indexOf(line.c)>=0 
			 		|| (_filterText && _viewingChannels.indexOf(config.filteredChannel) >= 0 && line.t.toLowerCase().indexOf(_filterText.toLowerCase())>=0 )
			 		|| (_filterRegExp && _viewingChannels.indexOf(config.filteredChannel)>=0 && line.t.search(_filterRegExp)>=0 )
			 	) 
			 	&& ( _priority <= 0 || line.p >= _priority)
			);
		}
		public function set priority (i:int):void{
			_priority = i;
			updateToBottom();
			updateMenu();
		}
		public function get priority ():int{
			return _priority;
		}
		public function get viewingChannels():Array{
			return _viewingChannels;
		}
		public function set viewingChannels(a:Array):void{
			_viewingChannels.splice(0);
			if(a && a.length) {
				if(a.indexOf(config.globalChannel) >= 0) a = [];
				for each(var item:Object in a) _viewingChannels.push(item is ConsoleChannel?(ConsoleChannel(item).name):String(item));
			}
			updateToBottom();
			master.panels.updateMenu();
		}
		//
		public function set filterText(str:String):void{
			_filterText = str;
			if(str){
				_filterRegExp = null;
				master.clear(config.filteredChannel);
				_channels.splice(1,0,config.filteredChannel);
				master.ch(config.filteredChannel, "Filtering ["+str+"]", -2);
				viewingChannels = [config.filteredChannel];
			}else if(_viewingChannels.length == 1 && _viewingChannels[0] == config.filteredChannel){
				viewingChannels = [config.globalChannel];
			}
		}
		public function get filterText():String{
			return _filterText?_filterText:(_filterRegExp?String(_filterRegExp):null);
		}
		//
		public function set filterRegExp(exp:RegExp):void{
			_filterRegExp = exp;
			if(exp){
				_filterText = null;
				master.clear(config.filteredChannel);
				_channels.splice(1,0,config.filteredChannel);
				master.ch(config.filteredChannel, "Filtering RegExp ["+exp+"]", -2);
				viewingChannels = [config.filteredChannel];
			}else if(_viewingChannels.length == 1 && _viewingChannels[0] == config.filteredChannel){
				viewingChannels = [config.globalChannel];
			}
		}
		private function makeLine(line:Log):String{
			var str:String = "";
			var txt:String = line.t;
			if(line.c != config.defaultChannel && (_viewingChannels.length == 0 || _viewingChannels.length>1)){
				txt = "[<a href=\"event:channel_"+line.c+"\">"+line.c+"</a>] "+txt;
			}
			var ptag:String = "p"+line.p;
			str += "<p><"+ptag+">" + txt + "</"+ptag+"></p>";
			return str;
		}
		private function onTraceScroll(e:Event = null):void{
			if(_lockScrollUpdate) return;
			var atbottom:Boolean = _traceField.scrollV >= _traceField.maxScrollV-1;
			if(!master.paused && _atBottom !=atbottom){
				var diff:int = _traceField.maxScrollV-_traceField.scrollV;
				_atBottom = atbottom;
				_updateTraces();
				_traceField.scrollV = _traceField.maxScrollV-diff;
			}
			updateScroller();
		}
		private function updateScroller():void{
			if(_traceField.maxScrollV <= 1){
				_txtscroll.visible = false;
			}else{
				_txtscroll.visible = true;
				if(_atBottom) {
					_txtscroll.scrollPercent = 1;
				}else{
					_txtscroll.scrollPercent = (_traceField.scrollV-1)/(_traceField.maxScrollV-1);
				}
			}
		}
		private function startedScrollingHandle(e:Event):void{
			if(!master.paused){
				_atBottom = false;
				var p:Number = _txtscroll.scrollPercent;
				_updateTraces();
				_txtscroll.scrollPercent = p;
			}
		}
		private function onScrolledHandle(e:Event):void{
			_lockScrollUpdate = true;
			_traceField.scrollV = Math.round((_txtscroll.scrollPercent*(_traceField.maxScrollV-1))+1);
			_lockScrollUpdate = false;
		}
		private function onScrollIncHandle(e:Event):void{
			_traceField.scrollV += _txtscroll.targetIncrement;
		}
		private function stoppedScrollingHandle(e:Event):void{
			onTraceScroll();
		}
		override public function set width(n:Number):void{
			_lockScrollUpdate = true;
			super.width = n;
			_traceField.width = n-4;
			txtField.width = n;
			_cmdField.width = width-15-_cmdField.x;
			_cmdBG.width = n;
			
			_bottomLine.graphics.clear();
			_bottomLine.graphics.lineStyle(1, style.controlColor);
			_bottomLine.graphics.moveTo(10, -1);
			_bottomLine.graphics.lineTo(n-10, -1);
			_txtscroll.x = n;
			onUpdateCommandLineScope();
			_atBottom = true;
			_needUpdateMenu = true;
			_needUpdateTrace = true;
			_lockScrollUpdate = false;
		}
		override public function set height(n:Number):void{
			_lockScrollUpdate = true;
			super.height = n;
			var fsize:int = style.menuFontSize;
			var msize:Number = fsize+6+style.traceFontSize;
			var minimize:Boolean = n<(_cmdField.visible?(msize+fsize+4):msize);
			if(_isMinimised != minimize){
				registerDragger(txtField, minimize);
				registerDragger(_traceField, !minimize);
				_isMinimised = minimize;
			}
			txtField.visible = !minimize;
			_traceField.y = minimize?0:fsize;
			_traceField.height = n-(_cmdField.visible?(fsize+4):0)-(minimize?0:fsize);
			var cmdy:Number = n-(fsize+6);
			_cmdField.y = cmdy;
			_cmdPrefx.y = cmdy;
			_cmdBG.y = cmdy;
			_bottomLine.y = _cmdField.visible?cmdy:n;
			//
			_txtscroll.height = (_bottomLine.y-(_cmdField.visible?0:10))-_txtscroll.y;
			//
			_atBottom = true;
			_needUpdateTrace = true;
			_lockScrollUpdate = false;
		}
		//
		//
		//
		public function updateMenu(instant:Boolean = false):void{
			if(instant){
				_updateMenu();
			}else{
				_needUpdateMenu = true;
			}
		}
		private function _updateMenu():void{
			var str:String = "<r><w>";
			if(!master.panels.channelsPanel){
				str += getChannelsLink(true);
			}
			str += "<menu>[ <b>";
			
			/*var extras:uint = _extraMenus.length;
			if(extras){
				for(var i:uint = 0; i<extras; i++){
					str += " <a href=\"event:external_"+i+"\">"+_extraMenus[i].key+"</a>";
				}
			}*/
			
			str += doActive("<a href=\"event:fps\">F</a>", master.fpsMonitor>0);
			str += doActive(" <a href=\"event:mm\">M</a>", master.memoryMonitor>0);
			if(config.commandLineAllowed){
				str += doActive(" <a href=\"event:command\">CL</a>", commandLine);
			}
			if(!master.remote){
				str += doActive(" <a href=\"event:roller\">Ro</a>", master.displayRoller);
				str += doActive(" <a href=\"event:ruler\">RL</a>", master.panels.rulerActive);
			}
			str += " ¦</b>";
			str += " <a href=\"event:copy\">Cc</a>";
			str += " <a href=\"event:priority\">P"+_priority+"</a>";
			str += doActive(" <a href=\"event:pause\">P</a>", master.paused);
			str += " <a href=\"event:clear\">C</a> <a href=\"event:close\">X</a>";
			
			str += " ]</menu> </w></r>";
			txtField.htmlText = str;
			txtField.scrollH = txtField.maxScrollH;
		}
		public function getChannelsLink(limited:Boolean = false):String{
			var str:String = "<chs>";
			var len:int = _channels.length;
			if(limited && len>style.maxChannelsInMenu) len = style.maxChannelsInMenu;
			for(var ci:int = 0; ci<len;  ci++){
				var channel:String = _channels[ci];
				var channelTxt:String = ((ci == 0 && _viewingChannels.length == 0) || _viewingChannels.indexOf(channel)>=0) ? "<ch><b>"+channel+"</b></ch>" : channel;
				str += "<a href=\"event:channel_"+channel+"\">["+channelTxt+"]</a> ";
			}
			if(limited){
				str += "<ch><a href=\"event:channels\"><b>"+(_channels.length>len?"...":"")+"</b>^^ </a></ch>";
			}
			str += "</chs> ";
			return str;
		}
		private function doActive(str:String, b:Boolean):String{
			if(b) return "<hi>"+str+"</hi>";
			return str;
		}
		public function onMenuRollOver(e:TextEvent, src:AbstractPanel = null):void{
			if(src==null) src = this;
			var txt:String = e.text?e.text.replace("event:",""):"";
			
			if(txt == "channel_"+config.globalChannel){
				txt = "View all channels";
			}else if(txt == "channel_"+config.defaultChannel) {
				txt = "Default channel::Logs with no channel";
			}else if(txt == "channel_"+ config.consoleChannel) {
				txt = "Console's channel::Logs generated from Console";
			}else if(txt == "channel_"+ config.filteredChannel) {
				txt = "Filtering channel"+"::*"+filterText+"*";
			}else if(txt.indexOf("channel_")==0) {
				txt = "Change channel::Hold shift to select multiple channels";
			}else if(txt == "pause"){
				if(master.paused)
					txt = "Resume updates";
				else
					txt = "Pause updates";
			}else if(txt == "close" && src == this){
				txt = "Close::Type password to show again";
			}else{
				var obj:Object = {
					fps:"Frames Per Second",
					mm:"Memory Monitor",
					roller:"Display Roller::Map the display list under your mouse",
					ruler:"Screen Ruler::Measure the distance and angle between two points on screen.",
					command:"Command Line",
					copy:"Copy to clipboard",
					clear:"Clear log",
					priority:"Toggle priority filter",
					channels:"Expand channels",
					close:"Close"
					};
				txt = obj[txt];
			}
			master.panels.tooltip(txt, src);
		}
		private function linkHandler(e:TextEvent):void{
			txtField.setSelection(0, 0);
			stopDrag();
			//if(topMenuClick!=null && topMenuClick(e.text)) return;
			if(e.text == "pause"){
				if(master.paused){
					master.paused = false;
					//master.panels.tooltip("Pause updates", this);
				}else{
					master.paused = true;
					//master.panels.tooltip("Resume updates", this);
				}
				master.panels.tooltip(null);
			}else if(e.text == "close"){
				master.panels.tooltip();
				visible = false;
				dispatchEvent(new Event(Event.CLOSE));
			}else if(e.text == "channels"){
				master.panels.channelsPanel = !master.panels.channelsPanel;
			}else if(e.text == "fps"){
				master.fpsMonitor = !master.fpsMonitor;
			}else if(e.text == "priority"){
				if(_priority<10){
					priority++;
				}else{
					priority = 0;
				}
			}else if(e.text == "mm"){
				master.memoryMonitor = !master.memoryMonitor;
			}else if(e.text == "roller"){
				master.displayRoller = !master.displayRoller;
			}else if(e.text == "ruler"){
				master.panels.tooltip();
				master.panels.startRuler();
			}else if(e.text == "command"){
				commandLine = !commandLine;
			}else if(e.text == "copy") {
				System.setClipboard(master.getAllLog());
				master.report("Copied log to clipboard.", -1);
			}else if(e.text == "clear"){
				master.clear();
			}else if(e.text == "settings"){
				master.report("A new window should open in browser. If not, try searching for 'Flash Player Global Security Settings panel' online :)", -1);
				Security.showSettings(SecurityPanel.SETTINGS_MANAGER);
			}else if(e.text.substring(0,8) == "channel_"){
				onChannelPressed(e.text.substring(8));
			}else if(e.text.substring(0,5) == "clip_"){
				var str:String = "/remap "+e.text.substring(5);
				master.runCommand(str);
			}else if(e.text.substring(0,6) == "sclip_"){
				//var str:String = "/remap 0|"+e.text.substring(6);
				master.runCommand("/remap 0"+Console.REMAPSPLIT+e.text.substring(6));
				//master.cl.reMap(e.text.substring(6), stage);
			}
			txtField.setSelection(0, 0);
			e.stopPropagation();
		}
		public function onChannelPressed(chn:String):void{
			var current:Array = _viewingChannels.concat();
			if(_shift && _viewingChannels.length > 0 && chn != config.globalChannel){
				var ind:int = current.indexOf(chn);
				if(ind>=0){
					current.splice(ind,1);
					if(current.length == 0){
						current.push(config.globalChannel);
					}
				}else{
					current.push(chn);
				}
				viewingChannels = current;
			}else{
				viewingChannels = [chn];
			}
		}
		//
		// COMMAND LINE
		//
		public function clearCommandLineHistory():void
		{
			_commandsHistory.splice(0);
			_commandsInd = -1;
			master.ud.commandLineHistoryChanged();
		}
		private function commandKeyDown(e:KeyboardEvent):void{
			e.stopPropagation();
		}
		private function commandKeyUp(e:KeyboardEvent):void{
			if( e.keyCode == Keyboard.ENTER){
				updateToBottom();
				if(_enteringLogin){
					dispatchEvent(new Event(Event.CONNECT));
					_cmdField.text = "";
					requestLogin(false);
				}else{
					var txt:String = _cmdField.text;
					if(txt.length > 2){
						var i:int = _commandsHistory.indexOf(txt);
						while(i>=0){
							_commandsHistory.splice(i,1);
							i = _commandsHistory.indexOf(txt);
						}
						_commandsHistory.unshift(txt);
						_commandsInd = -1;
						// maximum 20 commands history
						if(_commandsHistory.length>20){
							_commandsHistory.splice(20);
						}
						master.ud.commandLineHistoryChanged();
					}
					_cmdField.text = "";
					master.runCommand(txt);
				}
			}if( e.keyCode == Keyboard.ESCAPE){
				if(stage) stage.focus = null;
			}else if( e.keyCode == Keyboard.UP){
				// if its back key for first time, store the current key
				if(_cmdField.text && _commandsInd<0){
					_commandsHistory.unshift(_cmdField.text);
					_commandsInd++;
				}
				if(_commandsInd<(_commandsHistory.length-1)){
					_commandsInd++;
					_cmdField.text = _commandsHistory[_commandsInd];
					_cmdField.setSelection(_cmdField.text.length, _cmdField.text.length);
				}else{
					_commandsInd = _commandsHistory.length;
					_cmdField.text = "";
				}
			}else if( e.keyCode == Keyboard.DOWN){
				if(_commandsInd>0){
					_commandsInd--;
					_cmdField.text = _commandsHistory[_commandsInd];
					_cmdField.setSelection(_cmdField.text.length, _cmdField.text.length);
				}else{
					_commandsInd = -1;
					_cmdField.text = "";
				}
			}
			e.stopPropagation();
		}
		private function onUpdateCommandLineScope(e:Event=null):void{
			if(!master.remote) updateCLScope(master.cl.scopeString);
		}
		public function get commandLineText():String{
			return _cmdField.text;
		}
		public function set  commandLineText(str:String):void{
			_cmdField.text = str?str:"";
		}
		public function updateCLScope(str:String):void{
			if(_enteringLogin) {
				_enteringLogin = false;
				requestLogin(false);
			}
			_cmdPrefx.autoSize = TextFieldAutoSize.LEFT;
			_cmdPrefx.text = str;
			var w:Number = width-48;
			if(_cmdPrefx.width > 120 || _cmdPrefx.width > w){
				_cmdPrefx.autoSize = TextFieldAutoSize.NONE;
				_cmdPrefx.width = w>120?120:w;
				_cmdPrefx.scrollH = _cmdPrefx.maxScrollH;
			}
			_cmdField.x = _cmdPrefx.width+2;
			_cmdField.width = width-15-_cmdField.x;
		}
		public function set commandLine (b:Boolean):void{
			if(b && config.commandLineAllowed){
				_cmdField.visible = true;
				_cmdPrefx.visible = true;
				_cmdBG.visible = true;
			}else{
				_cmdField.visible = false;
				_cmdPrefx.visible = false;
				_cmdBG.visible = false;
			}
			_needUpdateMenu = true;
			this.height = height;
		}
		public function get commandLine ():Boolean{
			return _cmdField.visible;
		}
	}
}
/*
internal class ExternalMenu{
	public var key:String;
	public var rollover:String;
	public var click:Function;
	
	public function ExternalMenu(k:String, rover:String, clk:Function):void{
		key = k;
		rollover = rover;
		click = clk;
	}
}*/