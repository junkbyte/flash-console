package com.junkbyte.console.events {
	import flash.events.Event;
	/**
	 * @author LuAye
	 */
	public class ConsoleEvent extends Event
	{
		
		public static const CONSOLE_STARTED:String = "consoleStarted";
		
		public static const CONSOLE_SHOWN:String = "consoleShown";
		public static const CONSOLE_HIDDEN:String = "consoleHidden";
		
		public static const UPDATE_DATA:String = "updateData";
		public static const DATA_UPDATED:String = "dataUpdated";
		
		public var msDelta:uint;
		
		public function ConsoleEvent(type:String)
		{
            super(type, false, false);
		}
		
		public static function create(type:String):ConsoleEvent
		{
			return new ConsoleEvent(type);
		}
	}
}
