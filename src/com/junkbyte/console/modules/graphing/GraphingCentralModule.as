package com.junkbyte.console.modules.graphing
{
	import com.junkbyte.console.core.ConsoleModule;

	[Event(name = "addGroup", type = "com.junkbyte.console.modules.graphing.GraphingEvent")]
	[Event(name = "removeGroup", type = "com.junkbyte.console.modules.graphing.GraphingEvent")]
	[Event(name = "push", type = "com.junkbyte.console.modules.graphing.GraphingEvent")]
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
			if(getGroupId(group) >= 0)
			{
				throw new ArgumentError();
			}
			groups[nextIndex] = group;
			
			var event:GraphingEvent = new GraphingEvent(GraphingEvent.ADD_GROUP);
			event.group = group;
			dispatchEvent(event);
			
			return nextIndex++;
		}

		public function removeGroup(group:GraphingGroup):void
		{
			if(getGroupId(group) < 0)
			{
				throw new ArgumentError();
			}
			var event:GraphingEvent = new GraphingEvent(GraphingEvent.REMOVE_GROUP);
			event.group = group;
			dispatchEvent(event);
		}
		
		public function getGroups():Vector.<GraphingGroup>
		{
			var result:Vector.<GraphingGroup> = new Vector.<GraphingGroup>();
			for each(var group:GraphingGroup in groups)
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
