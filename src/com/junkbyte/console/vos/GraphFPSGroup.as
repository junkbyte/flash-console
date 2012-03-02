package com.junkbyte.console.vos
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.console_internal;
	
	import flash.display.StageAlign;
	
	use namespace console_internal;

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
			alignRight = true;
			

			var graph:GraphInterest = new GraphInterest("fps");
			graph.col = 0xFF3333;
			graph.setGetValueCallback(getNumFrames);

			interests.push(graph);
			
			_updateArgs.length = 1;
			
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
			_updateArgs[1] = _numFrames * (1000 / freq);
			_numFrames = 0;
			applyUpdateDispather(_updateArgs);
		}

		private function getNumFrames(graph:GraphInterest):Number
		{
			return _numFrames;
		}
	}
}
