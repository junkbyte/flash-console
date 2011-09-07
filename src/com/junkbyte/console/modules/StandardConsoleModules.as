package com.junkbyte.console.modules
{
	import com.junkbyte.console.Cc;
	import com.junkbyte.console.Console;
	import com.junkbyte.console.modules.displayRoller.DisplayRollerModule;
	import com.junkbyte.console.modules.keyStates.KeyStates;
	import com.junkbyte.console.modules.ruler.RulerModule;
	import com.junkbyte.console.modules.unCaughtErrorsListenerModule.UnCaughtErrorsListenerModule;

	public class StandardConsoleModules
	{
		public static function registerToConsole(targetConsole:Console = null):void
		{
			if(targetConsole == null)
			{
				targetConsole = Cc;
			}
			if(targetConsole == null)
			{
				return;
			}
			
			targetConsole.central.registerModule(new KeyStates());
			targetConsole.central.registerModule(new RulerModule());
			targetConsole.central.registerModule(new DisplayRollerModule());
			targetConsole.central.registerModule(new UnCaughtErrorsListenerModule());
		}
	}
}