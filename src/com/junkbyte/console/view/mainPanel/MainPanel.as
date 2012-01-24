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

	import com.junkbyte.console.ConsoleChannels;
	import com.junkbyte.console.ConsoleLevel;
	import com.junkbyte.console.events.ConsolePanelEvent;
	import com.junkbyte.console.interfaces.IKeyStates;
	import com.junkbyte.console.modules.ConsoleModuleNames;
	import com.junkbyte.console.utils.makeConsoleChannel;
	import com.junkbyte.console.view.ChannelsPanel;
	import com.junkbyte.console.view.ConsolePanel;
	import com.junkbyte.console.view.menus.LogPriorityMenu;
	import com.junkbyte.console.view.menus.PauseLogDisplayMenu;
	import com.junkbyte.console.view.menus.SaveToClipboardMenu;
	import com.junkbyte.console.vos.ConsoleMenuItem;
	import com.junkbyte.console.vos.Log;

	import flash.events.Event;
	import flash.events.TextEvent;
	import flash.geom.Point;
	import flash.system.Security;
	import flash.system.SecurityPanel;

	public class MainPanel extends ConsolePanel
	{

		public static const VIEWING_CHANNELS_CHANGED:String = "viewingChannelsChanged";
		public static const FILTER_PRIORITY_CHANGED:String = "filterPriorityChanged";
		public static const COMMAND_LINE_VISIBLITY_CHANGED:String = "commandLineVisibilityChanged";

		private var _menu:MainPanelMenu;
		private var _outputDisplay:ConsoleOutputDisplay;
		private var _commandArea:MainPanelCL;

		private var _enteringLogin:Boolean;
		private var _movedFrom:Point;

		private var _viewingChannels:Vector.<String> = new Vector.<String>();
		private var _ignoredChannels:Vector.<String> = new Vector.<String>();
		private var _priority:uint;

		protected var _defaultOutputProvider:DefaultOutputProvider;

		public function MainPanel()
		{
			super();
			minSize.x = 160;

			addEventListener(ConsolePanelEvent.STARTED_MOVING, onStartedDragging);
		}

		override public function getModuleName():String
		{
			return ConsoleModuleNames.MAIN_PANEL;
		}

		override protected function initToConsole():void
		{
			super.initToConsole();
			sprite.name = ConsoleModuleNames.MAIN_PANEL;

			_defaultOutputProvider = new DefaultOutputProvider();
			modules.registerModule(_defaultOutputProvider);
			//
			_menu = new MainPanelMenu(this);
			_outputDisplay = new ConsoleOutputDisplay(this);

			_outputDisplay.setDataProvider(_defaultOutputProvider);

			_commandArea = new MainPanelCL(this);

			_menu.addEventListener(Event.CHANGE, onMenuChanged);

			modules.registerModule(_outputDisplay);
			modules.registerModule(_menu);
			modules.registerModule(_commandArea);

			startPanelResizer();

			sprite.addEventListener(TextEvent.LINK, linkHandler, false, 0, true);

			setPanelSize(480, 100);

			addToLayer();
			addMenus();
		}

		protected function addMenus():void
		{
			var logPriorityMenu:LogPriorityMenu = new LogPriorityMenu(this);
			logPriorityMenu.sortPriority = -80;
			_menu.addMenu(logPriorityMenu);

			var saveMenu:SaveToClipboardMenu = new SaveToClipboardMenu();
			saveMenu.sortPriority = -50;

			_menu.addMenu(saveMenu);

			var clearLogsMenu:ConsoleMenuItem = new ConsoleMenuItem("C", logger.logs.clear, null, "Clear log");
			clearLogsMenu.sortPriority = -80;
			_menu.addMenu(clearLogsMenu);

			var closeMenu:ConsoleMenuItem = new ConsoleMenuItem("X", removeFromParent, null, "Close::Type password to show again");
			closeMenu.sortPriority = -90;
			_menu.addMenu(closeMenu);

			var pauseMenu:PauseLogDisplayMenu = new PauseLogDisplayMenu();
			pauseMenu.sortPriority = -60;
			_menu.addMenu(pauseMenu);
		}

		public function updateToBottom():void
		{
			_outputDisplay.updateToBottom();
		}

		private function onStartedDragging(e:Event):void
		{
			_movedFrom = new Point(x, y);
		}

		public function requestLogin(on:Boolean = true):void
		{
			if (on)
			{
				commandLine = true;
				logger.report("//", ConsoleLevel.CONSOLE_EVENT);
				logger.report("// <b>Enter remoting password</b> in CommandLine below...", ConsoleLevel.CONSOLE_EVENT);
			}
			//_outputDisplay.requestLogin(on);
			_commandArea.requestLogin(on);
			_enteringLogin = on;
		}

		public function get enteringLogin():Boolean
		{
			return _enteringLogin;
		}

		override protected function resizePanel(w:Number, h:Number):void
		{
			super.resizePanel(w, h);

			updateMenuArea();

			updateCommandArea();
			_menu.invalidate();

			var fsize:int = style.menuFontSize;
			var msize:Number = fsize + 6 + style.traceFontSize;
			if (height != h)
			{
				_menu.mini = h < (_commandArea.isVisible ? (msize + fsize + 4) : msize);
			}

			updateTraceArea();
		}

		private function updateMenuArea():void
		{
			_menu.setArea(0, 0, width - 6, height);
		}

		private function updateTraceArea():void
		{
			var mini:Boolean = _menu.mini || !style.topMenu;

			var traceY:Number = mini ? 0 : (_menu.area.y + _menu.area.height - 6);
			var traceHeight:Number = height - (_commandArea.isVisible ? (style.menuFontSize + 4) : 0) - traceY;
			_outputDisplay.setArea(0, traceY, width, traceHeight);

		}

		private function updateCommandArea():void
		{
			_commandArea.setArea(0, 0, width, height);
		}

		private function onMenuChanged(e:Event):void
		{
			updateMenuArea();
			updateTraceArea();
		}

		private function linkHandler(e:TextEvent):void
		{
			_menu.textField.setSelection(0, 0);
			sprite.stopDrag();
			var t:String = e.text;
			if (t == "channels")
			{
				toggleChannelsPanel();
			}
			/*else if(t == "priority"){
				var keyStates:IKeyStates = modules.getModuleByName(ConsoleModuleNames.KEY_STATES) as IKeyStates;

				traces.incPriority(keyStates != null && keyStates.shiftKeyDown);
			}*/
			else if (t == "settings")
			{
				logger.report("A new window should open in browser. If not, try searching for 'Flash Player Global Security Settings panel' online :)", ConsoleLevel.CONSOLE_STATUS);
				Security.showSettings(SecurityPanel.SETTINGS_MANAGER);
			}
			else if (t == "remote")
			{
				//central.remoter.remoting = Remoting.RECIEVER;
				//} else if(t.indexOf("ref")==0){
				//	central.refs.handleRefEvent(t);
			}
			else if (t.indexOf("channel_") == 0)
			{
				onChannelPressed(t.substring(8));
			}
			else if (t.indexOf("cl_") == 0)
			{
				var ind:int = t.indexOf("_", 3);
				//central.cl.handleScopeEvent(uint(t.substring(3, ind<0?t.length:ind)));
				if (ind >= 0)
				{
					_commandArea.inputText = t.substring(ind + 1);
				}
			}
			_menu.textField.setSelection(0, 0);
			e.stopPropagation();
		}

		private function toggleChannelsPanel():void
		{
			var channelsPanel:ChannelsPanel = modules.getModuleByName(ConsoleModuleNames.CHANNELS_PANEL) as ChannelsPanel;
			if (channelsPanel != null)
			{
				modules.unregisterModule(channelsPanel);
			}
			else
			{
				channelsPanel = new ChannelsPanel();
				modules.registerModule(channelsPanel);
			}
		}

		public function hideTopMenu():void
		{
			_menu.mini = false;
		}

		public function showTopMenu():void
		{
			_menu.mini = true;
		}

		public function set commandLine(b:Boolean):void
		{
			_commandArea.isVisible = b;

			_menu.invalidate();

			this.height = height;
			dispatchEvent(new Event(COMMAND_LINE_VISIBLITY_CHANGED));
		}

		public function get commandLine():Boolean
		{
			return _commandArea.isVisible;
		}

		public function moveToLastSafePosition():void
		{
			if (_movedFrom != null)
			{
				// This will only work if stage size is not altered OR stage.align is top left
				if (x + width < 10 || (sprite.stage && sprite.stage.stageWidth < x + 10) || y + height < 10 || (sprite.stage && sprite.stage.stageHeight < y + 20))
				{
					x = _movedFrom.x;
					y = _movedFrom.y;
				}
				_movedFrom = null;
			}
		}

		public function getChannelsLink(limited:Boolean = false):String
		{
			var str:String = "<chs>";
			var channels:Array = console.logger.logs.getChannels();
			var len:int = channels.length;
			if (limited && len > style.maxChannelsInMenu)
			{
				len = style.maxChannelsInMenu;
			}
			var filtering:Boolean = _viewingChannels.length > 0 || _ignoredChannels.length > 0;
			for (var i:int = 0; i < len; i++)
			{
				var channel:String = channels[i];
				var channelTxt:String = ((!filtering && i == 0) || (filtering && i != 0 && chShouldShow(channel))) ? "<ch><b>" + channel + "</b></ch>" : channel;
				str += "<a href=\"event:channel_" + channel + "\">[" + channelTxt + "]</a> ";
			}
			if (limited)
			{
				str += "<ch><a href=\"event:channels\"><b>" + (channels.length > len ? "..." : "") + "</b>^^ </a></ch>";
			}
			str += "</chs> ";
			return str;
		}

		public function onChannelPressed(chn:String):void
		{
			var current:Vector.<String>;

			var keyStates:IKeyStates = modules.getModuleByName(ConsoleModuleNames.KEY_STATES) as IKeyStates;

			if (keyStates != null && keyStates.ctrlKeyDown && chn != ConsoleChannels.GLOBAL)
			{
				current = toggleCHList(_ignoredChannels, chn);
				setIgnoredChannels.apply(this, current);
			}
			else if (keyStates != null && keyStates.shiftKeyDown && chn != ConsoleChannels.GLOBAL && _viewingChannels[0] != ConsoleChannels.INSPECTING)
			{
				current = toggleCHList(_viewingChannels, chn);
				setViewingChannels.apply(this, current);
			}
			else
			{
				console.mainPanel.setViewingChannels(chn);
			}
		}

		private function toggleCHList(current:Vector.<String>, chn:String):Vector.<String>
		{
			current = current.concat();
			var ind:int = current.indexOf(chn);
			if (ind >= 0)
			{
				current.splice(ind, 1);
				if (current.length == 0)
				{
					current.push(ConsoleChannels.GLOBAL);
				}
			}
			else
			{
				current.push(chn);
			}
			return current;
		}

		public function set priority(p:uint):void
		{
			_priority = p;
			// central.so[PRIORITY_HISTORY] = _priority;
			_defaultOutputProvider.changed();
			dispatchEvent(new Event(FILTER_PRIORITY_CHANGED));
		}

		public function get priority():uint
		{
			return _priority;
		}

		//
		public function incPriority(down:Boolean):void
		{
			var top:uint = 10;
			var bottom:uint;
			var line:Log = console.logger.logs.last;
			var p:int = _priority;
			_priority = 0;
			var i:uint = 32000;
			// just for crash safety, it wont look more than 32000 lines.
			while (line && i > 0)
			{
				i--;
				if (lineShouldShow(line))
				{
					if (line.priority > p && top > line.priority)
					{
						top = line.priority;
					}
					if (line.priority < p && bottom < line.priority)
					{
						bottom = line.priority;
					}
				}
				line = line.prev;
			}
			if (down)
			{
				if (bottom == p)
				{
					p = 10;
				}
				else
				{
					p = bottom;
				}
			}
			else
			{
				if (top == p)
				{
					p = 0;
				}
				else
				{
					p = top;
				}
			}
			priority = p;
		}

		public function lineShouldShow(line:Log):Boolean
		{
			return (chShouldShow(line.channel) && (_priority == 0 || line.priority >= _priority));
			//(_filterText && _viewingChannels.indexOf(ConsoleChannels.FILTERING) >= 0 && line.text.toLowerCase().indexOf(_filterText) >= 0) || (_filterRegExp && _viewingChannels.indexOf(ConsoleChannels.FILTERING) >= 0 && line.text.search(_filterRegExp) >= 0))
		}

		private function chShouldShow(ch:String):Boolean
		{
			return ((_viewingChannels.length == 0 || _viewingChannels.indexOf(ch) >= 0) && (_ignoredChannels.length == 0 || _ignoredChannels.indexOf(ch) < 0));
		}

		public function get reportChannel():String
		{
			return _viewingChannels.length == 1 ? _viewingChannels[0] : ConsoleChannels.CONSOLE;
		}

		public function setViewingChannels(... channels:Array):void
		{
			var a:Array = new Array();
			for each (var item:Object in channels)
			{
				a.push(makeConsoleChannel(item));
			}

			_ignoredChannels.splice(0, _ignoredChannels.length);
			_viewingChannels.splice(0, _viewingChannels.length);
			if (a.indexOf(ConsoleChannels.GLOBAL) < 0 && a.indexOf(null) < 0)
			{
				for each (var ch:String in a)
				{
					_viewingChannels.push(ch);
				}
			}
			_defaultOutputProvider.changed();
			announceChannelInterestChanged();
		}

		public function get viewingChannels():Vector.<String>
		{
			return _viewingChannels;
		}

		public function setIgnoredChannels(... channels:Array):void
		{
			var a:Array = new Array();
			for each (var item:Object in channels)
			{
				a.push(makeConsoleChannel(item));
			}

			_ignoredChannels.splice(0, _ignoredChannels.length);
			_viewingChannels.splice(0, _viewingChannels.length);
			if (a.indexOf(ConsoleChannels.GLOBAL) < 0 && a.indexOf(null) < 0)
			{
				for each (var ch:String in a)
				{
					_ignoredChannels.push(ch);
				}
			}
			_defaultOutputProvider.changed();
			announceChannelInterestChanged();
		}

		public function get ignoredChannels():Vector.<String>
		{
			return _ignoredChannels;
		}

		private function announceChannelInterestChanged():void
		{
			dispatchEvent(new Event(VIEWING_CHANNELS_CHANGED));
		}
	}
}
