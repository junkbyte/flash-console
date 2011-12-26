package com.junkbyte.console.modules.graphing.fps
{
	import com.junkbyte.console.modules.graphing.GraphingGroup;
	import com.junkbyte.console.modules.graphing.GraphingPanelModule;

	public class FPSGraphingPanelModule extends GraphingPanelModule
	{
		public function FPSGraphingPanelModule(group:GraphingGroup)
		{
			super(group);
		}

		override protected function initToConsole():void
		{
			super.initToConsole();
			x = console.mainPanel.x + console.mainPanel.width - 160;
			y = console.mainPanel.y + 15;
		}
	}
}
