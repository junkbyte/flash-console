package com.junkbyte.console.modules.graphing.memory
{
	import com.junkbyte.console.modules.graphing.GraphingGroup;
	import com.junkbyte.console.modules.graphing.GraphingLine;
	import com.junkbyte.console.view.ConsolePanel;

	public class MemoryGraphingGroup extends GraphingGroup
	{
		public function MemoryGraphingGroup()
		{
			super();

			updateFrequencyMS = 1000;

			var line:GraphingLine = new GraphingLine();
			line.key = "mb";
			line.color = 0x5060FF;

			lines.push(line);
		}

		override public function createPanel():ConsolePanel
		{
			return new MemoryGraphingPanelModule(this);
		}
	}
}
