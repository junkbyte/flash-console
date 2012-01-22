package com.junkbyte.console.modules.graphing.custom
{
	import com.junkbyte.console.modules.graphing.GraphingGroup;
	import com.junkbyte.console.modules.graphing.GraphingLine;
	import com.junkbyte.console.modules.graphing.GraphingModule;

	Vector.<GraphingLine>;

	public class CustomGraphingModule extends GraphingModule
	{

		protected var customGroup:GraphingGroup;

		protected var values:Vector.<Number> = new Vector.<Number>();

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

		override protected function stop():void
		{
			super.stop();
			modules.unregisterModule(this);
		}

		override protected function createGraphingGroup():GraphingGroup
		{
			return customGroup;
		}

		override protected function getValues():Vector.<Number>
		{
			var lines:Vector.<GraphingLine> = group.lines;
			var len:uint = values.length = lines.length;

			for (var i:uint = 0; i < len; i++)
			{
				values[i] = CustomGraphingLine(lines[i]).getValue();
			}
			return values;
		}
	}
}
