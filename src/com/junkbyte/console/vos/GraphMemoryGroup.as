package com.junkbyte.console.vos
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.console_internal;
	
	import flash.display.StageAlign;
	import flash.system.System;
	
	use namespace console_internal;

	public class GraphMemoryGroup extends GraphGroup
	{
		public static const NAME:String = "consoleMemoryGraph";
		
		private var console:Console;
		
		public function GraphMemoryGroup(console:Console)
		{
			super(NAME);
			this.console = console;

			rect.x = 90;
			rect.y = 15;
			alignRight = true;

			var graph:GraphInterest = new GraphInterest("mb");
			graph.col = 0x6090FF;
			
			_updateArgs.length = 1;
			
			interests.push(graph);
			freq = 1000;
			
			menus.push("G");
			
			onMenu.add(onMenuClick);
		}
		
		protected function onMenuClick(key:String):void
		{
			if(key == "G")
			{
				console.gc();
			}
		}

		override protected function dispatchUpdates():void
		{
			_updateArgs[0] = Math.round(System.totalMemory / 10485.76) / 100;
			applyUpdateDispather(_updateArgs);
		}
	}
}
