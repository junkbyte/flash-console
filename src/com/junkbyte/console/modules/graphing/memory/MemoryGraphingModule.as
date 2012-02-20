package com.junkbyte.console.modules.graphing.memory
{
	import com.junkbyte.console.core.ModuleTypeMatcher;
	import com.junkbyte.console.interfaces.IMainMenu;
	import com.junkbyte.console.modules.graphing.GraphingGroup;
	import com.junkbyte.console.modules.graphing.GraphingLine;
	import com.junkbyte.console.modules.graphing.GraphingModule;
	import com.junkbyte.console.vos.ConsoleMenuItem;
	
	import flash.events.Event;
	import flash.system.System;

	public class MemoryGraphingModule extends GraphingModule
	{
		
		protected var menu:ConsoleMenuItem;
		
		private var values:Vector.<Number> = new Vector.<Number>(1);
		
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
			return new MemoryGraphingGroup();
		}

		override protected function getValues():Vector.<Number>
		{
			values[0] = Math.round(System.totalMemory / 10485.76) / 100;
			return values;
		}
		
		override protected function start():void
		{
			menu.active = true;
			menu.announceChanged();
			super.start();
		}
		
		
		override protected function onGroupClose(event:Event):void
		{
			menu.active = false;
			menu.announceChanged();
			
			super.onGroupClose(event);
		}
	}
}
