package com.junkbyte.console.core
{
	import com.junkbyte.console.interfaces.IConsoleModule;
	import com.junkbyte.console.interfaces.IDependentConsoleModule;
	import com.junkbyte.console.vos.ConsoleModuleMatch;

	public class ModuleDependentCallback
	{
		public var moduleMatch:ConsoleModuleMatch;
		public var dependentModule:IDependentConsoleModule;
		
		public function ModuleDependentCallback(interestedModule:ConsoleModuleMatch, callbackModule:IDependentConsoleModule):void
		{
			this.moduleMatch = interestedModule;
			this.dependentModule = callbackModule;
		}
	}
}