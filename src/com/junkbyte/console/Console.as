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
package com.junkbyte.console
{
	import com.junkbyte.console.core.ConsoleModules;
	import com.junkbyte.console.core.Logs;
	import com.junkbyte.console.events.ConsoleEvent;
	import com.junkbyte.console.utils.explodeObjectsInConsole;
	import com.junkbyte.console.utils.mapDisplayListInConsole;
	import com.junkbyte.console.view.ConsoleLayer;
	import com.junkbyte.console.view.MainPanel;
	import com.junkbyte.console.vos.Log;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.system.Capabilities;
	import flash.utils.getQualifiedClassName;

	/**
	 * Console is the main class. 
	 * Please see com.junkbyte.console.Cc for documentation as it shares the same properties and methods structure.
	 * @see http://code.google.com/p/flash-console/
	 * @see com.junkbyte.console.Cc
	 */
	public class Console extends EventDispatcher
	{
		protected var _central:ConsoleModules;
		protected var _config:ConsoleConfig;

		[Event(name="consoleStarted", type="com.junkbyte.console.events.ConsoleEvent")]
		public function Console()
		{
		}

		public function start(container:DisplayObjectContainer = null):void
		{
			if (started) throw new Error("Console already started.");

			_central = new ConsoleModules(this, config);
			_central.init();
			_central.report("<b>Console v" + ConsoleVersion.VERSION + ConsoleVersion.STAGE + "</b> build " + ConsoleVersion.BUILD + ". " + Capabilities.playerType + " " + Capabilities.version + ".", ConsoleLevel.CONSOLE_EVENT);

			if (container)
			{
				container.addChild(display);
			}
			dispatchEvent(ConsoleEvent.create(ConsoleEvent.CONSOLE_STARTED));
		}

		public function startOnStage(target:DisplayObject):void
		{
			if (!started)
			{
				start();
			}
			if (target)
			{
				if (target.stage)
				{
					target.stage.addChild(display);
				}
				else
				{
					target.addEventListener(Event.ADDED_TO_STAGE, addedToStageHandle, false, 0, true);
				}
			}
		}

		private function addedToStageHandle(e:Event):void
		{
			var mc:DisplayObjectContainer = e.currentTarget as DisplayObjectContainer;
			mc.removeEventListener(Event.ADDED_TO_STAGE, addedToStageHandle);
			mc.stage.addChild(display);
		}

		public function get started():Boolean
		{
			return _central != null;
		}

		//
		// WARNING: Add menu hard references the function and arguments.
		//
		public function addMenu(key:String, callback:Function, args:Array = null, rollover:String = null):void
		{
			throwErrorIfNotStarted("addMenu()");
			_central.display.mainPanel.addMenu(key, callback, args, rollover);
		}

		public function store(name:String, obj:Object, strong:Boolean = false):void
		{
			throwErrorIfNotStarted("store()");
			_central.cl.store(name, obj, strong);
		}

		public function map(container:DisplayObjectContainer, maxstep:uint = 0):void
		{
			throwErrorIfNotStarted("map()");
			mapDisplayListInConsole(this, container, maxstep, Logs.DEFAULT_CHANNEL);
		}

		public function mapch(channel:*, container:DisplayObjectContainer, maxstep:uint = 0):void
		{
			throwErrorIfNotStarted("mapch()");
			mapDisplayListInConsole(this, container, maxstep, ConsoleModules.MakeChannelName(channel));
		}

		public function explode(obj:Object, depth:int = 3):void
		{
			addLine(new Array(explodeObjectsInConsole(this, obj, depth)), 1, null, false, true);
		}

		public function explodech(channel:*, obj:Object, depth:int = 3):void
		{
			addLine(new Array(explodeObjectsInConsole(this, obj, depth)), 1, channel, false, true);
		}

		public function get paused():Boolean
		{
			throwErrorIfNotStarted("paused");
			return _central.paused;
		}

		public function set paused(newV:Boolean):void
		{
			throwErrorIfNotStarted("paused");
			_central.paused = newV;
		}

		//
		//
		//
		public function setViewingChannels(...channels:Array):void
		{
			throwErrorIfNotStarted("minimumPriority");
			_central.display.mainPanel.setViewingChannels.apply(this, channels);
		}

		public function setIgnoredChannels(...channels:Array):void
		{
			throwErrorIfNotStarted("minimumPriority");
			_central.display.mainPanel.setIgnoredChannels.apply(this, channels);
		}

		public function set minimumPriority(level:uint):void
		{
			throwErrorIfNotStarted("minimumPriority");
			_central.display.mainPanel.priority = level;
		}

		protected function addLine(strings:Array, priority:int = 0, channel:* = null, isRepeating:Boolean = false, html:Boolean = false, stacks:int = -1):void
		{
			if(started)
			{
				_central.logs.addLine(strings, priority, channel, isRepeating, html, stacks);
			}
		}

		public function addSlashCommand(name:String, callback:Function, desc:String = "", alwaysAvailable:Boolean = true, endOfArgsMarker:String = ";"):void
		{
			_central.cl.addSlashCommand(name, callback, desc, alwaysAvailable, endOfArgsMarker);
		}
		
		//
		// LOGGING
		//
		public function add(string:*, priority:int = 2, isRepeating:Boolean = false):void
		{
			addLine([string], priority, Logs.DEFAULT_CHANNEL, isRepeating);
		}

		public function stack(string:*, depth:int = -1, priority:int = 5):void
		{
			addLine([string], priority, Logs.DEFAULT_CHANNEL, false, false, depth >= 0 ? depth : _central.config.defaultStackDepth);
		}

		public function stackch(channel:*, string:*, depth:int = -1, priority:int = 5):void
		{
			addLine([string], priority, channel, false, false, depth >= 0 ? depth : _central.config.defaultStackDepth);
		}

		public function log(...strings):void
		{
			addLine(strings, ConsoleLevel.LOG);
		}

		public function info(...strings):void
		{
			addLine(strings, ConsoleLevel.INFO);
		}

		public function debug(...strings):void
		{
			addLine(strings, ConsoleLevel.DEBUG);
		}

		public function warn(...strings):void
		{
			addLine(strings, ConsoleLevel.WARN);
		}

		public function error(...strings):void
		{
			addLine(strings, ConsoleLevel.ERROR);
		}

		public function fatal(...strings):void
		{
			addLine(strings, ConsoleLevel.FATAL);
		}

		public function ch(channel:*, string:*, priority:Number = 2, isRepeating:Boolean = false):void
		{
			addLine([string], priority, channel, isRepeating);
		}

		public function logch(channel:*, ...strings):void
		{
			addLine(strings, ConsoleLevel.LOG, channel);
		}

		public function infoch(channel:*, ...strings):void
		{
			addLine(strings, ConsoleLevel.INFO, channel);
		}

		public function debugch(channel:*, ...strings):void
		{
			addLine(strings, ConsoleLevel.DEBUG, channel);
		}

		public function warnch(channel:*, ...strings):void
		{
			addLine(strings, ConsoleLevel.WARN, channel);
		}

		public function errorch(channel:*, ...strings):void
		{
			addLine(strings, ConsoleLevel.ERROR, channel);
		}

		public function fatalch(channel:*, ...strings):void
		{
			addLine(strings, ConsoleLevel.FATAL, channel);
		}

		public function addCh(channel:*, strings:Array, priority:int = 2, isRepeating:Boolean = false):void
		{
			addLine(strings, priority, channel, isRepeating);
		}

		public function addHTML(...strings):void
		{
			addLine(strings, 2, Logs.DEFAULT_CHANNEL, false, testHTML(strings));
		}

		public function addHTMLch(channel:*, priority:int, ...strings):void
		{
			addLine(strings, priority, channel, false, testHTML(strings));
		}

		private function testHTML(args:Array):Boolean
		{
			try
			{
				new XML("<p>" + args.join("") + "</p>");
				// OR use RegExp?
			}
			catch(err:Error)
			{
				return false;
			}
			return true;
		}

		//
		public function get modules():ConsoleModules
		{
			throwErrorIfNotStarted("modules");
			return _central;
		}

		public function get display():ConsoleLayer
		{
			throwErrorIfNotStarted("display");
			return _central.display;
		}

		public function get config():ConsoleConfig
		{
			if (_config == null) _config = new ConsoleConfig();
			return _config;
		}

		private function throwErrorIfNotStarted(propName:String = null):void
		{
			if (!started)
			{
				if (propName)
				{
					propName = "\"" + propName + "\"";
				}
				throw new Error("Call to console " + propName + " before Console have started.");
			}
		}

		//
		//
		//
		public function clear(channel:String = null):void
		{
			if (!started) return;
			_central.logs.clear(channel);
			if (!paused) _central.display.mainPanel.updateToBottom();
			_central.display.updateMenu();
		}

		public function getAllLog(splitter:String = "\r\n"):String
		{
			throwErrorIfNotStarted("getAllLog()");
			return _central.logs.getLogsAsString(splitter);
		}
	}
}