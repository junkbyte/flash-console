package com.junkbyte.console.interfaces
{
	import com.junkbyte.console.Console;

	public interface IConsoleModule
	{
		function getModuleName():String; // can be null if other modules don't depend on this module
		
		function registeredToConsole(console:Console):void;
		function unregisteredFromConsole(console:Console):void;
	}
}
