package com.junkbyte.console.interfaces
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.vos.ConsoleModuleMatch;

	public interface IDependentConsoleModule
	{
		function getInterestedModules():Vector.<ConsoleModuleMatch>;
		function interestModuleRegistered(module:IConsoleModule):void;
		function interestModuleUnregistered(module:IConsoleModule):void;
		
	}
}
