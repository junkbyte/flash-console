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
	import com.junkbyte.console.core.ConsoleModulesManager;
	import com.junkbyte.console.core.Logs;
	import com.junkbyte.console.events.ConsoleEvent;
	import com.junkbyte.console.utils.explodeObjectsInConsole;
	import com.junkbyte.console.utils.makeConsoleChannel;
	import com.junkbyte.console.utils.mapDisplayListInConsole;
	import com.junkbyte.console.view.ConsoleLayer;

	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.system.Capabilities;
	import flash.utils.getTimer;

	/**
	 * Console is the main class. 
	 * Please see com.junkbyte.console.Cc for documentation as it shares the same properties and methods structure.
	 * @see http://code.google.com/p/flash-console/
	 * @see com.junkbyte.console.Cc
	 */
	[Event(name="consoleStarted", type="com.junkbyte.console.events.ConsoleEvent")]
	[Event(name="consoleShown", type="com.junkbyte.console.events.ConsoleEvent")]
	[Event(name="consoleHidden", type="com.junkbyte.console.events.ConsoleEvent")]
	[Event(name="paused", type="com.junkbyte.console.events.ConsoleEvent")]
	[Event(name="resumed", type="com.junkbyte.console.events.ConsoleEvent")]
	[Event(name="updateData", type="com.junkbyte.console.events.ConsoleEvent")]
	[Event(name="dataUpdated", type="com.junkbyte.console.events.ConsoleEvent")]
	public class Console extends EventDispatcher
	{
		protected var _modules:ConsoleModulesManager;
		protected var _display:ConsoleLayer;
		
		protected var _config:ConsoleConfig;
		protected var _paused:Boolean;
		
		protected var _lastTimer:Number;
		
		/**
		 * Console is the main class.
		 * @see http://code.google.com/p/flash-console/
		 */
		public function Console()
		{
		}

		public function start(container:DisplayObjectContainer = null):void
		{
			if (started) throw new Error("Console already started.");
			
			config.style.updateStyleSheet();
			
			_modules = new ConsoleModulesManager(this);
			
			_modules.init();
			_display = new ConsoleLayer(this);
			
			
			if (config.keystrokePassword) _display.visible = false;
			_display.start();

			_modules.report("<b>Console v" + ConsoleVersion.VERSION + ConsoleVersion.STAGE + "</b> build " + ConsoleVersion.BUILD + ". " + Capabilities.playerType + " " + Capabilities.version + ".", ConsoleLevel.CONSOLE_EVENT);
			
			_modules.display.addEventListener(Event.ENTER_FRAME, _onEnterFrame);
			
			if (container)
			{
				container.addChild(layer);
			}
			dispatchEvent(ConsoleEvent.create(ConsoleEvent.STARTED));
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
					target.stage.addChild(layer);
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
			mc.stage.addChild(layer);
		}

		public function get started():Boolean
		{
			return _modules != null;
		}
		
		protected function _onEnterFrame(e:Event):void
		{
			var timeNow:Number = getTimer();
			var msDelta:uint = timeNow - _lastTimer;
			_lastTimer = timeNow;
			//update data
			var event:ConsoleEvent = ConsoleEvent.create(ConsoleEvent.UPDATE_DATA);
			event.msDelta = msDelta;
			dispatchEvent(event);
			//update view
			event = ConsoleEvent.create(ConsoleEvent.DATA_UPDATED);
			event.msDelta = msDelta;
			dispatchEvent(event);
		}

		public function map(container:DisplayObjectContainer, maxstep:uint = 0):void
		{
			throwErrorIfNotStarted("map()");
			mapDisplayListInConsole(this, container, maxstep, Logs.DEFAULT_CHANNEL);
		}

		public function mapch(channel:*, container:DisplayObjectContainer, maxstep:uint = 0):void
		{
			throwErrorIfNotStarted("mapch()");
			mapDisplayListInConsole(this, container, maxstep, makeConsoleChannel(channel));
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
			return _paused;
		}

		public function set paused(newV:Boolean):void
		{
			if (_paused == newV) return;
			if (newV) _modules.report("Paused", ConsoleLevel.CONSOLE_STATUS);
			else _modules.report("Resumed", ConsoleLevel.CONSOLE_STATUS);
			_paused = newV;
			layer.mainPanel.traces.setPaused(newV);
			dispatchEvent(new Event( _paused ? ConsoleEvent.PAUSED : ConsoleEvent.RESUMED ));
		}

		//
		//
		//
		public function setViewingChannels(...channels:Array):void
		{
			throwErrorIfNotStarted("minimumPriority");
			_modules.display.mainPanel.traces.setViewingChannels.apply(this, channels);
		}

		public function setIgnoredChannels(...channels:Array):void
		{
			throwErrorIfNotStarted("minimumPriority");
			_modules.display.mainPanel.traces.setIgnoredChannels.apply(this, channels);
		}

		public function set minimumPriority(level:uint):void
		{
			throwErrorIfNotStarted("minimumPriority");
			_modules.display.mainPanel.traces.priority = level;
		}

		protected function addLine(strings:Array, priority:int = 0, channel:* = null, isRepeating:Boolean = false, html:Boolean = false, stacks:int = -1):void
		{
			if(started)
			{
				_modules.logs.addLine(strings, priority, channel, isRepeating, html, stacks);
			}
		}

		public function addSlashCommand(name:String, callback:Function, desc:String = "", alwaysAvailable:Boolean = true, endOfArgsMarker:String = ";"):void
		{
			_modules.cl.addSlashCommand(name, callback, desc, alwaysAvailable, endOfArgsMarker);
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
			addLine([string], priority, Logs.DEFAULT_CHANNEL, false, false, depth >= 0 ? depth : _modules.config.defaultStackDepth);
		}

		public function stackch(channel:*, string:*, depth:int = -1, priority:int = 5):void
		{
			addLine([string], priority, channel, false, false, depth >= 0 ? depth : _modules.config.defaultStackDepth);
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
		public function get modules():ConsoleModulesManager
		{
			throwErrorIfNotStarted("modules");
			return _modules;
		}

		public function get layer():ConsoleLayer
		{
			throwErrorIfNotStarted("layer");
			return _display;
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
			_modules.logs.clear(channel);
			if (!paused) _modules.display.mainPanel.traces.updateToBottom();
		}

		public function getAllLog(splitter:String = "\r\n"):String
		{
			throwErrorIfNotStarted("getAllLog()");
			return _modules.logs.getLogsAsString(splitter);
		}
	}
}