package com.junkbyte.console.modules.graphing.custom
{
	import com.junkbyte.console.modules.graphing.GraphingLine;

	public class CustomGraphingLine extends GraphingLine
	{
		public var target:Object;
		public var property:String;
		
		public function CustomGraphingLine(target:Object, property:String, key:String, color:Number)
		{
			super();
			this.target = target;
			this.property = property;
			this.key = key;
			this.color = color;
		}
		
		public function getValue():Number
		{
			return target[property];
		}
	}
}