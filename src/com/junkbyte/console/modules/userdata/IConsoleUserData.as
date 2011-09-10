package com.junkbyte.console.modules.userdata
{
	public interface IConsoleUserData
	{
		
		function get data():Object;
		function updateData(key:String = null):void;
		
	}
}