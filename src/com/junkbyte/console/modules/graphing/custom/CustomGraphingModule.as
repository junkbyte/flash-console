package com.junkbyte.console.modules.graphing.custom
{
	import com.junkbyte.console.events.ConsoleEvent;
	import com.junkbyte.console.modules.graphing.GraphingGroup;
	import com.junkbyte.console.modules.graphing.GraphingModule;

	public class CustomGraphingModule extends GraphingModule
	{
		
		protected var customGroup:GraphingGroup;
		
		public function CustomGraphingModule(group:CustomGraphingGroup)
		{
			this.customGroup = group;
			super();
		}
		
		// OVERRIDE
		override protected function onDependenciesReady():void
		{
			start();
		}
		
		override protected function createGraphingGroup():GraphingGroup
		{
			return customGroup;
		}

		override protected function getValues():Vector.<Number>
		{
			var values:Vector.<Number> = new Vector.<Number>();
			for each(var line:CustomGraphingLine in group.lines)
			{
				values.push(line.getValue());
			}
			return values;
		}
	}
}
