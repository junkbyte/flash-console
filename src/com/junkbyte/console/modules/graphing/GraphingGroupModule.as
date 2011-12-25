package com.junkbyte.console.modules.graphing
{
	import com.junkbyte.console.core.ConsoleModule;
	import com.junkbyte.console.core.ModuleTypeMatcher;
	import com.junkbyte.console.events.ConsoleEvent;
	import com.junkbyte.console.view.StageModule;

	import flash.display.Stage;

	public class GraphingGroupModule extends ConsoleModule
	{

		protected var stage:Stage;
		protected var graphModule:GraphingModule;

		protected var group:GraphingGroup;

		public function GraphingGroupModule()
		{
			super();

			addModuleRegisteryCallback(new ModuleTypeMatcher(StageModule), stageModuleRegistered, stageModuleUnregistered);
			addModuleRegisteryCallback(new ModuleTypeMatcher(GraphingModule), graphModuleRegistered, graphModuleUnregistered);
		}

		override protected function unregisteredFromConsole():void
		{
			stage = null;
			graphModule = null;

			super.unregisteredFromConsole();
		}

		protected function stageModuleRegistered(module:StageModule):void
		{
			stage = module.stage;
			startIfReady();
		}

		protected function stageModuleUnregistered(module:StageModule):void
		{
			stage = null;
			stop();
		}

		protected function graphModuleRegistered(module:GraphingModule):void
		{
			graphModule = module;
			startIfReady();
		}

		protected function graphModuleUnregistered(module:GraphingModule):void
		{
			graphModule = null;
			stop();
		}

		protected function startIfReady():void
		{
			if (stage != null && graphModule != null && group == null)
			{
				start();
			}
		}

		protected function start():void
		{
			
		}

		protected function stop():void
		{
			if (group != null && graphModule != null)
			{
				graphModule.removeGroup(group);
			}
			group = null;
		}
	}
}
