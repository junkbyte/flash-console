package com.junkbyte.console.interfaces
{
	import com.junkbyte.console.vos.ConsoleModuleMatch;

	public interface IDependentConsoleModule
	{
		function getDependentModules():Vector.<ConsoleModuleMatch>;
		function dependentModuleRegistered(module:IConsoleModule):void;
		function dependentModuleUnregistered(module:IConsoleModule):void;
	}
}
