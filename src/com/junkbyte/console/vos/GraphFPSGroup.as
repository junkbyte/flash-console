package com.junkbyte.console.vos
{
	import flash.display.StageAlign;

	public class GraphFPSGroup extends GraphGroup
	{
		private var _numFrames:uint;

		public function GraphFPSGroup()
		{
			super("consoleFPSMonitor");

			rect.x = 160;
			rect.y = 15;
			align = StageAlign.RIGHT;

			var graph:GraphInterest = new GraphInterest("fps");
			graph.col = 0xFF3333;
			graph.setGetValueCallback(getNumFrames);

			interests.push(graph);
			freq = 500;
			fixedMin = 0;
		}

		override public function updateIfApproate():void
		{
			_numFrames++;
			while (shouldUpdate())
			{
				update();
			}
		}

		override public function update():void
		{
			sinceLastUpdate -= freq;
			_values[0] = _numFrames * (1000 / freq);
			_numFrames = 0;
			updateDispatcher.apply(_values);
		}

		private function getNumFrames(graph:GraphInterest):Number
		{
			return _numFrames;
		}
	}
}
