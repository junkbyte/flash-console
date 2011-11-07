package com.junkbyte.console.logging
{
	import com.junkbyte.console.interfaces.IConsoleLogProcessor;
	import com.junkbyte.console.utils.EscHTML;
	import com.junkbyte.console.utils.getQualifiedShortClassName;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;

	public class ReferencingLogProcessor implements IConsoleLogProcessor
	{
		private var processor:ConsoleLogProcessors;
		
		public function ReferencingLogProcessor(processor:ConsoleLogProcessors)
		{
			super();
			this.processor = processor;
		}
		
		public function process(input:*, currentOutput:String):String
		{
			if (input is Array || input is Vector)
			{
				var str:String = "[";
				var len:int = input.length;
				for (var i:int = 0; i < len; i++)
				{
					str += (i ? ", " : "") + processor.makeString(input[i]);
				}
				return str + "]";
			}
			if(typeof input == "object")
			{
				var add:String = "";
				if (input is ByteArray)
					add = " position:" + input.position + " length:" + input.length;
				else if (input is Date || input is Rectangle || input is Point || input is Matrix || input is Event)
					add = " " + String(input);
				else if (input is DisplayObject && input.name)
					add = " " + input.name;
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