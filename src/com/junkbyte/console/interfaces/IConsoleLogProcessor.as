package com.junkbyte.console.interfaces
{
	import com.junkbyte.console.vos.LogEntry;

	public interface IConsoleLogProcessor
	{
		function process(entry:LogEntry):void;
	}
}