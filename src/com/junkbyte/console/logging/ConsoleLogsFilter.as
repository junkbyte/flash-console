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
package com.junkbyte.console.logging
{
	import com.junkbyte.console.ConsoleChannels;
	import com.junkbyte.console.core.ConsoleModule;
	import com.junkbyte.console.interfaces.IKeyStates;
	import com.junkbyte.console.modules.ConsoleModuleNames;
	import com.junkbyte.console.utils.makeConsoleChannel;
	import com.junkbyte.console.vos.Log;

	import flash.events.Event;

	[Event(name = "channelInterestsChanged", type = "flash.events.Event")]
	[Event(name = "filterPriorityChanged", type = "flash.events.Event")]
	public class ConsoleLogsFilter extends ConsoleModule
	{
		public static const CHANNEL_INTERESTS_CHANGED:String = "channelInterestsChanged";
		public static const FILTER_PRIORITY_CHANGED:String = "filterPriorityChanged";

		private var _viewingChannels:Vector.<String> = new Vector.<String>();
		private var _ignoredChannels:Vector.<String> = new Vector.<String>();
		private var _priority:uint;

		public function ConsoleLogsFilter()
		{
			super();
		}

		override public function getModuleName():String
		{
			return ConsoleModuleNames.LOGS_FILTER;
		}

		public function getChannelsLink(maxChannels:uint = uint.MAX_VALUE):String
		{
			var str:String = "<chs>";
			var channels:Array = console.logger.logs.getChannels();
			var len:int = channels.length;
			if (len > maxChannels)
			{
				len = maxChannels;
			}
			var filtering:Boolean = _viewingChannels.length > 0 || _ignoredChannels.length > 0;
			for (var i:int = 0; i < len; i++)
			{
				var channel:String = channels[i];
				var channelTxt:String = ((!filtering && i == 0) || (filtering && i != 0 && chShouldShow(channel))) ? "<ch><b>" + channel + "</b></ch>" : channel;
				str += "<a href=\"event:channel_" + channel + "\">[" + channelTxt + "]</a> ";
			}
			if (len != channels.length)
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
				setViewingChannels(chn);
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
			//_defaultOutputProvider.changed();
			dispatchEvent(new Event(FILTER_PRIORITY_CHANGED));
		}

		public function get priority():uint
		{
			return _priority;
		}

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

		protected function chShouldShow(ch:String):Boolean
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
			//_defaultOutputProvider.changed();
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
			//_defaultOutputProvider.changed();
			announceChannelInterestChanged();
		}

		public function get ignoredChannels():Vector.<String>
		{
			return _ignoredChannels;
		}

		protected function announceChannelInterestChanged():void
		{
			dispatchEvent(new Event(CHANNEL_INTERESTS_CHANGED));
		}
	}
}
