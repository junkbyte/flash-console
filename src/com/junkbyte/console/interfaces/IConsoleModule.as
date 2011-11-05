package com.junkbyte.console.interfaces
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.core.ConsoleModulesManager;
	
	import flash.events.IEventDispatcher;

	public interface IConsoleModule extends IEventDispatcher
	{
		function getModuleName():String; // can be null if other modules don't depend on this module
		
		function setConsole(newConsole:Console):void;
	}
}
