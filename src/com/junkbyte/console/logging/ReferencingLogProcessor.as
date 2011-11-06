package com.junkbyte.console.logging
{
	import com.junkbyte.console.utils.EscHTML;
	import com.junkbyte.console.utils.getQualifiedShortClassName;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;

	public class ReferencingLogProcessor extends BaseLogProcessor
	{
		public function ReferencingLogProcessor()
		{
			super();
		}
		
		override protected function processInput(input:*):void
		{
			if (input is Array || input is Vector)
			{
				var str:String = "[";
				var len:int = input.length;
				for (var i:int = 0; i < len; i++)
				{
					str += (i ? ", " : "") + processInput(input[i]);
				}
				setOutput(str + "]");
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
				setOutput("{" + genLinkString(input, EscHTML(getQualifiedShortClassName(input) + add)) + "}");
			}
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