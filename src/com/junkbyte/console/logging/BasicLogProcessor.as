package com.junkbyte.console.logging
{
	import com.junkbyte.console.interfaces.IConsoleLogProcessor;
	import com.junkbyte.console.utils.EscHTML;
	
	import flash.utils.ByteArray;

	public class BasicLogProcessor implements IConsoleLogProcessor
	{
		
		public function process(input:*, currentOutput:String):String
		{
			if(input is Boolean)
			{
				return primitiveOutput(currentOutput);
			}
			else if(input is Number)
			{
				return primitiveOutput(currentOutput);
			}
			else if (input is XML || input is XMLList)
			{
				return primitiveOutput(EscHTML(input.toXMLString()));
			}
			else if (input is Error)
			{
				var err:Error = input as Error;
				// err.getStackTrace() is not supported in non-debugger players...
				var stackstr:String = err.hasOwnProperty("getStackTrace") ? err.getStackTrace() : err.toString();
				if (stackstr != null && stackstr.length > 0)
				{
					return stackstr;
				}
				else
				{
					return err.toString();
				}
			}
			else if (input is ByteArray)
			{
				return "[ByteArray position:" + ByteArray(input).position + " length:" + ByteArray(input).length + "]";
			}
			return currentOutput;
		}
		
		protected function primitiveOutput(input:String):String
		{
			return "<prim>"+input+"</prim>";
		}
	}
}