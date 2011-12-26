package com.junkbyte.console.modules.graphing.memory
{
	import com.junkbyte.console.core.ModuleTypeMatcher;
	import com.junkbyte.console.interfaces.IMainMenu;
	import com.junkbyte.console.modules.graphing.GraphingGroup;
	import com.junkbyte.console.modules.graphing.GraphingLine;
	import com.junkbyte.console.modules.graphing.GraphingModule;
	import com.junkbyte.console.vos.ConsoleMenuItem;
	
	import flash.system.System;

	public class MemoryGraphingModule extends GraphingModule
	{
		
		protected var menu:ConsoleMenuItem;
		
		public function MemoryGraphingModule(startImmediately:Boolean = false)
		{
			menu = new ConsoleMenuItem("M", onMenuClick, null, "Memory::monitor");
			menu.sortPriority = -20;
			menu.visible = false;
			menu.active = startImmediately;
			
			addModuleRegisteryCallback(new ModuleTypeMatcher(IMainMenu), onMainMenuRegistered, onMainMenuUnregistered);
			
			super();
		}
		
		protected function onMainMenuRegistered(module:IMainMenu):void
		{
			module.addMenu(menu);
		}
		
		protected function onMainMenuUnregistered(module:IMainMenu):void
		{
			module.removeMenu(menu);
		}
		
		private function onMenuClick():void
		{
			if(menu.active)
			{
				stop();
			}
			else
			{
				start();
			}
		}
		
		override protected function onDependenciesReady():void
		{
			menu.visible = true;
			menu.announceChanged();
			if(menu.active)
			{
				start();
			}
		}

		override protected function createGraphingGroup():GraphingGroup
		{
			var group:MemoryGraphingGroup = new MemoryGraphingGroup();
			group.updateFrequencyMS = 1000;

			var line:GraphingLine = new GraphingLine();
			line.key = "mb";
			line.color = 0xFFCC00;

			group.lines.push(line);
			return group;
		}

		override protected function getValues():Vector.<Number>
		{
			var value:Number = Math.round(System.totalMemory / 10485.76) / 100;
			return Vector.<Number>([value]);
		}
		
		override protected function start():void
		{
			menu.active = true;
			menu.announceChanged();
			super.start();
		}
		
		override protected function stop():void
		{
			menu.active = false;
			menu.announceChanged();
			super.stop();
		}
	}
}
