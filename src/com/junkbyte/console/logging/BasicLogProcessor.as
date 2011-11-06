package com.junkbyte.console.logging
{
	import com.junkbyte.console.utils.EscHTML;
	
	import flash.utils.ByteArray;

	public class BasicLogProcessor extends BaseLogProcessor
	{
		public function BasicLogProcessor()
		{
			super();
		}
		
		override protected function processInput(input:*):void
		{
			// each of these could have their own processor class but that would hit performace
			if(input is Boolean)
			{
				setPrimitiveOutput(input);
			}
			else if(input is Number)
			{
				setPrimitiveOutput(input);
			}
			else if (input is XML || input is XMLList)
			{
				setPrimitiveOutput(EscHTML(input.toXMLString()));
			}
			else if (input is Error)
			{
				var err:Error = input as Error;
				// err.getStackTrace() is not supported in non-debugger players...
				var stackstr:String = err.hasOwnProperty("getStackTrace") ? err.getStackTrace() : err.toString();
				if (stackstr != null && stackstr.length > 0)
				{
					setOutput(stackstr);
				}
				else
				{
					setOutput(err.toString());
				}
			}
			else if (input is ByteArray)
			{
				setOutput("[ByteArray position:" + ByteArray(input).position + " length:" + ByteArray(input).length + "]");
			}
			else
			{
				setOutput(String(input));
			}
		}
		
		protected function setPrimitiveOutput(input:String):void
		{
			setOutput("<prim>"+input+"</prim>");
		}
	}
}