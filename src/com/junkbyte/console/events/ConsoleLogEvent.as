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
package com.junkbyte.console.events
{
	import com.junkbyte.console.vos.Log;
	
	import flash.events.Event;

	public class ConsoleLogEvent extends Event
	{
		public static const ENTRTY_ADDED:String = "entryadded";
		public static const ENTRIES_CHANGED:String = "entriesChanged";
		public static const CHANNEL_ADDED:String = "channelAdded";
		public static const CHANNELS_CHANGED:String = "channelsChanged";

		public var entry:Log;
		public var channel:String;

		public function ConsoleLogEvent(type:String)
		{
			super(type,false,false);
		}

		public override function clone():Event
		{
			var event:ConsoleLogEvent = new ConsoleLogEvent(type);
			event.entry = entry;
			event.channel = channel;
			return event;
		}

		public override function toString():String
		{
			return formatToString("ConsoleLogEvent","entry","channel");
		}
	}
}