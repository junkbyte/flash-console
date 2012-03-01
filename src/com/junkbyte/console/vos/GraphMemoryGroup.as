package com.junkbyte.console.vos
{
	import flash.display.StageAlign;
	import flash.system.System;

	public class GraphMemoryGroup extends GraphGroup
	{
		public static const NAME:String = "consoleMemoryGraph";
		
		public function GraphMemoryGroup()
		{
			super(NAME);

			rect.x = 90;
			rect.y = 15;
			alignRight = true;

			var graph:GraphInterest = new GraphInterest("mb");
			graph.col = 0x6090FF;
			
			_updateArgs.length = 1;
			
			interests.push(graph);
			freq = 1000;
		}

		override protected function dispatchUpdates():void
		{
			_updateArgs[1] = Math.round(System.totalMemory / 10485.76) / 100;
			updateDispatcher.apply(_updateArgs);
		}
	}
}
