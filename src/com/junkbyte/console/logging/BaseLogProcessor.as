package com.junkbyte.console.logging
{
	import com.junkbyte.console.interfaces.IConsoleLogProcessor;
	import com.junkbyte.console.vos.LogEntry;
	
	public class BaseLogProcessor implements IConsoleLogProcessor
	{
		
		protected var entry:LogEntry;
		protected var index:uint;
		
		public function process(entry:LogEntry):void
		{
			this.entry = entry;
			index = 0;
			
			var len:uint = entry.inputs.length;
			while (index < len)
			{
				processInput(entry.inputs[index]);
				index++;
			}
		}
		
		// OVERRIDE COMPLETELY
		protected function processInput(input:*):void
		{
			setOutput(String(input));
		}
		
		protected function setOutput(output:String):void
		{
			entry.outputs[index] = output;
		}
	}
}