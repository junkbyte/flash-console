package com.junkbyte.console.modules.commandLine
{
	/**
	 * @author LuAye
	 */
	public interface ICommandLine
	{
		function get scopeString():String;
		
		function run(str:String, params:* = null):*;

		function addInternalSlashCommand(n:String, callback:Function, desc:String = "", allow:Boolean = false, endOfArgsMarker:String = ";"):void;

		function addSlashCommand(n:String, callback:Function, desc:String = "", alwaysAvailable:Boolean = true, endOfArgsMarker:String = ";"):void;
		
		function getHintsFor(str:String, max:uint):Array;
	}
}
