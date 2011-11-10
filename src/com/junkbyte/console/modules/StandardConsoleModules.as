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
package com.junkbyte.console.modules
{
	import com.junkbyte.console.Cc;
	import com.junkbyte.console.Console;
	import com.junkbyte.console.modules.commandLine.SlashCommandLine;
	import com.junkbyte.console.modules.displayRoller.DisplayRoller;
	import com.junkbyte.console.modules.keyStates.KeyStates;
	import com.junkbyte.console.modules.keybinder.KeyBinder;
	import com.junkbyte.console.modules.referencing.ConsoleReferencingModule;
	import com.junkbyte.console.modules.ruler.RulerModule;
	import com.junkbyte.console.modules.stayOnTop.ConsoleStayOnTopModule;
	import com.junkbyte.console.modules.unCaughtErrorsListenerModule.UnCaughtErrorsListenerModule;
	import com.junkbyte.console.modules.userdata.UserData;

	public class StandardConsoleModules
	{
		public static function registerToConsole(console:Console = null):void
		{
			if(console == null)
			{
				console = Cc;
			}
			if(console == null)
			{
				return;
			}
			
			//console.modules.registerModule(new LocalRemoting());
			
			console.modules.registerModule(new ConsoleStayOnTopModule());
			console.modules.registerModule(new UserData());
			console.modules.registerModule(new KeyStates());
			console.modules.registerModule(new ConsoleReferencingModule());
			console.modules.registerModule(new SlashCommandLine());
			console.modules.registerModule(new KeyBinder());
			console.modules.registerModule(new RulerModule());
			console.modules.registerModule(new DisplayRoller());
			console.modules.registerModule(new UnCaughtErrorsListenerModule());
		}
	}
}