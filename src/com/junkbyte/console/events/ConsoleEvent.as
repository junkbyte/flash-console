package com.junkbyte.console.events {
	import flash.events.Event;
	/**
	 * @author LuAye
	 */
	public class ConsoleEvent extends Event
	{
		
		public static const CONSOLE_STARTED:String = "consoleStarted";
		
		public static const MODEL_UPDATE:String = "modelUpdate";
		public static const MODEL_UPDATED:String = "modelUpdated";
		public static const VIEW_UPDATE:String = "viewUpdate";
		public static const VIEW_UPDATED:String = "viewUpdated";
		
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
