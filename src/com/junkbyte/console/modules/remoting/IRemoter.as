package com.junkbyte.console.modules.remoting
{
	import flash.events.IEventDispatcher;
	import flash.utils.ByteArray;

	public interface IRemoter extends IEventDispatcher
	{
		function get connected():Boolean;
		function get isSender():Boolean;
		function send(command:String, arg:ByteArray = null):Boolean;
		function registerCallback(key:String, fun:Function, latestOnly:Boolean = false):void;
		function login(password:String):void;
		function close():void;
	}
}