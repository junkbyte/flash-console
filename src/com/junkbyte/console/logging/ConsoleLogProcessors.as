package com.junkbyte.console.logging
{
	import com.junkbyte.console.interfaces.IConsoleLogProcessor;

	public class ConsoleLogProcessors implements IConsoleLogProcessor
	{
		private var processors:Vector.<IConsoleLogProcessor> = new Vector.<IConsoleLogProcessor>();
		
		private var numOfProcessors:uint; // just for minor speed increase, instead of 'processors.length'
		
		public function ConsoleLogProcessors()
		{
			
			processors.push(new BasicLogProcessor());
			processors.push(new ReferencingLogProcessor(this));
			numOfProcessors = processors.length;
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
			this.processors = processors.concat();
			numOfProcessors = processors.length;
		}
		
		public function makeString(input:*):String
		{
			return process(input, String(input));
		}
		
		public function process(input:*, currentOutput:String):String
		{
			for (var i:uint = 0; i < numOfProcessors; i++)
			{
				var processor:IConsoleLogProcessor = processors[i];
				currentOutput = processor.process(input, currentOutput);
			}
			return currentOutput;
		}
	}
}