package com.junkbyte.console.modules.graphing
{
	import com.junkbyte.console.events.ConsoleEvent;

	public class CustomGraphingModule extends GraphingGroupModule
	{
		
		public function CustomGraphingModule()
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
			line.key = "x";
			line.color = 0xFF0000;
			group.lines.push(line);
			
			var line:GraphingLine = new GraphingLine();
			line.key = "y";
			line.color = 0x0000FF;
			group.lines.push(line);

			graphModule.registerGroup(group);
		}

		protected function onUpdate(event:ConsoleEvent):void
		{
			group.push(Vector.<Number>([layer.mouseX, layer.mouseY]));
		}
	}
}
