package com.junkbyte.console.modules.graphing
{
	import flash.events.Event;

	public class GraphingEvent extends Event
	{
		
		public static const ADD_GROUP:String = "addGroup";
		public static const REMOVE_GROUP:String = "removeGroup";
		
		public var group:GraphingGroup;
		public var values:Vector.<Number>;
		
		public function GraphingEvent(type:String)
		{
			super(type,false,false);
		}

		public override function clone():Event
		{
			var event:GraphingEvent = new GraphingEvent(type);
			event.values = values;
			event.group = group;
			return event;
		}

		public override function toString():String
		{
			return formatToString("GraphingEvent");
		}
	}
}