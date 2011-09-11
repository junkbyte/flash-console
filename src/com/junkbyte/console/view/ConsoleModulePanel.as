package com.junkbyte.console.view
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.core.ConsoleModules;
	import com.junkbyte.console.interfaces.IConsoleModule;
	import com.junkbyte.console.interfaces.IDependentConsoleModule;
	import com.junkbyte.console.vos.ConsoleModuleMatch;
	
	public class ConsoleModulePanel extends ConsolePanel implements IConsoleModule, IDependentConsoleModule
	{
		public function ConsoleModulePanel(m:ConsoleModules)
		{
			super(m);
		}
		
		public function getModuleName():String
		{
			return null;
		}
		
		public function registeredToConsole(console:Console):void
		{
			central = console.modules;
		}
		
		public function unregisteredFromConsole(console:Console):void
		{
			central = null;
		}
		
		public function getDependentModules():Vector.<ConsoleModuleMatch>
		{
			return new Vector.<ConsoleModuleMatch>();
		}
		
		public function dependentModuleRegistered(module:IConsoleModule):void
		{
			
		}
		
		public function dependentModuleUnregistered(module:IConsoleModule):void
		{
			
		}
	}
}