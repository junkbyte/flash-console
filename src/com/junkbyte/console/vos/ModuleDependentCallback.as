package com.junkbyte.console.vos
{
	import com.junkbyte.console.interfaces.IConsoleModule;
	import com.junkbyte.console.interfaces.IDependentConsoleModule;

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