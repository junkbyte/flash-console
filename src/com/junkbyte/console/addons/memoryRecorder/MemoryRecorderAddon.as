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
package com.junkbyte.console.addons.memoryRecorder
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.KeyBind;

	public class MemoryRecorderAddon
	{

		public static function registerToConsole(console:Console, key:String = "r"):void
		{
			MemoryRecorder.instance.reportCallback = function(... args:Array):void
			{
				args.unshift("R");
				console.infoch.apply(null, args);
			}

			var onMemoryRecorderStart:Function = function():void
			{
				if (MemoryRecorder.instance.running == false)
				{
					MemoryRecorder.instance.start();
				}
			}

			var onMemoryRecorderEnd:Function = function():void
			{
				if (MemoryRecorder.instance.running)
				{
					console.clear("R");
					MemoryRecorder.instance.end();
				}
			}

			console.bindKey(new KeyBind(key), onMemoryRecorderStart);
			console.bindKey(new KeyBind(key, false, false, false, true), onMemoryRecorderEnd);
		}

	}
}
