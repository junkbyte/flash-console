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
	import com.junkbyte.console.events.ConsoleLogEvent;
	import com.junkbyte.console.interfaces.IConsoleMenuItem;
	import com.junkbyte.console.interfaces.IMainMenu;
	import com.junkbyte.console.modules.ConsoleModuleNames;
	import com.junkbyte.console.view.ChannelsPanel;
	import com.junkbyte.console.view.ConsolePanel;
	import com.junkbyte.console.view.helpers.ConsoleTextRoller;
	import com.junkbyte.console.vos.ConsoleMenuItem;

	import flash.events.Event;
	import flash.events.TextEvent;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;

	[Event(name = "change", type = "flash.events.Event")]
	public class MainPanelMenu extends MainPanelSubArea implements IMainMenu
	{
		public static const NAME:String = "mainPanelMenu";
		protected var _textField:TextField;

		protected var _menus:Vector.<IConsoleMenuItem>;
		protected var _needsUpdate:Boolean = true;

		private var minimizerMenu:ConsoleMenuItem;
		private var hasChannelsPanel:Boolean;

		public var mini:Boolean;

		public function MainPanelMenu(parentPanel:ConsolePanel)
		{
			super(parentPanel);
			_menus = new Vector.<IConsoleMenuItem>();

			_textField = new TextField();
			_textField.name = "menuField";
			_textField.wordWrap = true;
			_textField.multiline = true;
			_textField.autoSize = TextFieldAutoSize.RIGHT;

			addModuleRegisteryCallback(new ModuleNameMatcher(ConsoleModuleNames.CHANNELS_PANEL), channelsPanelRegistered, channelsPanelUnregistered);
		}

		override public function getModuleName():String
		{
			return NAME;
		}

		public function get textField():TextField
		{
			return _textField;
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

			initBuildInMenus();
		}

		override protected function unregisteredFromConsole():void
		{
			super.unregisteredFromConsole();

			display.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			console.logger.logs.removeEventListener(ConsoleLogEvent.CHANNELS_CHANGED, onChannelsChanged);

			mainPanel.unregisterMoveDragger(textField);
			removeChild(textField);
		}

		protected function initBuildInMenus():void
		{
			minimizerMenu = new ConsoleMenuItem("", onMinimizeMenuClick);
			minimizerMenu.sortPriority = -100;
			updateMinimizeMenu();
			addMenu(minimizerMenu);

			var divider:ConsoleMenuItem = new ConsoleMenuItem(" ¦ ");
			divider.sortPriority = -1;
			addMenu(divider);
		}

		private function updateMinimizeMenu(e:Event = null):void
		{
			minimizerMenu.name = mini ? "‹" : "›";
			minimizerMenu.tooltip = mini ? "Expand menu" : "Minimize menu";
		}

		protected function onMinimizeMenuClick():void
		{
			mini = !mini;
			updateMinimizeMenu();
			minimizerMenu.announceChanged();
		}

		protected function onEnterFrame(event:Event):void
		{
			if (_needsUpdate)
			{
				_needsUpdate = false;
				update();
			}
		}

		protected function channelsPanelRegistered(module:ChannelsPanel):void
		{
			hasChannelsPanel = true;
			_needsUpdate = true;
		}

		protected function channelsPanelUnregistered(module:ChannelsPanel):void
		{
			hasChannelsPanel = false;
			_needsUpdate = true;
		}

		private function onChannelsChanged(e:Event):void
		{
			if (!hasChannelsPanel)
			{
				_needsUpdate = true;
			}
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

		public function addMenu(menu:IConsoleMenuItem):void
		{
			var index:int = _menus.indexOf(menu);
			if (index < 0)
			{
				_menus.push(menu);
				_menus.sort(menuSorter);
				menu.addEventListener(Event.CHANGE, onMenuChanged, false, 0, true);
			}
			_needsUpdate = true;
		}

		public function removeMenu(menu:IConsoleMenuItem):void
		{
			var index:int = _menus.indexOf(menu);
			if (index >= 0)
			{
				_menus.splice(index, 1);
				menu.removeEventListener(Event.CHANGE, onMenuChanged);
			}
			_needsUpdate = true;
		}

		protected function menuSorter(a:IConsoleMenuItem, b:IConsoleMenuItem):int
		{
			var pA:Number = a.getSortPriority();
			var pB:Number = b.getSortPriority();
			if (pA > pB)
			{
				return 1;
			}
			else if (pA < pB)
			{
				return -1;
			}
			return 0;
		}

		protected function onMenuChanged(event:Event):void
		{
			_needsUpdate = true;
		}

		public function update():void
		{
			var str:String = "<r><high><menu><b> ";
			if (mini || !style.topMenu)
			{
				str += printMinimizedMenu();
			}
			else
			{
				if (hasChannelsPanel == false)
				{
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
			if (menu.isVisible() == false)
			{
				return "";
			}
			var str:String = menu.getName();
			if (menu.isClickable())
			{
				str = " <a href=\"event:menu_" + index + "\">" + str + "</a>";
			}
			if (menu.isActive())
			{
				return "<menuHi>" + str + "</menuHi>";
			}
			return str;
		}

		private function linkHandler(e:TextEvent):void
		{
			_textField.setSelection(0, 0);
			var t:String = e.text;
			if (t.substring(0, 5) == "menu_")
			{
				var menu:IConsoleMenuItem = getMenuAtIndex(uint(t.substring(5)));
				if (menu)
				{
					menu.onClick();
				}
			}
		}

		private function printMenus():String
		{
			var str:String = "";
			var modulesLen:uint = _menus.length;

			for (var i:int = modulesLen - 1; i >= 0; i--)
			{
				str += createMenuString(_menus[i], i);
			}
			return str;
		}

		private function printMinimizedMenu():String
		{
			var index:int = _menus.indexOf(minimizerMenu);
			return createMenuString(minimizerMenu, index);
		}

		private function getMenuAtIndex(index:uint):IConsoleMenuItem
		{
			return _menus[index];
		}

		private function textRollOverHandler(e:TextEvent):void
		{
			var t:String = e.text ? e.text.replace("event:", "") : "";
			if (t.substring(0, 5) == "menu_")
			{
				var menu:IConsoleMenuItem = getMenuAtIndex(uint(t.substring(5)));
				t = menu.getTooltip();
			}
			mainPanel.setTooltip(t);
		}

	}
}
