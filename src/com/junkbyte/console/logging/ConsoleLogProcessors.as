/*
*
* Copyright (c) 2008-2011 Lu Aye Oo
*
* @author 		Lu Aye Oo
*
* http://code.google.com/p/flash-console/
* http://junkbyte.com
*
*
* This software is provided 'as-is', without any express or implied
* warranty.  In no event will the authors be held liable for any damages
* arising from the use of this software.
* Permission is granted to anyone to use this software for any purpose,
* including commercial applications, and to alter it and redistribute it
* freely, subject to the following restrictions:
* 1. The origin of this software must not be misrepresented; you must not
* claim that you wrote the original software. If you use this software
* in a product, an acknowledgment in the product documentation would be
* appreciated but is not required.
* 2. Altered source versions must be plainly marked as such, and must not be
* misrepresented as being the original software.
* 3. This notice may not be removed or altered from any source distribution.
*
*/
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