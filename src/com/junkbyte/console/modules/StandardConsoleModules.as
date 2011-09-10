package com.junkbyte.console.modules
{
	import com.junkbyte.console.Cc;
	import com.junkbyte.console.Console;
	import com.junkbyte.console.modules.displayRoller.DisplayRollerModule;
	import com.junkbyte.console.modules.keyStates.KeyStates;
	import com.junkbyte.console.modules.ruler.RulerModule;
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
			
			console.central.registerModule(new UserData());
			console.central.registerModule(new KeyStates());
			console.central.registerModule(new RulerModule());
			console.central.registerModule(new DisplayRollerModule());
			console.central.registerModule(new UnCaughtErrorsListenerModule());
		}
	}
}