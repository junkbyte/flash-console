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

package com.luaye.console.view {
	import flash.system.System;	
	
	import com.luaye.console.Console;
	import com.luaye.console.core.CommandLine;
	import com.luaye.console.core.Log;
	import com.luaye.console.core.Logs;

	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.system.Security;
	import flash.system.SecurityPanel;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.ui.Keyboard;

	public class MainPanel extends AbstractPanel {
		
		private static const CHANNELS_IN_MENU:int = 7;
		
		public static const TOOLTIPS:Object = {
				fps:"Frames Per Second",
				mm:"Memory Monitor",
				roller:"Display Roller::Map the display list under your mouse",
				ruler:"Screen Ruler::Measure the distance and angle between two points on screen.",
				command:"Command Line",
				copy:"Copy to clipboard",
				clear:"Clear log",
				trace:"Trace",
				pause:"Pause updates",
				resume:"Resume updates",
				priority:"Priority filter",
				channels:"Expand channels",
				close:"Close",
				closemain:"Close::Type password to show again",
				viewall:"View all channels",
				defaultch:"Default channel::Logs with no channel",
				consolech:"Console's channel::Logs generated from Console",
				filterch:"Filtering channel",
				channel:"Change channel::Hold shift to select multiple channels",
				scrollUp:"Scroll up",
				scrollDown:"Scroll down",
				scope:"Current scope::(CommandLine)"
		};
		
		// these are used for adding extended functionality such as from RemoteAIR
		private var _extraMenuKeys:Array = [];
		public var topMenuClick:Function;
		public var topMenuRollOver:Function;
		
		private var _traceField:TextField;
		private var _menuField:TextField;
		private var _commandPrefx:TextField;
		private var _commandField:TextField;
		private var _commandBackground:Shape;
		private var _bottomLine:Shape;
		private var _isMinimised:Boolean;
		private var _shift:Boolean;
		private var _canUseTrace:Boolean;
		private var _scrollbar:Sprite;
		private var _scroller:Sprite;
		private var _scrolldelay:uint;
		private var _scrolldir:int;
		
		private var _channels:Array;
		private var _lines:Logs;
		private var _commandsHistory:Array = [];
		private var _commandsInd:int;
		
		private var _needUpdateMenu:Boolean;
		private var _needUpdateTrace:Boolean;
		private var _lockScrollUpdate:Boolean;
		private var _atBottom:Boolean = true;
		private var _enteringLogin:Boolean;
		
		public function MainPanel(m:Console, lines:Logs, channels:Array) {
			super(m);
			
			_canUseTrace = (Capabilities.playerType=="External"||Capabilities.isDebugger);
			
			_channels = channels;
			_lines = lines;
			name = Console.PANEL_MAIN;
			minimumWidth = 50;
			minimumHeight = 18;
			
			_traceField = new TextField();
			_traceField.name = "traceField";
			_traceField.wordWrap = true;
			_traceField.background  = false;
			_traceField.multiline = true;
			_traceField.styleSheet = style.css;
			_traceField.y = 12;
			_traceField.addEventListener(Event.SCROLL, onTraceScroll, false, 0, true);
			addChild(_traceField);
			//
			_menuField = new TextField();
			_menuField.name = "menuField";
			_menuField.styleSheet = style.css;
			_menuField.height = 18;
			_menuField.y = -2;
			registerRollOverTextField(_menuField);
			_menuField.addEventListener(AbstractPanel.TEXT_LINK, onMenuRollOver, false, 0, true);
			addChild(_menuField);
			//
			_commandBackground = new Shape();
			_commandBackground.name = "commandBackground";
			_commandBackground.graphics.beginFill(style.commandLineColor, 0.1);
			_commandBackground.graphics.drawRoundRect(0, 0, 100, 18,12,12);
			_commandBackground.scale9Grid = new Rectangle(9, 9, 80, 1);
			addChild(_commandBackground);
			//
			_commandField = new TextField();
			_commandField.name = "commandField";
			_commandField.type  = TextFieldType.INPUT;
			_commandField.x = 40;
			_commandField.height = 18;
			_commandField.addEventListener(KeyboardEvent.KEY_DOWN, commandKeyDown, false, 0, true);
			_commandField.addEventListener(KeyboardEvent.KEY_UP, commandKeyUp, false, 0, true);
			_commandField.defaultTextFormat = style.textFormat;
			addChild(_commandField);
			
			_commandPrefx = new TextField();
			_commandPrefx.name = "commandPrefx";
			_commandPrefx.type  = TextFieldType.DYNAMIC;
			_commandPrefx.x = 2;
			_commandPrefx.height = 18;
			_commandPrefx.selectable = false;
			_commandPrefx.styleSheet = style.css;
			_commandPrefx.text = " ";
			_commandPrefx.addEventListener(MouseEvent.MOUSE_DOWN, onCmdPrefMouseDown, false, 0, true);
			_commandPrefx.addEventListener(MouseEvent.MOUSE_MOVE, onCmdPrefRollOverOut, false, 0, true);
			_commandPrefx.addEventListener(MouseEvent.ROLL_OUT, onCmdPrefRollOverOut, false, 0, true);
			addChild(_commandPrefx);
			//
			_bottomLine = new Shape();
			_bottomLine.name = "blinkLine";
			_bottomLine.alpha = 0.2;
			addChild(_bottomLine);
			//
			_scrollbar = new Sprite();
			_scrollbar.name = "scrollbar";
			_scrollbar.buttonMode = true;
			_scrollbar.addEventListener(MouseEvent.MOUSE_DOWN, onScrollbarDown, false, 0, true);
			_scrollbar.y = 16;
			addChild(_scrollbar);
			//
			_scroller = new Sprite();
			_scroller.name = "scroller";
			_scroller.graphics.beginFill(style.panelScalerColor, 1);
			_scroller.graphics.drawRect(-5, 0, 5, 30);
			_scroller.graphics.beginFill(0, 0);
			_scroller.graphics.drawRect(-10, 0, 10, 30);
			_scroller.graphics.endFill();
			_scroller.buttonMode = true;
			_scroller.addEventListener(MouseEvent.MOUSE_DOWN, onScrollerDown, false, 0, true);
			addChild(_scroller);
			//
			_commandField.visible = false;
			_commandPrefx.visible = false;
			_commandBackground.visible = false;
			//
			init(420,100,true);
			registerDragger(_menuField);
			//
			addEventListener(TextEvent.LINK, linkHandler, false, 0, true);
			addEventListener(Event.ADDED_TO_STAGE, stageAddedHandle, false, 0, true);
			addEventListener(Event.REMOVED_FROM_STAGE, stageRemovedHandle, false, 0, true);
			
			master.cl.addEventListener(CommandLine.CHANGED_SCOPE, onUpdateCommandLineScope, false, 0, true);
		}
		public function addMenuKey(key:String):void{
			_extraMenuKeys.push(key);
			_needUpdateMenu = true;
		}

		private function stageAddedHandle(e:Event=null):void{
			stage.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler, false, 0, true);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler, false, 0, true);
		}
		private function stageRemovedHandle(e:Event=null):void{
			stage.removeEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
		}
		private function onCmdPrefRollOverOut(e : MouseEvent) : void {
			master.panels.tooltip(e.type==MouseEvent.MOUSE_MOVE?TOOLTIPS["scope"]:"", this);
		}
		private function onCmdPrefMouseDown(e : MouseEvent) : void {
			stage.focus = _commandField;
			_commandField.setSelection(_commandField.text.length, _commandField.text.length);
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
				ct.color = style.bottomLineColor;
				_commandBackground.transform.colorTransform = ct;
				_traceField.transform.colorTransform = new ColorTransform(0.7,0.7,0.7);
			}else{
				updateCLScope("?");
				_commandBackground.transform.colorTransform = ct;
				_traceField.transform.colorTransform = ct;
			}
			_commandField.displayAsPassword = on;
			_enteringLogin = on;
		}
		public function update(changed:Boolean):void{
			//if(visible){
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
			//}
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
			// TODO: onlyBottom: when you are scrolled up, it doesnt update for new lines, because
			// you won't see them while scrolled up anyway... (it increase performace a lot on long logs)
			// BUT scroll up, add lots of new lines, scroll back down,
			// you'll see it jumps to the bottom of log which can be annoying in rare cases
			// 
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
				if(master.lineShouldShow(line)){
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
			var linesLeft:int = Math.round(_traceField.height/10);
			var line:Log = _lines.last;
			while(line){
				if(master.lineShouldShow(line)){
					linesLeft--;
					lines.push(makeLine(line));
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
		private function makeLine(line:Log):String{
			var str:String = "";
			var txt:String = line.text;
			if(master.prefixChannelNames && (master.viewingChannels.indexOf(Console.GLOBAL_CHANNEL)>=0 || master.viewingChannels.length>1) && line.c != Console.DEFAULT_CHANNEL){
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
			if(_traceField.maxScrollV<=1 || scrollerMaxY<22){
				_scroller.visible = false;
				_scrollbar.visible = false;
			}else{
				_scrollbar.visible = true;
				_scroller.visible = true;
				/* // scroller resize... works but waste of resouse I think
				var h:Number = (height*20)/_lines.length;
				var mh:Number = _bottomLine.y-40;
				_scroller.height = h<16?16:(h>mh?mh:h);
				*/
				
				if(_atBottom) {
					_scroller.y = scrollerMaxY;
				}else{
					var per:Number = (_traceField.scrollV-1)/(_traceField.maxScrollV-1);
					_scroller.y = 21+((scrollerMaxY-21)*per);
				}
			}
		}
		private function onScrollerDown(e:MouseEvent):void{
			if(!master.paused){
				_atBottom = false;
				var Y:int = _scroller.y;
				_updateTraces();
				_scroller.y = Y;
			}
			_scroller.startDrag(false, new Rectangle(_scroller.x,21, 0, (scrollerMaxY-21)));
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onScrollerMove, false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_UP, onScrollerUp, false, 0, true);
		}
		private function onScrollerMove(e:MouseEvent):void{
			var minY:Number = 21;
			var per:Number = (_scroller.y-minY)/(scrollerMaxY-minY);
			_lockScrollUpdate = true;
			_traceField.scrollV = Math.round((per*(_traceField.maxScrollV-1))+1);
			_lockScrollUpdate = false;
		}
		private function get scrollerMaxY():Number{
			return _bottomLine.y-_scroller.height-(_commandField.visible?5:15);
		}
		private function onScrollerUp(e:MouseEvent):void{
			_scroller.stopDrag();
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onScrollerMove);
			stage.removeEventListener(MouseEvent.MOUSE_UP, onScrollerUp);
			onTraceScroll();
		}
		private function onScrollbarDown(e:MouseEvent):void{
			if(_scroller.mouseY>0) {
				_traceField.scrollV += 3;
				_scrolldir = 3;
			}
			else {
				_traceField.scrollV -= 3;
				_scrolldir = -3;
			}
			_scrolldelay = 0;
			_scrollbar.addEventListener(Event.ENTER_FRAME, onScrollBarFrame, false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_UP, onScrollBarUp, false, 0, true);
		}
		private function onScrollBarFrame(e:Event):void{
			_scrolldelay++;
			if(_scrolldelay>10){
				_scrolldelay = 9;
				if((_scrolldir<0 && _scroller.y>mouseY)||(_scrolldir>0 && _scroller.y+_scroller.height<mouseY)){
					_traceField.scrollV += _scrolldir;
				}
			}
		}
		private function onScrollBarUp(e:Event):void{
			_scrollbar.removeEventListener(Event.ENTER_FRAME, onScrollBarFrame);
			stage.removeEventListener(MouseEvent.MOUSE_UP, onScrollBarUp);
		}
		override public function set width(n:Number):void{
			_lockScrollUpdate = true;
			super.width = n;
			_traceField.width = n-4;
			_menuField.width = n;
			_commandField.width = width-15-_commandField.x;
			_commandBackground.width = n;
			
			_bottomLine.graphics.clear();
			_bottomLine.graphics.lineStyle(1, style.bottomLineColor);
			_bottomLine.graphics.moveTo(10, -1);
			_bottomLine.graphics.lineTo(n-10, -1);
			_scroller.x = n;
			_scrollbar.x = n;
			onUpdateCommandLineScope();
			_atBottom = true;
			_needUpdateMenu = true;
			_needUpdateTrace = true;
			_lockScrollUpdate = false;
		}
		override public function set height(n:Number):void{
			_lockScrollUpdate = true;
			super.height = n;
			var minimize:Boolean = false;
			if(n<(_commandField.visible?42:24)){
				minimize = true;
			}
			if(_isMinimised != minimize){
				registerDragger(_menuField, minimize);
				registerDragger(_traceField, !minimize);
				_isMinimised = minimize;
			}
			_menuField.visible = !minimize;
			_traceField.y = minimize?0:12;
			_traceField.height = n-(_commandField.visible?16:0)-(minimize?0:12);
			var cmdy:Number = n-18;
			_commandField.y = cmdy;
			_commandPrefx.y = cmdy;
			_commandBackground.y = cmdy;
			_bottomLine.y = _commandField.visible?cmdy:n;
			//
			var sbh:Number = (_bottomLine.y-(_commandField.visible?0:10))-_scrollbar.y;
			_scrollbar.graphics.clear();
			_scrollbar.graphics.beginFill(style.panelScalerColor, 0.7);
			_scrollbar.graphics.drawRect(-5, 0, 5, 5);
			_scrollbar.graphics.drawRect(-5, sbh-5, 5, 5);
			_scrollbar.graphics.beginFill(style.panelScalerColor, 0.25);
			_scrollbar.graphics.drawRect(-5, 5, 5, sbh-10);
			_scrollbar.graphics.endFill();
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
			if(!master.channelsPanel){
				str += getChannelsLink(true);
			}
			str += "<menu>[ <b>";
			str += doActive("<a href=\"event:fps\">F</a>", master.fpsMonitor>0);
			str += doActive(" <a href=\"event:mm\">M</a>", master.memoryMonitor>0);
			if(master.commandLineAllowed){
				str += doActive(" <a href=\"event:command\">CL</a>", commandLine);
			}
			if(!master.remote){
				str += doActive(" <a href=\"event:roller\">Ro</a>", master.displayRoller);
				str += doActive(" <a href=\"event:ruler\">RL</a>", master.panels.rulerActive);
			}
			str += " ¦</b>";
			for each(var link:String in _extraMenuKeys){
				str += " <a href=\"event:"+link+"\">"+link+"</a>";
			}
			if(_canUseTrace){
				str += doActive(" <a href=\"event:trace\">T</a>", master.tracing);
			}
			str += " <a href=\"event:copy\">Cc</a>";
			str += " <a href=\"event:priority\">P"+master.priority+"</a>";
			str += doActive(" <a href=\"event:pause\">P</a>", master.paused);
			str += " <a href=\"event:clear\">C</a> <a href=\"event:close\">X</a>";
			
			str += " ]</menu> </w></r>";
			_menuField.htmlText = str;
			_menuField.scrollH = _menuField.maxScrollH;
		}
		public function getChannelsLink(limited:Boolean = false):String{
			var str:String = "<chs>";
			var len:int = _channels.length;
			if(limited && len>CHANNELS_IN_MENU) len = CHANNELS_IN_MENU;
			for(var ci:int = 0; ci<len;  ci++){
				var channel:String = _channels[ci];
				var channelTxt:String = (master.viewingChannels.indexOf(channel)>=0) ? "<ch><b>"+channel+"</b></ch>" : channel;
				str += "<a href=\"event:channel_"+channel+"\">["+channelTxt+"]</a> ";
			}
			if(limited){
				str += "<ch><a href=\"event:channels\"><b>"+(_channels.length>len?"...":"")+"</b>^^ </a></ch>";
			}
			str += "</chs> ";
			return str;
		}
		private function doActive(str:String, b:Boolean):String{
			if(b) return "<y>"+str+"</y>";
			return str;
		}
		public function onMenuRollOver(e:TextEvent, src:AbstractPanel = null):void{
			if(src==null) src = this;
			var txt:String = e.text?e.text.replace("event:",""):"";
			if(topMenuRollOver!=null) {
				var t:String = topMenuRollOver(txt);
				if(t) {
					master.panels.tooltip(t, src);
					return;
				}
			}
			if(txt == "channel_"+Console.GLOBAL_CHANNEL){
				txt = TOOLTIPS["viewall"];
			}else if(txt == "channel_"+Console.DEFAULT_CHANNEL) {
				txt = TOOLTIPS["defaultch"];
			}else if(txt == "channel_"+ Console.CONSOLE_CHANNEL) {
				txt = TOOLTIPS["consolech"];
			}else if(txt == "channel_"+ Console.FILTERED_CHANNEL) {
				txt = TOOLTIPS["filterch"]+"::*"+master.filterText+"*";
			}else if(txt.indexOf("channel_")==0) {
				txt = TOOLTIPS["channel"];
			}else if(txt == "pause"){
				if(master.paused)
					txt = TOOLTIPS["resume"];
				else
					txt = TOOLTIPS["pause"];
			}else if(txt == "copy"){
				txt = TOOLTIPS["copy"];
			}else if(txt == "close" && src == this){
				txt = TOOLTIPS["closemain"];
			}else{
				txt = TOOLTIPS[txt];
			}
			master.panels.tooltip(txt, src);
		}
		private function linkHandler(e:TextEvent):void{
			_menuField.setSelection(0, 0);
			stopDrag();
			if(topMenuClick!=null && topMenuClick(e.text)) return;
			if(e.text == "pause"){
				if(master.paused){
					master.paused = false;
					master.panels.tooltip(TOOLTIPS["pause"], this);
				}else{
					master.paused = true;
					master.panels.tooltip(TOOLTIPS["resume"], this);
				}
			}else if(e.text == "trace"){
				master.tracing = !master.tracing;
				if(master.tracing){
					master.report("Tracing turned [<b>On</b>]",-1);
				}else{
					master.report("Tracing turned [<b>Off</b>]",-1);
				}
			}else if(e.text == "close"){
				master.panels.tooltip();
				visible = false;
				//dispatchEvent(new Event(AbstractPanel.CLOSED));
			}else if(e.text == "channels"){
				master.channelsPanel = !master.channelsPanel;
			}else if(e.text == "fps"){
				master.fpsMonitor = !master.fpsMonitor;
			}else if(e.text == "priority"){
				if(master.priority<10){
					master.priority++;
				}else{
					master.priority = 0;
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
				master.runCommand("/remap 0"+Console.MAPPING_SPLITTER+e.text.substring(6));
				//master.cl.reMap(e.text.substring(6), stage);
			}
			_menuField.setSelection(0, 0);
			e.stopPropagation();
		}
		public function onChannelPressed(chn:String):void{
			var current:Array = master.viewingChannels.concat();
			if(_shift && master.viewingChannel != Console.GLOBAL_CHANNEL && chn != Console.GLOBAL_CHANNEL){
				var ind:int = current.indexOf(chn);
				if(ind>=0){
					current.splice(ind,1);
					if(current.length == 0){
						current.push(Console.GLOBAL_CHANNEL);
					}
				}else{
					current.push(chn);
				}
				master.viewingChannels = current;
			}else{
				master.viewingChannel = chn;
			}
		}
		//
		// COMMAND LINE
		//
		private function commandKeyDown(e:KeyboardEvent):void{
			e.stopPropagation();
		}
		private function commandKeyUp(e:KeyboardEvent):void{
			if(!master.enabled){
				return;
			}
			if( e.keyCode == 13){
				if(_enteringLogin){
					master.sendLogin(_commandField.text);
					_commandField.text = "";
					requestLogin(false);
				}else{
					master.runCommand(_commandField.text);
					_commandsHistory.unshift(_commandField.text);
					_commandsInd = -1;
					_commandField.text = "";
					// maximum 20 commands history
					if(_commandsHistory.length>20){
						_commandsHistory.splice(20);
					}
				}
			}else if( e.keyCode == 38 ){
				// if its back key for first time, store the current key
				if(_commandField.text && _commandsInd<0){
					_commandsHistory.unshift(_commandField.text);
					_commandsInd++;
				}
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
		private function onUpdateCommandLineScope(e:Event=null):void{
			if(!master.remote) updateCLScope(master.cl.scopeString);
		}
		public function updateCLScope(str:String):void{
			if(_enteringLogin) {
				_enteringLogin = false;
				requestLogin(false);
			}
			_commandPrefx.autoSize = TextFieldAutoSize.LEFT;
			_commandPrefx.htmlText = "<w><p1>"+str+":</p1></w>";
			var w:Number = width-48;
			if(_commandPrefx.width > 120 || _commandPrefx.width > w){
				_commandPrefx.autoSize = TextFieldAutoSize.NONE;
				_commandPrefx.width = w>120?120:w;
				_commandPrefx.scrollH = _commandPrefx.maxScrollH;
			}
			_commandField.x = _commandPrefx.width+2;
			_commandField.width = width-15-_commandField.x;
		}
		public function set commandLine (b:Boolean):void{
			if(b && master.commandLineAllowed>0){
				_commandField.visible = true;
				_commandPrefx.visible = true;
				_commandBackground.visible = true;
			}else{
				_commandField.visible = false;
				_commandPrefx.visible = false;
				_commandBackground.visible = false;
			}
			this.height = height;
		}
		public function get commandLine ():Boolean{
			return _commandField.visible;
		}
	}
}
