package com.junkbyte.console.modules.graphing
{
	import com.junkbyte.console.view.ConsolePanel;

	import flash.events.EventDispatcher;
	import flash.geom.Rectangle;

	[Event(name = "push", type = "com.junkbyte.console.modules.graphing.GraphingGroupEvent")]
	public class GraphingGroup extends EventDispatcher
	{

		public static var defaultGraphingPanelModuleClass:Class = GraphingPanelModule;

		public var fixedMin:Number;
		public var fixedMax:Number;

		public var inverted:Boolean;

		public var area:Rectangle;

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
	}
}
