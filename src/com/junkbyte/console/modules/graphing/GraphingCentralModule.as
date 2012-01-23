package com.junkbyte.console.modules.graphing
{
	import com.junkbyte.console.core.ConsoleModule;
	import com.junkbyte.console.view.ConsolePanel;

	import flash.events.Event;

	[Event(name = "addGroup", type = "com.junkbyte.console.modules.graphing.GraphingEvent")]
	public class GraphingCentralModule extends ConsoleModule
	{

		protected var groups:Object = new Object();
		protected var nextIndex:uint;

		public function GraphingCentralModule()
		{
			super();
		}

		public function registerGroup(group:GraphingGroup):uint
		{
			if (getGroupId(group) >= 0)
			{
				throw new ArgumentError();
			}
			groups[nextIndex] = group;

			group.addEventListener(Event.CLOSE, onGroupClose);

			createPanelForGroup(group);

			var event:GraphingEvent = new GraphingEvent(GraphingEvent.ADD_GROUP);
			event.group = group;
			dispatchEvent(event);

			return nextIndex++;
		}

		protected function createPanelForGroup(group:GraphingGroup):void
		{
			var panel:ConsolePanel = group.createPanel();
			if (panel != null)
			{
				modules.registerModule(panel);
			}
		}

		protected function onGroupClose(event:Event):void
		{
			var group:GraphingGroup = event.currentTarget as GraphingGroup;
			removeGroup(group);
		}

		protected function removeGroup(group:GraphingGroup):void
		{
			group.removeEventListener(Event.CLOSE, onGroupClose);
			
			var index:int = getGroupId(group);
			delete groups[index];
		}

		public function getGroups():Vector.<GraphingGroup>
		{
			var result:Vector.<GraphingGroup> = new Vector.<GraphingGroup>();
			for each (var group:GraphingGroup in groups)
			{
				result.push(group);
			}
			return result;
		}

		public function getGroupById(id:uint):GraphingGroup
		{
			return groups[nextIndex];
		}

		public function getGroupId(group:GraphingGroup):int
		{
			for (var X:String in groups)
			{
				if (groups[X] == group)
				{
					return int(X);
				}
			}
			return -1;
		}
	}
}
