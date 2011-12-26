package com.junkbyte.console.modules.graphing.memory
{
	import com.junkbyte.console.modules.graphing.GraphingGroup;
	import com.junkbyte.console.view.ConsolePanel;

	public class MemoryGraphingGroup extends GraphingGroup
	{
		public function MemoryGraphingGroup()
		{
			super();
		}

		override public function createPanel():ConsolePanel
		{
			return new MemoryGraphingPanelModule(this);
		}
	}
}
