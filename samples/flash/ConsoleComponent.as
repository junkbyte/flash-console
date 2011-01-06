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
package {
	import com.junkbyte.console.Cc;
	import com.junkbyte.console.ConsoleChannel;

	import flash.display.MovieClip;

	//
	// This class is for exporting to SWC from flash CS3 (and above) with a component icon.
	// To import SWC to CS3:
	// Copy the swc into C:\Program Files\Adobe\Adobe Flash CS3\en\Configuration\Components\ 
	// Restart flash. Look in components panel.
	//
	// To import SWC to CS4 (and above):
	// Go to publish settings > Link library > point to SWC
	//
	public class ConsoleComponent extends MovieClip{
		// just to have a reference to Cc, so that flash will include the source when compiling
		public static function get CONSOLE():Class{
			return Cc;
		}
		public static function get CHANNEL():Class{
			return ConsoleChannel;
		}
	}
}
