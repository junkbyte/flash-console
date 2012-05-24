package com.junkbyte.console.vos
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.console_internal;

	use namespace console_internal;

	public class GraphFPSGroup extends GraphGroup
	{
		public static const NAME:String = "consoleFPSGraph";

		public var maxLag:uint = 60;

		private var _console:Console;
		
		private var _historyLength:uint;
		private var _history:Array = new Array();
		private var _historyIndex:uint;
		private var _historyTotal:Number = 0;

		public function GraphFPSGroup(console:Console, historyLength:uint = 5)
		{
			_console = console;
			_historyLength = historyLength;

			super(NAME);
			
			for (var i:uint = 0; i < historyLength; i++)
			{
				_history.push(0);
			}

			rect.x = 170;
			rect.y = 15;
			alignRight = true;

			var graph:GraphInterest = new GraphInterest("fps");
			graph.col = 0xFF3333;

			interests.push(graph);

			_updateArgs.length = 1;

			freq = 200;
			fixedMin = 0;
			numberDisplayPrecision = 2;
		}

		override public function tick(timeDelta:uint):void
		{
			if(timeDelta == 0)
			{
				return;
			}
			var fps:Number = 1000 / timeDelta;
			
			var frames:uint;
			if (_console.stage)
			{
				fixedMax = _console.stage.frameRate;
				
				frames = fixedMax / fps / _historyLength;
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
			_historyTotal -= _history[_historyIndex];
			
			_historyTotal += fps;
			_history[_historyIndex] = fps;
			
			_historyIndex++;
			if (_historyIndex >= _historyLength)
			{
				_historyIndex = 0;
			}
			
			fps = _historyTotal / _historyLength;
			if (fps > fixedMax)
			{
				fps = fixedMax;
			}
			_updateArgs[0] = Math.round(fps);

			applyUpdateDispather(_updateArgs);
		}
	}
}
