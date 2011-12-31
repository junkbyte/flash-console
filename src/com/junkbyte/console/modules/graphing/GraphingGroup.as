package com.junkbyte.console.modules.graphing
{
	import com.junkbyte.console.view.ConsolePanel;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Rectangle;

	[Event(name = "push", type = "com.junkbyte.console.modules.graphing.GraphingGroupEvent")]
	[Event(name="close", type="flash.events.Event")]
	public class GraphingGroup extends EventDispatcher
	{

		public static var defaultGraphingPanelModuleClass:Class = GraphingPanelModule;

		public var updateFrequencyMS:uint = 5;
		
		public var fixedMin:Number;
		public var fixedMax:Number;

		public var inverted:Boolean;

		public var lines:Vector.<GraphingLine> = new Vector.<GraphingLine>();

		public function GraphingGroup()
		{
		}

		public function push(values:Vector.<Number>):void
		{
			var event:GraphingGroupEvent = new GraphingGroupEvent(GraphingGroupEvent.PUSH);
			event.values = values;
			dispatchEvent(event);
		}

		public function createPanel():ConsolePanel
		{
			return new defaultGraphingPanelModuleClass(this);
		}
		
		public function close():void
		{
			dispatchEvent(new Event(Event.CLOSE));
		}
	}
}
