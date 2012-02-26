package com.junkbyte.console.vos
{
	import flash.display.StageAlign;

	public class GraphFPSGroup extends GraphGroup
	{
		public static const NAME:String = "consoleFPSGraph";
		
		private var _numFrames:uint;

		public function GraphFPSGroup()
		{
			super(NAME);

			rect.x = 160;
			rect.y = 15;
			align = StageAlign.RIGHT;
			

			var graph:GraphInterest = new GraphInterest("fps");
			graph.col = 0xFF3333;
			graph.setGetValueCallback(getNumFrames);

			interests.push(graph);
			
			_values.length = 1;
			
			freq = 500;
			fixedMin = 0;
		}
		
		override public function tick(timeDelta:uint):void
		{
			_numFrames++;
			sinceLastUpdate += timeDelta;
			
			while(sinceLastUpdate >= freq)
			{
				sinceLastUpdate -= freq;
				dispatchUpdates();
			}
		}

		override protected function dispatchUpdates():void
		{
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
