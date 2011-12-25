package com.junkbyte.console.modules.graphing
{
	import com.junkbyte.console.events.ConsoleEvent;

	import flash.system.System;

	public class MemoryGraphingModule extends GraphingGroupModule
	{

		private var time:uint;

		public var updateFreqMs:uint = 1000;

		public function MemoryGraphingModule()
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

			var line:GraphingLine = new GraphingLine();
			line.key = "mb";
			line.color = 0xFFCC00;

			group.lines.push(line);

			graphModule.registerGroup(group);
		}

		protected function onUpdate(event:ConsoleEvent):void
		{
			time += event.msDelta;

			if (time >= updateFreqMs)
			{
				var value:Number = Math.round(System.totalMemory/10485.76)/100;
				group.push(Vector.<Number>([value]));

				time -= updateFreqMs;
			}
		}
	}
}
