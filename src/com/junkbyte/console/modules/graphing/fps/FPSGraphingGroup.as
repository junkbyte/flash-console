package com.junkbyte.console.modules.graphing.fps
{
	import com.junkbyte.console.modules.graphing.GraphingGroup;
	import com.junkbyte.console.modules.graphing.GraphingLine;
	import com.junkbyte.console.view.ConsolePanel;

	public class FPSGraphingGroup extends GraphingGroup
	{
		public function FPSGraphingGroup()
		{
			super();
			updateFrequencyMS = 250;
			fixedMin = 0;

			var line:GraphingLine = new GraphingLine();
			line.key = "fps";
			line.color = 0xFF3333;

			lines.push(line);
		}

		override public function createPanel():ConsolePanel
		{
			return new FPSGraphingPanelModule(this);
		}
	}
}
