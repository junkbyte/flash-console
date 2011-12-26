package com.junkbyte.console.modules.graphing.fps
{
	import com.junkbyte.console.modules.graphing.GraphingGroup;
	import com.junkbyte.console.view.ConsolePanel;

	public class FPSGraphingGroup extends GraphingGroup
	{
		public function FPSGraphingGroup()
		{
			super();
		}

		override public function createPanel():ConsolePanel
		{
			return new FPSGraphingPanelModule(this);
		}
	}
}
