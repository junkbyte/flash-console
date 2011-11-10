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
package com.junkbyte.console.events {
	import flash.events.Event;
	/**
	 * @author LuAye
	 */
	public class ConsoleEvent extends Event
	{
		
		public static const STARTED:String = "started";
		
		public static const SHOWN:String = "shown";
		public static const HIDDEN:String = "hidden";
		
		public static const PAUSED:String = "paused";
		public static const RESUMED:String = "resumed";
		
		public static const UPDATE_DATA:String = "updateData";
		public static const DATA_UPDATED:String = "dataUpdated";
		
		public static const UPDATE_DISPLAY:String = "updateDisplay";
		
		public var msDelta:uint;
		
		public function ConsoleEvent(type:String)
		{
            super(type, false, false);
		}
		
		public static function create(type:String):ConsoleEvent
		{
			return new ConsoleEvent(type);
		}
	}
}
