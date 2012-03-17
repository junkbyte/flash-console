package com.junkbyte.console.vos
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.console_internal;

	use namespace console_internal;

	public class GraphFPSGroup extends GraphGroup
	{
		public static const NAME:String = "consoleFPSGraph";

		public var historyLength:uint = 5;
		public var maxLag:uint = 60;

		private var _numFrames:uint;

		private var _console:Console;

		private var _history:Array = new Array();
		private var _historyIndex:uint;
		private var _historyTotal:Number = 0;

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
		}

		override public function tick(timeDelta:uint):void
		{
			var fps:Number = 1000 / timeDelta;
			
			var frames:uint;
			if (_console.stage)
			{
				fixedMax = _console.stage.frameRate;
				
				frames = fixedMax / fps / historyLength;
				if (frames > maxLag)
				{
					frames = maxLag;
				}
			}
			if (frames == 0)
			{
				frames = 1
			}
			
			while (frames > 0)
			{
				dispatchFPS(fps);
				frames--;
			}
		}

		private function dispatchFPS(fps:Number):void
		{
			var prevHistory:Number = _history[_historyIndex];
			if (prevHistory > 0)
			{
				_historyTotal -= prevHistory
			}
			
			_historyTotal += fps;
			_history[_historyIndex] = fps;
			
			_historyIndex++;
			if (_historyIndex >= historyLength)
			{
				_historyIndex = 0;
			}

			fps = _historyTotal / historyLength;
			if (fps > fixedMax)
			{
				fps = fixedMax;
			}
			_updateArgs[1] = Math.round(fps);

			applyUpdateDispather(_updateArgs);
		}

		private function getNumFrames(graph:GraphInterest):Number
		{
			return _numFrames;
		}
	}
}
