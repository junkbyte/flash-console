package com.junkbyte.console.interfaces {
	import com.junkbyte.console.Console;

	public interface IConsoleModule {
		
		function registerConsole(console:Console):void;
		function unregisterConsole(console:Console):void;
		
		function getModuleName():String;
		
	}
}
