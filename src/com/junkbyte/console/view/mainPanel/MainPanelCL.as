package com.junkbyte.console.view.mainPanel
{
	import com.junkbyte.console.core.ConsoleModule;
	import com.junkbyte.console.logging.Logs;
	import com.junkbyte.console.events.ConsolePanelEvent;
	import com.junkbyte.console.interfaces.IConsoleModule;
	import com.junkbyte.console.interfaces.IRemoter;
	import com.junkbyte.console.modules.ConsoleModuleNames;
	import com.junkbyte.console.modules.commandLine.ICommandLine;
	import com.junkbyte.console.modules.keyStates.IKeyStates;
	import com.junkbyte.console.modules.userdata.IConsoleUserData;
	import com.junkbyte.console.utils.EscHTML;
	import com.junkbyte.console.utils.makeConsoleChannel;
	import com.junkbyte.console.view.ConsolePanel;
	import com.junkbyte.console.view.ConsolePanelAreaModule;
	import com.junkbyte.console.vos.ConsoleModuleMatch;
	import com.junkbyte.console.vos.Log;
	
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	
	public class MainPanelCL extends ConsolePanelAreaModule
	{
		private static const CL_HISTORY:String = "clhistory";
		
		
		private var _userInfo:IConsoleUserData;
		
		private var _cmdsHistory:Array;
		
		private var _cmdPrefx:TextField;
		private var _cmdField:TextField;
		private var _hintField:TextField;
		private var _cmdBG:Shape;
		private var _cmdsInd:int = -1;
		private var _clScope:String = "";
		
		private var _hint:String;
		
		private var _cl:ICommandLine;
		
		public function MainPanelCL(parentPanel:ConsolePanel)
		{
			super(parentPanel);
			addModuleRegisteryCallback(ConsoleModuleMatch.createForClass(IConsoleUserData), userInfoRegistered, userInfoUnregistered);
			addModuleRegisteryCallback(ConsoleModuleMatch.createForClass(ICommandLine), commandLineRegistered, commandLineUnregistered);
			
			
			
			
			_cmdsHistory = new Array();
			//
			_cmdBG = new Shape();
			_cmdBG.name = "commandBackground";
			//
			_cmdField = new TextField();
			_cmdField.name = "commandField";
			_cmdField.type  = TextFieldType.INPUT;
			_cmdField.addEventListener(KeyboardEvent.KEY_DOWN, commandKeyDown);
			_cmdField.addEventListener(KeyboardEvent.KEY_UP, commandKeyUp);
			_cmdField.addEventListener(FocusEvent.FOCUS_IN, updateCmdHint);
			_cmdField.addEventListener(FocusEvent.FOCUS_OUT, onCmdFocusOut);
			
			_hintField = new TextField();
			_hintField.name = "hintField";
			_hintField.background = true;
			_hintField.mouseEnabled = false;
			_hintField.autoSize = TextFieldAutoSize.LEFT;
			setHints();
			
			_cmdPrefx = new TextField();
			_cmdPrefx.name = "commandPrefx";
			_cmdPrefx.type  = TextFieldType.DYNAMIC;
			_cmdPrefx.selectable = false;
			_cmdPrefx.addEventListener(MouseEvent.MOUSE_DOWN, onCmdPrefMouseDown);
			_cmdPrefx.addEventListener(MouseEvent.MOUSE_MOVE, onCmdPrefRollOverOut);
			_cmdPrefx.addEventListener(MouseEvent.ROLL_OUT, onCmdPrefRollOverOut);
		}
		
		public function get isVisible():Boolean
		{
			return _cmdField.visible;
		}
		
		public function set isVisible(b:Boolean):void{
			if(b){
				_cmdField.visible = true;
				_cmdPrefx.visible = true;
				_cmdBG.visible = true;
			}else{
				_cmdField.visible = false;
				_cmdPrefx.visible = false;
				_cmdBG.visible = false;
			}
		}
		
		public function set inputText(text:String):void
		{
			_cmdField.text = text;
		}
		
		public function get inputText():String
		{
			return _cmdField.text;
		}
		
		override protected function registeredToConsole():void
		{
			
			var tf:TextFormat = new TextFormat(style.menuFont, style.menuFontSize, style.highColor);
			
			_cmdField.defaultTextFormat = tf;
			
			_hintField.styleSheet = style.styleSheet;
			_hintField.backgroundColor = style.backgroundColor;
			
			tf.color = style.commandLineColor;
			_cmdPrefx.defaultTextFormat = tf;
			
			addChild(_cmdBG);
			addChild(_cmdField);
			addChild(_hintField);
			addChild(_cmdPrefx);
			
			sprite.addEventListener(Event.ADDED_TO_STAGE, stageAddedHandle, false, 0, true);
			sprite.addEventListener(Event.REMOVED_FROM_STAGE, stageRemovedHandle, false, 0, true);
			
			super.registeredToConsole();
		}
		
		override protected function unregisteredFromConsole():void
		{
			var mainPanel:MainPanel  = console.layer.mainPanel;
			
			
			removeChild(_cmdBG);
			removeChild(_cmdField);
			removeChild(_hintField);
			removeChild(_cmdPrefx);
			
			
			sprite.removeEventListener(Event.ADDED_TO_STAGE, stageAddedHandle);
			sprite.removeEventListener(Event.REMOVED_FROM_STAGE, stageRemovedHandle);
			//
			updateCLScope("");
			
			
			super.unregisteredFromConsole();
		}
		
		override public function setArea(x:Number, y:Number, width:Number, height:Number):void
		{
			super.setArea(x, y, width, height);
			
			var fsize:int = style.menuFontSize;
			var cmdy:Number = height-(fsize+6);
			
			_cmdBG.graphics.clear();
			_cmdBG.graphics.beginFill(style.commandLineColor, 0.1);
			_cmdBG.graphics.drawRoundRect(0, 0, 100, 18,fsize,fsize);
			_cmdBG.scale9Grid = new Rectangle(9, 9, 80, 1);
			
			
			_cmdPrefx.x = 2;
			_hintField.x = _cmdField.x = 40;
			
			_cmdPrefx.y = cmdy;
			_cmdPrefx.height = fsize+6;
			
			_cmdField.y = cmdy;
			_cmdField.width = width-15-_cmdField.x;
			_cmdField.height = fsize+6;
			
			_hintField.y = _cmdField.y-_hintField.height;
			
			_cmdBG.x = x;
			_cmdBG.y = cmdy;
			_cmdBG.width = width;
		}
		
		
		protected function userInfoRegistered(module:IConsoleUserData):void
		{
			_userInfo = module;
			if(_userInfo.data[CL_HISTORY] is Array){
				_cmdsHistory = _userInfo.data[CL_HISTORY];
			}else{
				_userInfo.data[CL_HISTORY] = _cmdsHistory = new Array();
			}
		}
		
		protected function userInfoUnregistered(module:IConsoleModule):void
		{
			_userInfo = null;
		}
		
		protected function commandLineRegistered(module:ICommandLine):void
		{
			_cl = module;
			module.addInternalSlashCommand("clearhistory", clearCommandLineHistory, "Clear history of commands you have entered.", true);
		}
		
		protected function commandLineUnregistered(module:ICommandLine):void
		{
			_cl = null;
			module.addInternalSlashCommand("clearhistory", null);
		}
		
		public function update(changed:Boolean):void
		{
			
			if (style.showCommandLineScope) {
				if(_clScope != _cl.scopeString){
					_clScope = _cl.scopeString;
					updateCLScope(_clScope);
				}
			}else if(_clScope != null){
				_clScope = "";
				updateCLScope("");
			}
		}
		
		
		private function stageAddedHandle(e:Event=null):void{
			sprite.stage.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler, false, 0, true);
		}
		private function stageRemovedHandle(e:Event=null):void{
			sprite.stage.removeEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
		}
		private function onCmdPrefRollOverOut(e : MouseEvent) : void {
			layer.setTooltip(e.type==MouseEvent.MOUSE_MOVE?"Current scope::(CommandLine)":"", mainPanel);
		}
		
		private function onCmdPrefMouseDown(e : MouseEvent) : void {
			try{
				var mainPanel:MainPanel  = console.layer.mainPanel;
				mainPanel.sprite.stage.focus = _cmdField;
				setCLSelectionAtEnd();
			} catch(err:Error) {}
		}
		private function keyUpHandler(e:KeyboardEvent):void{
			if((e.keyCode == Keyboard.TAB || e.keyCode == Keyboard.ENTER) && layer.visible && sprite.visible && _cmdField.visible){
				try{
					sprite.stage.focus = _cmdField;
					setCLSelectionAtEnd();
				} catch(err:Error) {}
			}
		}
		
		public function requestLogin(on:Boolean = true):void{
			if(on){
				updateCLScope("Password");
				var ct:ColorTransform = new ColorTransform();
				ct.color = style.controlColor;
				_cmdBG.transform.colorTransform = ct;
			}else{
				updateCLScope("");
				_cmdBG.transform.colorTransform = new ColorTransform();
			}
			_cmdField.displayAsPassword = on;
		}
		//
		// COMMAND LINE
		//
		private function clearCommandLineHistory(...args:Array):void
		{
			_cmdsInd = -1;
			_cmdsHistory.splice(0, _cmdsHistory.length);
			if(_userInfo)
			{
				_userInfo.updateData();
			}
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
				mainPanel.traces.updateToBottom();
				setHints();
				if(mainPanel.enteringLogin){
					var remoter:IRemoter = modules.getModuleByName(ConsoleModuleNames.REMOTING) as IRemoter;
					remoter.login(_cmdField.text);
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
						if(_userInfo)
						{
							_userInfo.updateData(CL_HISTORY);
						}
					}
					_cmdField.text = "";
					if(config.commandLineInputPassThrough != null){
						txt = config.commandLineInputPassThrough(txt);
					}
					if(txt) _cl.run(txt);
				}
			}else if( e.keyCode == Keyboard.ESCAPE){
				if(sprite.stage) sprite.stage.focus = null;
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
			else if(!mainPanel.enteringLogin) updateCmdHint();
			e.stopPropagation();
		}
		private function setCLSelectionAtEnd():void{
			_cmdField.setSelection(_cmdField.text.length, _cmdField.text.length);
		}
		private function updateCmdHint(e:Event = null):void{
			var str:String = _cmdField.text;
			if(str && config.commandLineAutoCompleteEnabled){
				try{
					setHints(_cl.getHintsFor(str, 5));
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
				_hintField.y = area.height-_hintField.height;
			}else{
				_hintField.visible = false;
				_hint = null;
			}
		}
		public function updateCLScope(str:String):void{
			//if(mainPanel.enteringLogin) {
			//	mainPanel.enteringLogin = false;
			//	requestLogin(false);
			//}
			_cmdPrefx.autoSize = TextFieldAutoSize.LEFT;
			_cmdPrefx.text = str;
			updateCLSize();
		}
		private function updateCLSize():void{
			var w:Number = area.width-48;
			if(_cmdPrefx.width > 120 || _cmdPrefx.width > w){
				_cmdPrefx.autoSize = TextFieldAutoSize.NONE;
				_cmdPrefx.width = w>120?120:w;
				_cmdPrefx.scrollH = _cmdPrefx.maxScrollH;
			}
			_cmdField.x = _cmdPrefx.width+2;
			_cmdField.width = area.width-15-_cmdField.x;
			_hintField.x = _cmdField.x;
		}
	}
}