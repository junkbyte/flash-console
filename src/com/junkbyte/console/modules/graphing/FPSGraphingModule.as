package com.junkbyte.console.modules.graphing
{
	import com.junkbyte.console.events.ConsoleEvent;

	public class FPSGraphingModule extends GraphingGroupModule
	{
		
		private var frames:uint;
		private var time:uint;
		
		public var updateFreqMs:uint = 200;
		
		public function FPSGraphingModule()
		{
			super();
		}

		override protected function unregisteredFromConsole():void
		{
			console.removeEventListener(ConsoleEvent.UPDATE_DATA, onUpdate);

			super.unregisteredFromConsole();
		}

		override protected function start():void
		{
			console.addEventListener(ConsoleEvent.UPDATE_DATA, onUpdate);

			group = new GraphingGroup();
			group.fixedMin = 0;
			group.fixedMax = stage.frameRate;

			var line:GraphingLine = new GraphingLine();
			line.key = "fps";
			line.color = 0xFFCC00;

			group.lines.push(line);

			graphModule.registerGroup(group);
		}

		protected function onUpdate(event:ConsoleEvent):void
		{
			time += event.msDelta;
			frames++;
			
			while(time >= updateFreqMs)
			{
				var fps:uint = frames * (1000 / updateFreqMs);
				
				group.push(Vector.<Number>([fps]));
				
				frames = 0;
				time -= updateFreqMs;
			}
		}
	}
}
