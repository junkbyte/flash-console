package com.junkbyte.console.logging
{
	import com.junkbyte.console.interfaces.IConsoleLogProcessor;

	public class ConsoleLogProcessors implements IConsoleLogProcessor
	{
		private var processors:Vector.<IConsoleLogProcessor> = new Vector.<IConsoleLogProcessor>();
		
		private var numOfProcessors:uint; // just for minor speed increase, instead of 'processors.length'
		
		public function ConsoleLogProcessors()
		{
			addProcessor(new BasicLogProcessor());
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
			updateNumProcessors();
		}
		
		public function addProcessor(processor:IConsoleLogProcessor):void
		{
			if(processors == null)
			{
				throw new ArgumentError();
			}
			processors.push(processor);
			updateNumProcessors();
		}
		
		protected function updateNumProcessors():void
		{
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