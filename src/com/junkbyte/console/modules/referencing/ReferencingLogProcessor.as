package com.junkbyte.console.modules.referencing
{
	import com.junkbyte.console.logging.ConsoleLogger;
	import com.junkbyte.console.logging.StandardLogProcessor;
	import com.junkbyte.console.utils.EscHTML;
	import com.junkbyte.console.utils.getQualifiedShortClassName;

	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;

	public class ReferencingLogProcessor extends StandardLogProcessor
	{
		private var logger:ConsoleLogger;

		public function ReferencingLogProcessor(logger:ConsoleLogger)
		{
			super();
			this.logger = logger;
		}

		override public function process(input:*, currentOutput:String):String
		{
			if (input is Array || input is Vector)
			{
				var str:String = "[";
				var len:int = input.length;
				for (var i:int = 0; i < len; i++)
				{
					str += (i ? ", " : "") + logger.makeString(input[i]);
				}
				return str + "]";
			}
			if (typeof input == "object")
			{
				var add:String = "";
				if (input is ByteArray)
				{
					add = " position:" + input.position + " length:" + input.length;
				}
				else if (input is Date || input is Rectangle || input is Point || input is Matrix || input is Event)
				{
					add = " " + String(input);
				}
				else if (input is DisplayObject && input.name)
				{
					add = " " + input.name;
				}
				return "{" + genLinkString(input, EscHTML(getQualifiedShortClassName(input) + add)) + "}";
			}
			return currentOutput;
		}

		protected function genLinkString(input:*, str:String):String
		{
			return "<menu><a href='event:ref_'>" + str + "</a></menu>";
		/*var ind:uint = setLogRef(o);
		if (ind)
		{
			return "<menu><a href='event:ref_" + ind + (prop ? ("_" + prop) : "") + "'>" + str + "</a></menu>";
		}
		else
		{
			return str;
		}*/
		}
	}
}
