package com.junkbyte.console.modules.graphing.memory
{
	import com.junkbyte.console.interfaces.IConsoleOnDemandModule;
	import com.junkbyte.console.modules.ConsoleModuleNames;
	import com.junkbyte.console.modules.graphing.GraphingGroup;
	import com.junkbyte.console.modules.graphing.GraphingPanelModule;
	
	import flash.events.TextEvent;

	public class MemoryGraphingPanelModule extends GraphingPanelModule
	{
		public function MemoryGraphingPanelModule(group:GraphingGroup)
		{
			super(group);
		}

		override protected function initToConsole():void
		{
			super.initToConsole();
			x = console.mainPanel.x + console.mainPanel.width - 80;
			y = console.mainPanel.y + 15;
		}

		override protected function getMenuKeys():Vector.<String>
		{
			var keys:Vector.<String> = super.getMenuKeys();
			if (modules.getModuleByName(ConsoleModuleNames.GARBAGE_COLLECTOR) != null)
			{
				keys.unshift("G");
			}
			return keys;
		}

		override protected function onTextLinkHandler(e:TextEvent):void
		{
			super.onTextLinkHandler(e);

			if (e.text == "G")
			{
				IConsoleOnDemandModule(modules.getModuleByName(ConsoleModuleNames.GARBAGE_COLLECTOR)).run();
			}
		}
	}
}
