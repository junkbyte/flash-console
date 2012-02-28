package com.junkbyte.console.vos
{
	import com.junkbyte.console.Console;
	
	import flash.display.StageAlign;

	public class GraphFPSGroup extends GraphGroup
	{
		public static const NAME:String = "consoleFPSGraph";
		
		private var _numFrames:uint;
		
		private var _console:Console;

		public function GraphFPSGroup(console:Console)
		{
			_console = console;
			
			super(NAME);
			
			rect.x = 170;
			rect.y = 15;
			align = StageAlign.RIGHT;
			

			var graph:GraphInterest = new GraphInterest("fps");
			graph.col = 0xFF3333;
			graph.setGetValueCallback(getNumFrames);

			interests.push(graph);
			
			_values.length = 1;
			
			freq = 200;
			fixedMin = 0;
			
			updateStageFrameRate();
		}
		
		override public function tick(timeDelta:uint):void
		{
			_numFrames++;
			
			sinceLastUpdate += timeDelta;
			
			while(sinceLastUpdate >= freq)
			{
				updateStageFrameRate();
				sinceLastUpdate -= freq;
				dispatchUpdates();
			}
		}

		private function updateStageFrameRate():void
		{
			if(_console.stage)
			{
				fixedMax = _console.stage.frameRate;
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
