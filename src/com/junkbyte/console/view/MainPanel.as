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
package com.junkbyte.console.view 
{
	import com.junkbyte.console.core.ConsoleCentral;
	import com.junkbyte.console.core.LogReferences;
	import com.junkbyte.console.core.Logs;
	import com.junkbyte.console.core.Remoting;
	import com.junkbyte.console.vos.Log;

	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Rectangle;
	import flash.system.Security;
	import flash.system.SecurityPanel;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;

	public class MainPanel extends ConsolePanel {
		
		public static const NAME:String = "mainPanel";
		public static const FILTER_PRIORITY_CHANGED:String = "filterPriorityChanged";
		public static const COMMAND_LINE_VISIBLITY_CHANGED:String = "commandLineVisibilityChanged";
		
		private static const CL_HISTORY:String = "clhistory";
		private static const VIEWING_CH_HISTORY:String = "viewingChannels";
		private static const IGNORED_CH_HISTORY:String = "ignoredChannels";
		private static const PRIORITY_HISTORY:String = "priority";
		
		private var _menu:MainPanelMenu;
		private var _traceField:TextField;
		private var _cmdPrefx:TextField;
		private var _cmdField:TextField;
		private var _hintField:TextField;
		private var _cmdBG:Shape;
		private var _bottomLine:Shape;
		private var _shift:Boolean;
		private var _ctrl:Boolean;
		private var _alt:Boolean;
		
		private var _scroll:Sprite;
		private var _scroller:Sprite;
		private var _scrolldelay:uint;
		private var _scrolldir:int;
		private var _scrolling:Boolean;
		private var _scrollHeight:Number;
		private var _selectionStart:int;
		private var _selectionEnd:int;
		
		private var _viewingChannels:Array;
		private var _ignoredChannels:Array;
		private var _extraMenus:Object = new Object();
		private var _cmdsInd:int = -1;
		private var _priority:uint;
		private var _filterText:String;
		private var _filterRegExp:RegExp;
		private var _clScope:String = "";
		
		private var _needUpdateMenu:Boolean;
		private var _needUpdateTrace:Boolean;
		private var _lockScrollUpdate:Boolean;
		private var _atBottom:Boolean = true;
		private var _enteringLogin:Boolean;
		
		private var _hint:String;
		
		private var _cmdsHistory:Array;
		
		public function MainPanel(m:ConsoleCentral) {
			super(m);
		}
		
		public function start():void
		{
			var fsize:int = style.menuFontSize;
			
			central.cl.addCLCmd("filter", setFilterText, "Filter console logs to matching string. When done, click on the * (global channel) at top.", true);
			central.cl.addCLCmd("filterexp", setFilterRegExp, "Filter console logs to matching regular expression", true);
			central.cl.addCLCmd("clearhistory", clearCommandLineHistory, "Clear history of commands you have entered.", true);
			
			name = NAME;
			minWidth = 50;
			minHeight = 18;
			
			_traceField = makeTF("traceField");
			_traceField.wordWrap = true;
			_traceField.multiline = true;
			_traceField.y = fsize;
			_traceField.addEventListener(Event.SCROLL, onTraceScroll);
			addChild(_traceField);
			//
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
			_cmdField.addEventListener(KeyboardEvent.KEY_DOWN, commandKeyDown);
			_cmdField.addEventListener(KeyboardEvent.KEY_UP, commandKeyUp);
			_cmdField.addEventListener(FocusEvent.FOCUS_IN, updateCmdHint);
			_cmdField.addEventListener(FocusEvent.FOCUS_OUT, onCmdFocusOut);
			_cmdField.defaultTextFormat = tf;
			addChild(_cmdField);
			
			_hintField = makeTF("hintField", true);
			_hintField.mouseEnabled = false;
			_hintField.x = _cmdField.x;
			_hintField.autoSize = TextFieldAutoSize.LEFT;
			addChild(_hintField);
			setHints();
			
			tf.color = style.commandLineColor;
			_cmdPrefx = new TextField();
			_cmdPrefx.name = "commandPrefx";
			_cmdPrefx.type  = TextFieldType.DYNAMIC;
			_cmdPrefx.x = 2;
			_cmdPrefx.height = fsize+6;
			_cmdPrefx.selectable = false;
			_cmdPrefx.defaultTextFormat = tf;
			_cmdPrefx.addEventListener(MouseEvent.MOUSE_DOWN, onCmdPrefMouseDown);
			_cmdPrefx.addEventListener(MouseEvent.MOUSE_MOVE, onCmdPrefRollOverOut);
			_cmdPrefx.addEventListener(MouseEvent.ROLL_OUT, onCmdPrefRollOverOut);
			addChild(_cmdPrefx);
			//
			_bottomLine = new Shape();
			_bottomLine.name = "blinkLine";
			_bottomLine.alpha = 0.2;
			addChild(_bottomLine);
			//
			_scroll = new Sprite();
			_scroll.name = "scroller";
			_scroll.tabEnabled = false;
			_scroll.y = fsize+4;
			_scroll.buttonMode = true;
			_scroll.addEventListener(MouseEvent.MOUSE_DOWN, onScrollbarDown, false, 0, true);
			_scroller = new Sprite();
			_scroller.name = "scrollbar";
			_scroller.tabEnabled = false;
			_scroller.y = 5;
			_scroller.graphics.beginFill(style.controlColor, 1);
			_scroller.graphics.drawRect(-5, 0, 5, 30);
			_scroller.graphics.beginFill(0, 0);
			_scroller.graphics.drawRect(-10, 0, 10, 30);
			_scroller.graphics.endFill();
			_scroller.addEventListener(MouseEvent.MOUSE_DOWN, onScrollerDown, false, 0, true);
			_scroll.addChild(_scroller);
			addChild(_scroll);
			//
			_cmdField.visible = false;
			_cmdPrefx.visible = false;
			_cmdBG.visible = false;
			updateCLScope("");
			//
			_menu = new MainPanelMenu();
			central.registerModule(_menu);
			_menu.textField.y = -2;
			_menu.addEventListener(Event.CHANGE, onMenuChanged);
			//registerTFRoller(_menu, onMenuRollOver);
			addChild(_menu.textField);
			//
			init(640,100,true);
			registerDragger(_menu.textField);
			//
			if(central.so[CL_HISTORY] is Array){
				_cmdsHistory = central.so[CL_HISTORY];
			}else{
				central.so[CL_HISTORY] = _cmdsHistory = new Array();
			}
			//
			if(config.rememberFilterSettings && central.so[VIEWING_CH_HISTORY] is Array){
				_viewingChannels = central.so[VIEWING_CH_HISTORY];
			}else{
				central.so[VIEWING_CH_HISTORY] = _viewingChannels = new Array();
			}
			if(config.rememberFilterSettings && central.so[IGNORED_CH_HISTORY] is Array){
				_ignoredChannels = central.so[IGNORED_CH_HISTORY];
			}
			if(_viewingChannels.length > 0 || _ignoredChannels == null){
				central.so[IGNORED_CH_HISTORY] = _ignoredChannels = new Array();
			}
			if(config.rememberFilterSettings && central.so[PRIORITY_HISTORY] is uint)
			{
				_priority = central.so[PRIORITY_HISTORY];
			}
			//
			addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel, false, 0, true);
			addEventListener(TextEvent.LINK, linkHandler, false, 0, true);
			addEventListener(Event.ADDED_TO_STAGE, stageAddedHandle, false, 0, true);
			addEventListener(Event.REMOVED_FROM_STAGE, stageRemovedHandle, false, 0, true);
		}
		public function addMenu(key:String, f:Function, args:Array, rollover:String):void{
			if(key){
				key = key.replace(/[^\w]*/g, "");
				if(f == null){
					delete _extraMenus[key];
				}else{
					// used to use ExternalMenu Class, but that adds extra 0.3kb.
					_extraMenus[key] = new Array(f, args, rollover);
				}
				_needUpdateMenu = true;
			}else central.report("ERROR: Invalid add menu params.", 9);
		}
		private function stageAddedHandle(e:Event=null):void{
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown, true, 0, true);
			stage.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler, false, 0, true);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler, false, 0, true);
		}
		private function stageRemovedHandle(e:Event=null):void{
			stage.removeEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown, true);
			stage.removeEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
		}

		private function onStageMouseDown(e : MouseEvent) : void {
			_shift = e.shiftKey;
			_ctrl = e.ctrlKey;
			_alt = e.altKey;
		}
		private function onMouseWheel(e : MouseEvent) : void {
			if(_shift){
				var s:int = central.config.style.traceFontSize + (e.delta>0?1:-1);
				if(s > 10 && s < 20){
					central.config.style.traceFontSize = s;
					central.config.style.updateStyleSheet();
					updateToBottom();
					e.stopPropagation();
				}
			}
		}
		private function onCmdPrefRollOverOut(e : MouseEvent) : void {
			central.display.tooltip(e.type==MouseEvent.MOUSE_MOVE?"Current scope::(CommandLine)":"", this);
		}
		private function onCmdPrefMouseDown(e : MouseEvent) : void {
			try{
				stage.focus = _cmdField;
				setCLSelectionAtEnd();
			} catch(err:Error) {}
		}
		private function keyDownHandler(e:KeyboardEvent):void{
			if(e.keyCode == Keyboard.SHIFT){
				_shift = true;
			}
			if (e.keyCode == Keyboard.CONTROL) {
				_ctrl = true;
			}
			if (e.keyCode == 18) { //Keyboard.ALTERNATE not supported in flash 9
				_alt = true;
			}
		}
		private function keyUpHandler(e:KeyboardEvent):void{
			if(e.keyCode == Keyboard.SHIFT) _shift = false;
			else if(e.keyCode == Keyboard.CONTROL) _ctrl = false;
			else if (e.keyCode == 18) _alt = false;
			
			if((e.keyCode == Keyboard.TAB || e.keyCode == Keyboard.ENTER) && parent.visible && visible && _cmdField.visible){
				try{
					stage.focus = _cmdField;
					setCLSelectionAtEnd();
				} catch(err:Error) {}
			}
		}
		
		public function requestLogin(on:Boolean = true):void{
			var ct:ColorTransform = new ColorTransform();
			if(on){
				central.console.commandLine = true;
				central.report("//", -2);
				central.report("// <b>Enter remoting password</b> in CommandLine below...", -2);
				updateCLScope("Password");
				ct.color = style.controlColor;
				_cmdBG.transform.colorTransform = ct;
				_traceField.transform.colorTransform = new ColorTransform(0.7,0.7,0.7);
			}else{
				updateCLScope("");
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
			if (style.showCommandLineScope) {
				if(_clScope != central.cl.scopeString){
					_clScope = central.cl.scopeString;
					updateCLScope(_clScope);
				}
			}else if(_clScope != null){
				_clScope = "";
				updateCLScope("");
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
		private function _updateTraces(onlyBottom:Boolean = false):void{
			if(_atBottom) {
				updateBottom(); 
			}else if(!onlyBottom){
				updateFull();
			}
			if(_selectionStart != _selectionEnd){
				if(_atBottom){
					_traceField.setSelection(_traceField.text.length-_selectionStart, _traceField.text.length-_selectionEnd);
				}else{
					_traceField.setSelection(_traceField.text.length-_selectionEnd, _traceField.text.length-_selectionStart);
				}
				_selectionEnd = -1;
				_selectionStart = -1;
			}
		}
		private function updateFull():void{
			var str:String = "";
			var line:Log = central.logs.last;
			var showch:Boolean = _viewingChannels.length != 1;
			while(line){
				if(lineShouldShow(line)){
					str = makeLine(line, showch)+str;
				}
				line = line.prev;
			}
			_lockScrollUpdate = true;
			_traceField.htmlText = str;
			_lockScrollUpdate = false;
			updateScroller();
		}
		public function setPaused(b:Boolean):void{
			if(b && _atBottom){
				_atBottom = false;
				_updateTraces();
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
			
			var line:Log = central.logs.last;
			var showch:Boolean = _viewingChannels.length != 1;
			while(line){
				if(lineShouldShow(line)){
					var numlines:int = Math.ceil(line.text.length/ maxchars);
					if(line.html || linesLeft >= numlines ){
						lines.push(makeLine(line, showch));
					}else{
						line = line.clone();
						line.text = line.text.substring(Math.max(0,line.text.length-(maxchars*linesLeft)));
						lines.push(makeLine(line, showch));
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
		public function lineShouldShow(line:Log):Boolean{
			return (
				(
					chShouldShow(line.ch)
			 		|| (_filterText && _viewingChannels.indexOf(Logs.FILTER_CHANNEL) >= 0 && line.text.toLowerCase().indexOf(_filterText)>=0 )
			 		|| (_filterRegExp && _viewingChannels.indexOf(Logs.FILTER_CHANNEL)>=0 && line.text.search(_filterRegExp)>=0 )
			 	) 
			 	&& ( _priority == 0 || line.priority >= _priority)
			);
		}
		private function chShouldShow(ch:String):Boolean{
			return  ((_viewingChannels.length == 0 || _viewingChannels.indexOf(ch)>=0)
					&&
					 (_ignoredChannels.length == 0 || _ignoredChannels.indexOf(ch)<0));
		}
		public function get reportChannel():String{
			return _viewingChannels.length == 1?_viewingChannels[0]:Logs.CONSOLE_CHANNEL;
		}
		/*public function get viewingChannels():Array{
			return _viewingChannels;
		}*/
		public function setViewingChannels(...channels:Array):void{
			var a:Array = new Array();
			for each(var item:Object in channels) a.push(ConsoleCentral.MakeChannelName(item));
			
			if(_viewingChannels[0] == Logs.INSPECTING_CHANNEL && (!a || a[0] != _viewingChannels[0])){
				central.refs.exitFocus();
			}
			_ignoredChannels.splice(0);
			_viewingChannels.splice(0);
			if(a.indexOf(Logs.GLOBAL_CHANNEL) < 0 && a.indexOf(null) < 0){
				for each(var ch:String in a) _viewingChannels.push(ch);
			}
			updateToBottom();
			central.display.updateMenu();
		}
		public function setIgnoredChannels(...channels:Array):void{
			var a:Array = new Array();
			for each(var item:Object in channels) a.push(ConsoleCentral.MakeChannelName(item));
			
			if(_viewingChannels[0] == Logs.INSPECTING_CHANNEL){
				central.refs.exitFocus();
			}
			
			_ignoredChannels.splice(0);
			_viewingChannels.splice(0);
			if(a.indexOf(Logs.GLOBAL_CHANNEL) < 0 && a.indexOf(null) < 0){
				for each(var ch:String in a) _ignoredChannels.push(ch);
			}
			updateToBottom();
			central.display.updateMenu();
		}
		//
		private function setFilterText(str:String = ""):void{
			if(str){
				_filterRegExp = null;
				_filterText = LogReferences.EscHTML(str.toLowerCase());
				startFilter();
			}else{
				endFilter();
			}
		}
		private function setFilterRegExp(expstr:String = ""):void{
			if(expstr){
				_filterText = null;
				_filterRegExp = new RegExp(LogReferences.EscHTML(expstr), "gi");
				startFilter();
			}else{
				endFilter();
			}
		}
		private function startFilter():void{
			central.console.clear(Logs.FILTER_CHANNEL);
			central.logs.addChannel(Logs.FILTER_CHANNEL);
			setViewingChannels(Logs.FILTER_CHANNEL);
		}
		private function endFilter():void{
			_filterRegExp = null;
			_filterText = null;
			if(_viewingChannels.length == 1 && _viewingChannels[0] == Logs.FILTER_CHANNEL){
				setViewingChannels(Logs.GLOBAL_CHANNEL);
			}
		}
		private function makeLine(line:Log, showch:Boolean):String{
			var str:String = "";
			var txt:String = line.text;
			if(showch && line.ch != Logs.DEFAULT_CHANNEL){
				txt = "[<a href=\"event:channel_"+line.ch+"\">"+line.ch+"</a>] "+txt;
			}
			var index:int;
			if(_filterRegExp){
				// need to look into every match to make sure there no half way HTML tags and not inside the HTML tags it self in the match.
				_filterRegExp.lastIndex = 0;
				var result:Object = _filterRegExp.exec(txt);
				while (result != null) {
					index = result.index;
					var match:String = result[0];
					if(match.search("<|>")>=0){
						_filterRegExp.lastIndex -= match.length-match.search("<|>");
					}else if(txt.lastIndexOf("<", index)<=txt.lastIndexOf(">", index)){
						txt = txt.substring(0, index)+"<u>"+txt.substring(index, index+match.length)+"</u>"+txt.substring(index+match.length);
						_filterRegExp.lastIndex+=7; // need to add to satisfy the fact that we added <u> and </u>
					}
					result = _filterRegExp.exec(txt);
				}
			}else if(_filterText){
				// could have been simple if txt.replace replaces every match.
				var lowercase:String = txt.toLowerCase();
				index = lowercase.lastIndexOf(_filterText);
				while(index>=0){
					txt = txt.substring(0, index)+"<u>"+txt.substring(index, index+_filterText.length)+"</u>"+txt.substring(index+_filterText.length);
					index = lowercase.lastIndexOf(_filterText, index-2);
				}
			}
			var ptag:String = "p"+line.priority;
			str += "<p><"+ptag+">" + txt + "</"+ptag+"></p>";
			return str;
		}
		//
		// START OF SCROLL BAR STUFF
		//
		private function onTraceScroll(e:Event = null):void{
			if(_lockScrollUpdate || _shift) return;
			var atbottom:Boolean = _traceField.scrollV >= _traceField.maxScrollV;
			if(!central.paused && _atBottom !=atbottom){
				var diff:int = _traceField.maxScrollV-_traceField.scrollV;
				_selectionStart = _traceField.text.length-_traceField.selectionBeginIndex;
				_selectionEnd = _traceField.text.length-_traceField.selectionEndIndex;
				_atBottom = atbottom;
				_updateTraces();
				_traceField.scrollV = _traceField.maxScrollV-diff;
			}
			updateScroller();
		}
		private function updateScroller():void{
			if(_traceField.maxScrollV <= 1){
				_scroll.visible = false;
			}else{
				_scroll.visible = true;
				if(_atBottom) {
					scrollPercent = 1;
				}else{
					scrollPercent = (_traceField.scrollV-1)/(_traceField.maxScrollV-1);
				}
			}
		}
		private function onScrollbarDown(e:MouseEvent):void{
			if((_scroller.visible && _scroller.mouseY>0) || (!_scroller.visible && _scroll.mouseY>_scrollHeight/2)) {
				_scrolldir = 3;
			}else {
				_scrolldir = -3;
			}
			_traceField.scrollV += _scrolldir;
			_scrolldelay = 0;
			addEventListener(Event.ENTER_FRAME, onScrollBarFrame, false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_UP, onScrollBarUp, false, 0, true);
		}
		private function onScrollBarFrame(e:Event):void{
			_scrolldelay++;
			if(_scrolldelay>10){
				_scrolldelay = 9;
				if((_scrolldir<0 && _scroller.y>_scroll.mouseY)||(_scrolldir>0 && _scroller.y+_scroller.height<_scroll.mouseY)){
					_traceField.scrollV += _scrolldir;
				}
			}
		}
		private function onScrollBarUp(e:Event):void{
			removeEventListener(Event.ENTER_FRAME, onScrollBarFrame);
			stage.removeEventListener(MouseEvent.MOUSE_UP, onScrollBarUp);
		}
		//
		//
		private function get scrollPercent():Number{
			return (_scroller.y-5)/(_scrollHeight-40);
		}
		private function set scrollPercent(per:Number):void{
			_scroller.y = 5+((_scrollHeight-40)*per);
		}
		private function onScrollerDown(e:MouseEvent):void{
			_scrolling = true;
			
			if(!central.paused && _atBottom){
				_atBottom = false;
				var p:Number = scrollPercent;
				_updateTraces();
				scrollPercent = p;
			}
			
			_scroller.startDrag(false, new Rectangle(0,5, 0, (_scrollHeight-40)));
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onScrollerMove, false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_UP, onScrollerUp, false, 0, true);
			e.stopPropagation();
		}
		private function onScrollerMove(e:MouseEvent):void{
			_lockScrollUpdate = true;
			_traceField.scrollV = Math.round((scrollPercent*(_traceField.maxScrollV-1))+1);
			_lockScrollUpdate = false;
		}
		private function onScrollerUp(e:MouseEvent):void{
			_scroller.stopDrag();
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onScrollerMove);
			stage.removeEventListener(MouseEvent.MOUSE_UP, onScrollerUp);
			_scrolling = false;
			onTraceScroll();
		}
		//
		// END OF SCROLL BAR STUFF
		//
		override public function set width(n:Number):void{
			_lockScrollUpdate = true;
			super.width = n;
			_menu.textField.width = n-6;
			_traceField.width = n-4;
			_cmdField.width = width-15-_cmdField.x;
			_cmdBG.width = n;
			
			_bottomLine.graphics.clear();
			_bottomLine.graphics.lineStyle(1, style.controlColor);
			_bottomLine.graphics.moveTo(10, -1);
			_bottomLine.graphics.lineTo(n-10, -1);
			_scroll.x = n;
			_atBottom = true;
			updateCLSize();
			_needUpdateMenu = true;
			_needUpdateTrace = true;
			_lockScrollUpdate = false;
		}
		override public function set height(n:Number):void{
			_lockScrollUpdate = true;
			var fsize:int = style.menuFontSize;
			var msize:Number = fsize+6+style.traceFontSize;
			if(height != n){
				_menu.mini = n < (_cmdField.visible?(msize+fsize+4):msize);
			}
			super.height = n;
			var mini:Boolean = _menu.mini || !style.topMenu;
			updateTraceFHeight();
			var cmdy:Number = n-(fsize+6);
			_cmdField.y = cmdy;
			_cmdPrefx.y = cmdy;
			_hintField.y = _cmdField.y-_hintField.height;
			_cmdBG.y = cmdy;
			_bottomLine.y = _cmdField.visible?cmdy:n;
			//
			_scroll.y = mini?6:fsize+4;
			_scrollHeight = (_bottomLine.y-(_cmdField.visible?0:10))-_scroll.y;
			_scroller.visible = _scrollHeight>40;
			_scroll.graphics.clear();
			if(_scrollHeight>=10){
				_scroll.graphics.beginFill(style.controlColor, 0.7);
				_scroll.graphics.drawRect(-5, 0, 5, 5);
				_scroll.graphics.drawRect(-5, _scrollHeight-5, 5, 5);
				_scroll.graphics.beginFill(style.controlColor, 0.25);
				_scroll.graphics.drawRect(-5, 5, 5, _scrollHeight-10);
				_scroll.graphics.beginFill(0, 0);
				_scroll.graphics.drawRect(-10, 10, 10, _scrollHeight-10);
				_scroll.graphics.endFill();
			}
			//
			_atBottom = true;
			_needUpdateTrace = true;
			_lockScrollUpdate = false;
		}
		private function updateTraceFHeight():void{
			var mini:Boolean = _menu.mini || !style.topMenu;
			_traceField.y = mini?0:(_menu.textField.y+_menu.textField.height-6);
			_traceField.height = height-(_cmdField.visible?(style.menuFontSize+4):0)-_traceField.y;
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
			_menu.update();
		}
		private function onMenuChanged(e:Event):void{
			updateTraceFHeight();
		}
		public function getChannelsLink(limited:Boolean = false):String{
			var str:String = "<chs>";
			var channels:Array = central.logs.getChannels();
			var len:int = channels.length;
			if(limited && len>style.maxChannelsInMenu) len = style.maxChannelsInMenu;
			var filtering:Boolean = _viewingChannels.length > 0 || _ignoredChannels.length > 0;
			for(var i:int = 0; i<len;  i++){
				var channel:String = channels[i];
				var channelTxt:String = ((!filtering && i == 0) || (filtering && i != 0 && chShouldShow(channel))) ? "<ch><b>"+channel+"</b></ch>" : channel;
				str += "<a href=\"event:channel_"+channel+"\">["+channelTxt+"]</a> ";
			}
			if(limited){
				str += "<ch><a href=\"event:channels\"><b>"+(channels.length>len?"...":"")+"</b>^^ </a></ch>";
			}
			str += "</chs> ";
			return str;
		}
		public function onMenuRollOver(e:TextEvent, src:ConsolePanel = null):void{
			if(src==null) src = this;
			var txt:String = e.text?e.text.replace("event:",""):"";
			if(txt == "channel_"+Logs.GLOBAL_CHANNEL){
				txt = "View all channels";
			}else if(txt == "channel_"+Logs.DEFAULT_CHANNEL) {
				txt = "Default channel::Logs with no channel";
			}else if(txt == "channel_"+ Logs.CONSOLE_CHANNEL) {
				txt = "Console's channel::Logs generated from Console";
			}else if(txt == "channel_"+ Logs.FILTER_CHANNEL) {
				txt = _filterRegExp?String(_filterRegExp):_filterText;
				txt = "Filtering channel"+"::*"+txt+"*";
			}else if(txt == "channel_"+Logs.INSPECTING_CHANNEL) {
				txt = "Inspecting channel";
			}else if(txt.indexOf("channel_")==0) {
				txt = "Change channel::shift: select multiple\nctrl: ignore channel";
			}else if(txt == "pause"){
				if(central.paused) txt = "Resume updates";
				else txt = "Pause updates";
			}else if(txt == "close" && src == this){
				txt = "Close::Type password to show again";
			}else if(txt.indexOf("external_")==0){
				var menu:Array = _extraMenus[txt.substring(9)];
				if(menu) txt = menu[2];
			}else{
				var obj:Object = {
					fps:"Frames Per Second",
					mm:"Memory Monitor",
					channels:"Expand channels",
					close:"Close"
				};
				txt = obj[txt];
			}
			central.display.tooltip(txt, src);
		}
		private function linkHandler(e:TextEvent):void{
			_menu.textField.setSelection(0, 0);
			stopDrag();
			var t:String = e.text;
			if(t == "channels"){
				central.display.channelsPanel = !central.display.channelsPanel;
			}else if(t == "fps"){
				central.console.fpsMonitor = !central.console.fpsMonitor;
			}else if(t == "priority"){
				incPriority(_shift);
			}else if(t == "mm"){
				central.console.memoryMonitor = !central.console.memoryMonitor;
			}else if(t == "settings"){
				central.report("A new window should open in browser. If not, try searching for 'Flash Player Global Security Settings panel' online :)", -1);
				Security.showSettings(SecurityPanel.SETTINGS_MANAGER);
			}else if(t == "remote"){
				central.remoter.remoting = Remoting.RECIEVER;
			}else if(t.indexOf("ref")==0){
				central.refs.handleRefEvent(t);
			}else if(t.indexOf("channel_")==0){
				onChannelPressed(t.substring(8));
			}else if(t.indexOf("cl_")==0){
				var ind:int = t.indexOf("_", 3);
				central.cl.handleScopeEvent(uint(t.substring(3, ind<0?t.length:ind)));
				if(ind>=0){
					_cmdField.text = t.substring(ind+1);
				}
			}else if(t.indexOf("external_")==0){
				var menu:Array = _extraMenus[t.substring(9)];
				if(menu) menu[0].apply(null, menu[1]);
			}
			_menu.textField.setSelection(0, 0);
			e.stopPropagation();
		}
		override public function close():void{
			central.display.tooltip();
			visible = false;
			dispatchEvent(new Event(Event.CLOSE));
		}
		public function toggleTopMenu():void
		{
			if(_menu.mini){
				showTopMenu();
			}else{
				hideTopMenu();
			}
		}
		public function hideTopMenu():void
		{
			central.display.tooltip();
			_menu.mini = true;
			central.config.style.topMenu = false;
			height = height;
			updateMenu();
		}
		public function showTopMenu():void
		{
			central.display.tooltip();
			_menu.mini = false;
			central.config.style.topMenu = true;
			height = height;
			updateMenu();
		}
		public function onChannelPressed(chn:String):void{
			var current:Array;
			if(_ctrl && chn != Logs.GLOBAL_CHANNEL){
				current = toggleCHList(_ignoredChannels, chn);
				setIgnoredChannels.apply(this, current);
			}
			else if(_shift && chn != Logs.GLOBAL_CHANNEL && _viewingChannels[0] != Logs.INSPECTING_CHANNEL){
				current = toggleCHList(_viewingChannels, chn);
				setViewingChannels.apply(this, current);
			}else{
				central.console.setViewingChannels(chn);
			}
		}
		private function toggleCHList(current:Array, chn:String):Array{
			current = current.concat();
			var ind:int = current.indexOf(chn);
			if(ind>=0){
				current.splice(ind,1);
				if(current.length == 0){
					current.push(Logs.GLOBAL_CHANNEL);
				}
			}else{
				current.push(chn);
			}
			return current;
		}
		public function set priority(p:uint):void{
			_priority = p;
			central.so[PRIORITY_HISTORY] = _priority;
			updateToBottom();
			updateMenu();
			dispatchEvent(new Event(FILTER_PRIORITY_CHANGED));
		}
		public function get priority():uint{
			return _priority;
		}
		//
		public function incPriority(down:Boolean):void{
			var top:uint = 10;
			var bottom:uint;
			var line:Log = central.logs.last;
			var p:int = _priority;
			_priority = 0;
			var i:uint = 32000; // just for crash safety, it wont look more than 32000 lines.
			while(line && i>0){
				i--;
				if(lineShouldShow(line)){
					if(line.priority > p && top>line.priority) top = line.priority;
					if(line.priority < p && bottom<line.priority) bottom = line.priority;
				}
				line = line.prev;
			}
			if(down){
				if(bottom == p) p = 10;
				else p = bottom;
			}else{
				if(top == p) p = 0;
				else p = top;
			}
			priority = p;
		}
		//
		// COMMAND LINE
		//
		private function clearCommandLineHistory(...args:Array):void
		{
			_cmdsInd = -1;
			central.updateSO();
			_cmdsHistory = new Array();
		}
		private function commandKeyDown(e:KeyboardEvent):void{
			e.stopPropagation();
			if(e.keyCode == Keyboard.TAB){
				if(_hint) 
				{
					_cmdField.text = _hint;
					setCLSelectionAtEnd();
					setHints();
				}
			}
		}
		private function commandKeyUp(e:KeyboardEvent):void{
			if( e.keyCode == Keyboard.ENTER){
				updateToBottom();
				setHints();
				if(_enteringLogin){
					central.remoter.login(_cmdField.text);
					_cmdField.text = "";
					requestLogin(false);
				}else{
					var txt:String = _cmdField.text;
					if(txt.length > 2){
						var i:int = _cmdsHistory.indexOf(txt);
						while(i>=0){
							_cmdsHistory.splice(i,1);
							i = _cmdsHistory.indexOf(txt);
						}
						_cmdsHistory.unshift(txt);
						_cmdsInd = -1;
						// maximum 20 commands history
						if(_cmdsHistory.length>20){
							_cmdsHistory.splice(20);
						}
						central.updateSO(CL_HISTORY);
					}
					_cmdField.text = "";
					if(config.commandLineInputPassThrough != null){
						txt = config.commandLineInputPassThrough(txt);
					}
					if(txt) central.cl.run(txt);
				}
			}else if( e.keyCode == Keyboard.ESCAPE){
				if(stage) stage.focus = null;
			}else if( e.keyCode == Keyboard.UP){
				setHints();
				// if its back key for first time, store the current key
				if(_cmdField.text && _cmdsInd<0){
					_cmdsHistory.unshift(_cmdField.text);
					_cmdsInd++;
				}
				if(_cmdsInd<(_cmdsHistory.length-1)){
					_cmdsInd++;
					_cmdField.text = _cmdsHistory[_cmdsInd];
					setCLSelectionAtEnd();
				}else{
					_cmdsInd = _cmdsHistory.length;
					_cmdField.text = "";
				}
			}else if( e.keyCode == Keyboard.DOWN){
				setHints();
				if(_cmdsInd>0){
					_cmdsInd--;
					_cmdField.text = _cmdsHistory[_cmdsInd];
					setCLSelectionAtEnd();
				}else{
					_cmdsInd = -1;
					_cmdField.text = "";
				}
			}else if(e.keyCode == Keyboard.TAB){
				setCLSelectionAtEnd();
			}
			else if(!_enteringLogin) updateCmdHint();
			e.stopPropagation();
		}
		private function setCLSelectionAtEnd():void{
			_cmdField.setSelection(_cmdField.text.length, _cmdField.text.length);
		}
		private function updateCmdHint(e:Event = null):void{
			var str:String = _cmdField.text;
			if(str && config.commandLineAutoCompleteEnabled && central.remoter.remoting != Remoting.RECIEVER){
				try{
					setHints(central.cl.getHintsFor(str, 5));
					return;
				}catch(err:Error){}
			}
			setHints();
		}
		private function onCmdFocusOut(e:Event):void{
			setHints();
		}
		private function setHints(hints:Array = null):void{
			if(hints && hints.length){
				_hint = hints[0][0];
				if(hints.length > 1){
					var next:String = hints[1][0];
					var matched:Boolean = false;
					for (var i:int = 0; i<next.length; i++){
						if(next.charAt(i) == _hint.charAt(i)){
							matched = true;
						}else{
							if(matched && _cmdField.text.length < i) _hint = _hint.substring(0, i);
							break;
						}
					}
				}
				var strs:Array = new Array();
				for each(var hint:Array in hints) strs.push("<p3>"+hint[0]+"</p3> <p0>"+(hint[1]?hint[1]:"")+"</p0>");
				_hintField.htmlText = "<p>"+strs.reverse().join("\n")+"</p>";
				_hintField.visible = true;
				var r:Rectangle = _cmdField.getCharBoundaries(_cmdField.text.length-1);
				if(!r) r = new Rectangle();
				_hintField.x = _cmdField.x + r.x + r.width+ 30;
				_hintField.y = height-_hintField.height;
			}else{
				_hintField.visible = false;
				_hint = null;
			}
		}
		public function updateCLScope(str:String):void{
			if(_enteringLogin) {
				_enteringLogin = false;
				requestLogin(false);
			}
			_cmdPrefx.autoSize = TextFieldAutoSize.LEFT;
			_cmdPrefx.text = str;
			updateCLSize();
		}
		private function updateCLSize():void{
			var w:Number = width-48;
			if(_cmdPrefx.width > 120 || _cmdPrefx.width > w){
				_cmdPrefx.autoSize = TextFieldAutoSize.NONE;
				_cmdPrefx.width = w>120?120:w;
				_cmdPrefx.scrollH = _cmdPrefx.maxScrollH;
			}
			_cmdField.x = _cmdPrefx.width+2;
			_cmdField.width = width-15-_cmdField.x;
			_hintField.x = _cmdField.x;
		}
		public function set commandLine(b:Boolean):void{
			if(b){
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
			dispatchEvent(new Event(COMMAND_LINE_VISIBLITY_CHANGED));
		}
		public function get commandLine():Boolean{
			return _cmdField.visible;
		}
	}
}