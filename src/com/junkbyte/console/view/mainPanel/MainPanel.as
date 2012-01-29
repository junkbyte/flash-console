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

	import com.junkbyte.console.ConsoleLevel;
	import com.junkbyte.console.events.ConsolePanelEvent;
	import com.junkbyte.console.modules.ConsoleModuleNames;
	import com.junkbyte.console.view.ChannelsPanel;
	import com.junkbyte.console.view.ConsolePanel;
	import com.junkbyte.console.view.menus.LogPriorityMenu;
	import com.junkbyte.console.view.menus.PauseLogDisplayMenu;
	import com.junkbyte.console.view.menus.SaveToClipboardMenu;
	import com.junkbyte.console.vos.ConsoleMenuItem;

	import flash.events.Event;
	import flash.events.TextEvent;
	import flash.geom.Point;
	import flash.system.Security;
	import flash.system.SecurityPanel;

	public class MainPanel extends ConsolePanel
	{

		public static const COMMAND_LINE_VISIBLITY_CHANGED:String = "commandLineVisibilityChanged";

		private var _menu:MainPanelMenu;
		private var _outputDisplay:ConsoleOutputDisplay;
		private var _commandArea:MainPanelCL;

		private var _enteringLogin:Boolean;
		private var _movedFrom:Point;

		protected var _defaultOutputProvider:ConsoleMainOutputProvider;

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

			_defaultOutputProvider = new ConsoleMainOutputProvider();
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
			
			setPanelSize(480, 100);

			addToLayer();
			addMenus();
			
			
			modules.textLinks.addLinkCallback("channels", onChannelsLinkClicked);
		}

		public function setOutputProvider(provider:ConsoleOutputProvider):void
		{
			if (provider == null)
			{
				provider = _defaultOutputProvider;
			}
			_outputDisplay.setDataProvider(provider);
		}

		protected function addMenus():void
		{
			var logPriorityMenu:LogPriorityMenu = new LogPriorityMenu();
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
		

		private function onChannelsLinkClicked(link:String):void
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
	}
}
