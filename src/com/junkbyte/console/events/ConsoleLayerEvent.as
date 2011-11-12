package com.junkbyte.console.events
{

	import com.junkbyte.console.view.ConsolePanel;

	import flash.events.Event;

	public class ConsoleLayerEvent extends Event
	{
		public static const PANEL_ADDED:String = "panelAdded";

		public static const PANEL_REMOVED:String = "panelRemoved";

		public var panel:ConsolePanel;

		public function ConsoleLayerEvent(type:String, panel:ConsolePanel)
		{
			super(type);

			this.panel = panel;
		}

		override public function clone():Event
		{
			return new ConsoleLayerEvent(type, panel);
		}
	}
}
