package com.junkbyte.console.modules.graphing
{
	import com.junkbyte.console.core.ConsoleModule;
	import com.junkbyte.console.core.ModuleTypeMatcher;
	import com.junkbyte.console.view.ConsolePanel;
	
	import flash.utils.Dictionary;

	public class GraphingPanelsModule extends ConsoleModule
	{

		protected var graphToPanelMap:Dictionary = new Dictionary();

		public function GraphingPanelsModule()
		{
			super();
			addModuleRegisteryCallback(new ModuleTypeMatcher(GraphingModule), graphModuleRegistered, graphModuleUnregistered);
		}

		protected function graphModuleRegistered(graphModule:GraphingModule):void
		{
			graphModule.addEventListener(GraphingEvent.ADD_GROUP, onGroupAdded);
			graphModule.addEventListener(GraphingEvent.REMOVE_GROUP, onGroupRemoved);
			addGroups(graphModule);
		}

		protected function graphModuleUnregistered(graphModule:GraphingModule):void
		{
			graphModule.removeEventListener(GraphingEvent.ADD_GROUP, onGroupAdded);
			graphModule.removeEventListener(GraphingEvent.REMOVE_GROUP, onGroupRemoved);
		}

		protected function addGroups(graphModule:GraphingModule):void
		{
			for each (var group:GraphingGroup in graphModule.getGroups())
			{
				addGroup(group);
			}
		}

		protected function onGroupAdded(event:GraphingEvent):void
		{
			addGroup(event.group);
		}

		protected function onGroupRemoved(event:GraphingEvent):void
		{
			removeGroup(event.group);
		}

		protected function addGroup(group:GraphingGroup):void
		{
			var panel:ConsolePanel = group.createPanel();
			graphToPanelMap[group] = panel;
			modules.registerModule(panel);
		}

		protected function removeGroup(group:GraphingGroup):void
		{
			var panel:ConsolePanel = graphToPanelMap[group];
			modules.unregisterModule(panel);
			delete graphToPanelMap[group];
		}
	}
}
