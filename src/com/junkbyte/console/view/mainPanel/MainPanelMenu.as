/*
*
* Copyright (c) 2008-2011 Lu Aye Oo
*
* @author 		Lu Aye Oo
*
* http://code.google.com/p/flash-console/
* http://junkbyte.com
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
package com.junkbyte.console.view.mainPanel
{
	import com.junkbyte.console.core.ModuleNameMatcher;
	import com.junkbyte.console.core.ModuleTypeMatcher;
	import com.junkbyte.console.events.ConsoleEvent;
	import com.junkbyte.console.events.ConsoleLogEvent;
	import com.junkbyte.console.interfaces.IConsoleMenuItem;
	import com.junkbyte.console.interfaces.IConsoleModule;
	import com.junkbyte.console.interfaces.IMainMenu;
	import com.junkbyte.console.logging.Logs;
	import com.junkbyte.console.modules.ConsoleModuleNames;
	import com.junkbyte.console.interfaces.IKeyStates;
	import com.junkbyte.console.view.ChannelsPanel;
	import com.junkbyte.console.view.ConsolePanel;
	import com.junkbyte.console.view.helpers.ConsoleTextRoller;
	import com.junkbyte.console.vos.ConsoleMenuItem;
	
	import flash.events.Event;
	import flash.events.TextEvent;
	import flash.geom.Rectangle;
	import flash.net.FileReference;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	
	[Event(name="change", type="flash.events.Event")]
	public class MainPanelMenu extends MainPanelSubArea implements IMainMenu
	{
		
		public static const NAME:String = "mainPanelMenu";
		
		protected var _textField:TextField;
		
		private var buildInMenus:Array;
		private var moduleMenus:Array;
		
		private var minimizerMenu:ConsoleMenuItem;
		private var pauseMenu:ConsoleMenuItem;
		private var priorityMenu:ConsoleMenuItem;
		private var commandLineMenu:ConsoleMenuItem;
		
		private var hasChannelsPanel:Boolean;
		
		public var mini:Boolean;
		
		protected var needsUpdate:Boolean = true;
		
		public function MainPanelMenu(parentPanel:ConsolePanel)
		{
			super(parentPanel);
			buildInMenus = new Array();
			moduleMenus = new Array();
			
			_textField = new TextField();
			_textField.name = "menuField";
			_textField.wordWrap = true;
			_textField.multiline = true;
			_textField.autoSize = TextFieldAutoSize.RIGHT;
			
			addModuleRegisteryCallback(new ModuleTypeMatcher(MainPanelLogs), mainPanelLogsRegistered, null);
			addModuleRegisteryCallback(new ModuleNameMatcher(ConsoleModuleNames.CHANNELS_PANEL), channelsPanelRegistered, channelsPanelUnregistered);
		}
		
		override protected function registeredToConsole():void
		{
			super.registeredToConsole();
			
			addChild(textField);
			mainPanel.registerMoveDragger(textField);
			
			_textField.styleSheet = style.styleSheet;
			
			display.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			console.logger.logs.addEventListener(ConsoleLogEvent.CHANNELS_CHANGED, onChannelsChanged);
			
			ConsoleTextRoller.register(_textField, textRollOverHandler, linkHandler);
		}
		
		
		override protected function unregisteredFromConsole():void
		{
			super.unregisteredFromConsole();
			
			display.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			console.logger.logs.removeEventListener(ConsoleLogEvent.CHANNELS_CHANGED, onChannelsChanged);
			
			mainPanel.unregisterMoveDragger(textField);
			removeChild(textField);
		}
		
		private function onChannelsChanged(e:Event):void
		{
			needsUpdate = true;
		}
		
		protected function onEnterFrame(event:Event):void
		{
			if(needsUpdate)
			{
				update();
				needsUpdate = false;
			}
		}
		
		
		protected function mainPanelLogsRegistered(module:MainPanelLogs):void
		{
			initBuildInMenus();
			initModuleMenus();
		}
		
		protected function channelsPanelRegistered(module:ChannelsPanel):void
		{
			hasChannelsPanel = true;
			needsUpdate = true;
		}
		
		protected function channelsPanelUnregistered(module:ChannelsPanel):void
		{
			hasChannelsPanel = false;
			needsUpdate = true;
		}
		
		override public function getModuleName():String
		{
			return NAME;
		}
		
		public function get textField():TextField
		{
			return _textField;
		}
		
		override public function setArea(x:Number, y:Number, width:Number, height:Number):void
		{
			super.setArea(x, y, width, height);
			
			
			textField.x = x;
			textField.y = y - 2;
			textField.width = width;
			
		}
		
		
		
		override public function get area():Rectangle
		{
			super.area.height = textField.height;
			return super.area;
		}
		
		protected function initBuildInMenus():void
		{
			
			minimizerMenu = new ConsoleMenuItem("", minimizerCB);
			updateMinimizerState();
			console.addEventListener(ConsoleEvent.PAUSED, updateMinimizerState, false, 0, true);
			console.addEventListener(ConsoleEvent.RESUMED, updateMinimizerState, false, 0, true);
			
			pauseMenu = new ConsoleMenuItem("P", pauseCB, null, "Close::Type password to show again");
			updatePauseState();
			console.addEventListener(ConsoleEvent.PAUSED, updatePauseState, false, 0, true);
			console.addEventListener(ConsoleEvent.RESUMED, updatePauseState, false, 0, true);
			
			priorityMenu = new ConsoleMenuItem("P0", priorityCB, null, "Priority filter::shift: previous priority\n(skips unused priorites)");
			updatePriorityState();
			mainPanel.addEventListener(MainPanelLogs.FILTER_PRIORITY_CHANGED, updatePriorityState, false, 0, true);
			
			
			commandLineMenu = new ConsoleMenuItem("CL", commandLineCB);
			updateCommandLineState();
			mainPanel.addEventListener(MainPanel.COMMAND_LINE_VISIBLITY_CHANGED, updateCommandLineState, false, 0, true);
			
			
			buildInMenus = new Array();
			
			addBuildInMenu(minimizerMenu);
			addBuildInMenu(new ConsoleMenuItem("X", mainPanel.removeFromParent, null, "Close::Type password to show again"));
			addBuildInMenu(new ConsoleMenuItem("C", logger.logs.clear, null, "Clear log"));
			addBuildInMenu(pauseMenu);
			addBuildInMenu(new ConsoleMenuItem("Sv", saveLogs, null, "Save to clipboard::shift: no channel name\nctrl: use viewing filters\nalt: save to file"));
			addBuildInMenu(priorityMenu);
			addBuildInMenu(commandLineMenu);
			
		}
		
		protected function addBuildInMenu(menu:IConsoleMenuItem):void{
			buildInMenus.push(menu);
			buildInMenus.sort(menuSorter);
			menu.addEventListener(Event.CHANGE, onMenuChanged, false, 0, true);
			needsUpdate = true;
		}
		
		public function addMenu(menu:IConsoleMenuItem):void{
			var index:int = moduleMenus.indexOf(menu);
			if(index < 0)
			{
				moduleMenus.push(menu);
				moduleMenus.sort(menuSorter);
				menu.addEventListener(Event.CHANGE, onMenuChanged, false, 0, true);
			}
			needsUpdate = true;
		}
		
		public function removeMenu(menu:IConsoleMenuItem):void{
			var index:int = moduleMenus.indexOf(menu);
			if(index >= 0)
			{
				moduleMenus.splice(index, 1);
				menu.removeEventListener(Event.CHANGE, onMenuChanged);
			}
			needsUpdate = true;
		}
		
		protected function menuSorter(a:IConsoleMenuItem, b:IConsoleMenuItem):int
		{
			var pA:Number = a.getSortPriority();
			var pB:Number = b.getSortPriority();
			if(pA > pB) return 1;
			else if(pA < pB) return -1;
			return 0;
		}
		
		protected function onMenuChanged(event:Event):void
		{
			needsUpdate = true;
		}
		
		protected function initModuleMenus():void
		{
			moduleMenus = new Array();
		}
		
		private function updatePauseState(e:Event = null):void{
			pauseMenu.active = console.paused;
			pauseMenu.tooltip = pauseMenu.active?"Resume updates":"Pause updates";
			pauseMenu.announceChanged();
		}
		
		private function pauseCB():void{
			console.paused = !console.paused;
		}
		
		private function updatePriorityState(e:Event = null):void{
			priorityMenu.active = mainPanel.traces.priority > 0;
			priorityMenu.name = "P"+mainPanel.traces.priority;
			priorityMenu.announceChanged();
		}
		
		private function priorityCB(e:Event = null):void{
			var keyStates:IKeyStates = modules.getModuleByName(ConsoleModuleNames.KEY_STATES) as IKeyStates;
			mainPanel.traces.incPriority(keyStates != null && keyStates.shiftKeyDown);
		}
		
		private function updateMinimizerState(e : Event = null) : void {
			minimizerMenu.name = mini ? "‹" : "›";
			minimizerMenu.tooltip = mini ? "Expand menu" : "Minimize menu";
			minimizerMenu.announceChanged();
		}
		
		
		private function minimizerCB(e:Event = null):void{
			mini = !mini;
			updateMinimizerState();
		}
		
		private function updateCommandLineState(e : Event = null) : void {
			commandLineMenu.active = mainPanel.commandLine;
			commandLineMenu.tooltip = commandLineMenu.active ? "Hide Command Line" : "Show Command Line";
			commandLineMenu.announceChanged();
		}
		
		private function commandLineCB(e:Event = null):void{
			mainPanel.commandLine = !mainPanel.commandLine;
		}
		
		private function saveLogs():void
		{
			var keyStates:IKeyStates = modules.getModuleByName(ConsoleModuleNames.KEY_STATES) as IKeyStates;
			if(keyStates == null)
			{
				saveLogsWOpts();
			}
			else
			{
				saveLogsWOpts(!keyStates.shiftKeyDown, keyStates.altKeyDown, keyStates.ctrlKeyDown ? mainPanel.traces.lineShouldShow : null);
			}
		}
		
		protected function saveLogsWOpts(incChNames:Boolean = true, makeFile:Boolean = false, filterFunction:Function = null):void
		{
			var str : String = console.logger.logs.getLogsAsString("\r\n", incChNames, filterFunction);
			if(makeFile){
				var file:FileReference = new FileReference();
				try{
					file["save"](str,"log.txt");
				}catch(err:Error) {
					report("Save to file is not supported in your flash player.", 8);
				}
			}else{
				System.setClipboard(str);
				report("Copied log to clipboard.", -1);
			}
		}
		
		public function update():void{
			var str:String = "<r><high><menu><b> ";
			if(mini || !style.topMenu){
				str += "<a href=\"event:show\">‹</a>";
			}else {
				if(hasChannelsPanel == false){
					str += console.mainPanel.traces.getChannelsLink(true);
				}
				str += printMenus();
			}
			str += " </b></menu></high></r>";
			_textField.htmlText = str;
			_textField.scrollH = _textField.maxScrollH;
			dispatchEvent(new Event(Event.CHANGE));
		}
		
		protected function createMenuString(menu:IConsoleMenuItem, index:uint):String
		{
			var str:String = " <a href=\"event:menu_"+index+"\">" + menu.getName() + "</a>";
			if(menu.isActive())
			{
				return "<menuHi>"+str+"</menuHi>";
			}
			return str;
		}
		
		private function linkHandler(e:TextEvent):void{
			_textField.setSelection(0, 0);
			var t:String = e.text;
			if(t.substring(0, 5) == "menu_"){
				var menu:ConsoleMenuItem = getMenuForIndex(uint(t.substring(5)));
				if (menu) {
					menu.onClick();
				}
			}
		}
		
		private function printMenus():String
		{
			var str:String = "";
			var modulesLen:uint = moduleMenus.length;
			
			for (var i:int = modulesLen-1; i >= 0; i--){
				str += createMenuString(moduleMenus[i], i);
			}
				
			str += " ¦ ";
				
			for (i = buildInMenus.length-1; i >= 0; i--){
				str += createMenuString(buildInMenus[i], i+modulesLen);
			}
			/*
				var extra:Boolean;
				for (var X:String in _extraMenus){
					str += "<a href=\"event:external_"+X+"\">"+X+"</a> ";
					extra = true;
				}
				if(extra) str += "¦ ";
				
				str += doActive("<a href=\"event:fps\">F</a>", central.console.fpsMonitor>0);
				str += doActive(" <a href=\"event:mm\">M</a>", central.console.memoryMonitor>0);
				
				str += doActive(" <a href=\"event:command\">CL</a>", central.console.commandLine);
				
				if(central.remoter.remoting != Remoting.RECIEVER){
					if(config.displayRollerEnabled)
					str += doActive(" <a href=\"event:roller\">Ro</a>", central.console.displayRoller);
					if(config.rulerToolEnabled)
					str += doActive(" <a href=\"event:ruler\">RL</a>", central.panels.rulerActive);
				}
				str += " ¦</b>";
			*/
			return str;
		}
		
		private function getMenuForIndex(index:uint):ConsoleMenuItem
		{
			if(index >= moduleMenus.length ) return buildInMenus[index-moduleMenus.length];
			return moduleMenus[index];
		}
		
		private function textRollOverHandler(e:TextEvent):void{
			var t:String = e.text?e.text.replace("event:",""):"";
			if(t.substring(0, 5) == "menu_"){
				var menu:ConsoleMenuItem = getMenuForIndex(uint(t.substring(5)));
				t = menu.getTooltip();
			}
			mainPanel.setTooltip(t);
		}
	}
}
