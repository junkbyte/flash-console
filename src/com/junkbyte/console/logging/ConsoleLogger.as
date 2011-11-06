package com.junkbyte.console.logging
{
	import com.junkbyte.console.core.ConsoleModule;
	import com.junkbyte.console.interfaces.IConsoleLogProcessor;
	import com.junkbyte.console.vos.ConsoleModuleMatch;
	import com.junkbyte.console.vos.Log;
	import com.junkbyte.console.vos.LogEntry;
	
	public class ConsoleLogger extends ConsoleModule
	{
		private var processors:Vector.<IConsoleLogProcessor> = new Vector.<IConsoleLogProcessor>();
		
		public function ConsoleLogger()
		{
			super();
			
			processors.push(new BasicLogProcessor());
			processors.push(new ReferencingLogProcessor());
		}
		
		public function getProcessorsCopy():Vector.<IConsoleLogProcessor>
		{
			return processors.concat();
		}
		
		public function setProcessors(processors:Vector.<IConsoleLogProcessor>):void
		{
			if(processors == null)
			{
				throw new ArgumentError();
			}
			this.processors = processors;
		}
		
		public function addEntry(entry:LogEntry):void
		{
			var len:uint = processors.length;
			
			entry.outputs = new Vector.<String>(entry.inputs.length);
			
			for (var i:uint = 0; i < len; i++)
			{
				var processor:IConsoleLogProcessor = processors[i];
				processor.process(entry);
			}
			addProcessedEntry(entry);
		}
		
		protected function addProcessedEntry(entry:LogEntry):void
		{
			console.addHTMLch(entry.channel, entry.priority, entry.outputs.join(" "));
		}
	}
}