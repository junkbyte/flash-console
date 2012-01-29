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
package com.junkbyte.console
{

	import com.junkbyte.console.core.ConsoleModulesManager;
	import com.junkbyte.console.core.ConsoleTicker;
	import com.junkbyte.console.events.ConsoleEvent;
	import com.junkbyte.console.logging.ConsoleLogger;
	import com.junkbyte.console.logging.ConsoleLogs;
	import com.junkbyte.console.logging.ConsoleLogsFilter;
	import com.junkbyte.console.modules.ConsoleModuleNames;
	import com.junkbyte.console.view.ConsoleLayer;
	import com.junkbyte.console.view.mainPanel.MainPanel;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.system.Capabilities;

	[Event(name = "consoleStarted", type = "com.junkbyte.console.events.ConsoleEvent")]
	[Event(name = "consoleShown", type = "com.junkbyte.console.events.ConsoleEvent")]
	[Event(name = "consoleHidden", type = "com.junkbyte.console.events.ConsoleEvent")]
	[Event(name = "paused", type = "com.junkbyte.console.events.ConsoleEvent")]
	[Event(name = "resumed", type = "com.junkbyte.console.events.ConsoleEvent")]
	public class Console extends EventDispatcher
	{

		protected var _modules:ConsoleModulesManager;

		protected var _layer:ConsoleLayer;

		protected var _paused:Boolean;

		protected var _style:ConsoleStyle = new ConsoleStyle();

		public function Console()
		{
		}

		public function startOnStage(target:DisplayObject):void
		{
			if (!started)
			{
				start();
			}
			if (target != null)
			{
				if (target.stage != null)
				{
					addToContainer(target.stage);
				}
				else
				{
					target.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
				}
			}
		}

		public function start(container:DisplayObjectContainer = null):void
		{
			if (started)
			{
				addToContainer(container);
				return;
			}
			init();
			sayIntro();
			addToContainer(container);
			dispatchEvent(ConsoleEvent.create(ConsoleEvent.STARTED));
		}

		protected function init():void
		{
			style.updateStyleSheet();
			
			_layer = new ConsoleLayer();
			
			initModulesManager();
			registerLoggingModules();
			
			_layer.initUsingConsole(this);
		}

		protected function initModulesManager():void
		{
			_modules = new ConsoleModulesManager(this);
		}

		protected function registerLoggingModules():void
		{
			modules.registerModule(new ConsoleLogs());
			modules.registerModule(new ConsoleLogsFilter());
			if(CLog != null && CLog.console == null)
			{
				modules.registerModule(CLog);
			}
			else
			{
				modules.registerModule(new ConsoleLogger());
			}
		}

		protected function sayIntro():void
		{
			logger.report("<b>Console v" + ConsoleVersion.VERSION + ConsoleVersion.STAGE + "</b> build " + ConsoleVersion.BUILD + ". " + Capabilities.playerType + " " + Capabilities.version + ".", ConsoleLevel.CONSOLE_EVENT);
		}

		protected function addToContainer(container:DisplayObjectContainer):void
		{
			if (container != null)
			{
				container.addChild(layer);
			}
		}

		private function onAddedToStage(e:Event):void
		{
			var mc:DisplayObjectContainer = e.currentTarget as DisplayObjectContainer;
			mc.removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			addToContainer(mc.stage);
		}

		public function get started():Boolean
		{
			return _modules != null;
		}

		public function get paused():Boolean
		{
			return _paused;
		}

		public function set paused(newV:Boolean):void
		{
			if (_paused == newV)
			{
				return;
			}
			if (newV)
			{
				logger.report("Paused", ConsoleLevel.CONSOLE_STATUS);
			}
			else
			{
				logger.report("Resumed", ConsoleLevel.CONSOLE_STATUS);
			}
			_paused = newV;

			var eventType:String = _paused ? ConsoleEvent.PAUSED : ConsoleEvent.RESUMED;
			dispatchEvent(ConsoleEvent.create(eventType));
		}

		public function get modules():ConsoleModulesManager
		{
			return _modules;
		}

		public function get layer():ConsoleLayer
		{
			return _layer;
		}

		public function get style():ConsoleStyle
		{
			return _style;
		}

		public function get logger():ConsoleLogger
		{
			return modules.getModuleByName(ConsoleModuleNames.LOGGER) as ConsoleLogger;
		}

		public function get mainPanel():MainPanel
		{
			return modules.getModuleByName(ConsoleModuleNames.MAIN_PANEL) as MainPanel;
		}
	}
}
