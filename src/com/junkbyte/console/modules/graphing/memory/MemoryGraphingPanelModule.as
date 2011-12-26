package com.junkbyte.console.modules.graphing.memory
{
	import com.junkbyte.console.modules.graphing.GraphingGroup;
	import com.junkbyte.console.modules.graphing.GraphingPanelModule;

	public class MemoryGraphingPanelModule extends GraphingPanelModule
	{
		public function MemoryGraphingPanelModule(group:GraphingGroup)
		{
			super(group);
		}

		override protected function initToConsole():void
		{
			super.initToConsole();
			x = console.mainPanel.x + console.mainPanel.width - 80;
			y = console.mainPanel.y + 15;
		}
	}
}
