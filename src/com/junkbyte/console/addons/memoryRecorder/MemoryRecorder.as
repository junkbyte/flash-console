/*
* 
* Copyright (c) 2008-2010 Lu Aye Oo
* 
* @author 		Lu Aye Oo
* 
* http://code.google.com/p/flash-console/
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
package com.junkbyte.console.addons.memoryRecorder
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.sampler.NewObjectSample;
	import flash.sampler.Sample;
	import flash.sampler.clearSamples;
	import flash.sampler.getSamples;
	import flash.sampler.pauseSampling;
	import flash.sampler.startSampling;
	import flash.system.System;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getTimer;

	public class MemoryRecorder extends EventDispatcher
	{
		public static var instance:MemoryRecorder = new MemoryRecorder();

		private var _interestedClassExpressions:Array = new Array();
		private var _ignoredClassExpressions:Array = new Array();

		private var _started:Boolean;

		private var startMemory:uint;
		private var endMemory:uint;
		private var startTimer:int;
		private var endTimer:int;

		private var ticker:Sprite;

		public var reportCallback:Function;

		public function get ignoredClassExpressions():Array
		{
			return _ignoredClassExpressions;
		}

		public function addIgnoredClassExpression(expression:*):void
		{
			_ignoredClassExpressions.push(expression);
		}

		public function get interestedClassExpressions():Array
		{
			return _interestedClassExpressions;
		}

		public function addInterestedClassExpression(expression:*):void
		{
			_interestedClassExpressions.push(expression);
		}

		public function get running():Boolean
		{
			return _started || ticker != null;
		}

		public function start():void
		{
			if (running)
			{
				return;
			}

			_started = true;

			startMemory = System.totalMemory;
			startTimer = getTimer();

			startSampling();
			clearSamples();
		}

		public function end():void
		{
			if (!_started || ticker != null)
			{
				return;
			}

			pauseSampling();
			endMemory = System.totalMemory;
			endTimer = getTimer();

			System.gc();
			ticker = new Sprite();
			ticker.addEventListener(Event.ENTER_FRAME, onEndingEnterFrame);
		}

		private function onEndingEnterFrame(event:Event):void
		{
			ticker.removeEventListener(Event.ENTER_FRAME, onEndingEnterFrame);
			ticker = null;
			System.gc();
			endSampling();
			dispatchEvent(new Event(Event.COMPLETE));
		}

		private function endSampling():void
		{
			var newCount:uint;
			var liveCount:uint;
			var lastMicroTime:Number = 0;

			report("MemoryRecorder...");
			report("Objects still alive: >>>");

			var objectsMap:Object = new Object();
			for each (var sample:Sample in getSamples())
			{
				if (sample is NewObjectSample)
				{
					var newSample:NewObjectSample = NewObjectSample(sample);
					if (shouldPrintClass(newSample.type))
					{
						newCount++;
						if (newSample.object !== undefined)
						{
							liveCount++;
							reportNewSample(newSample);
						}
					}
				}
				/*
				else if (sample is DeleteObjectSample)
				{
					//var delSample:DeleteObjectSample = DeleteObjectSample(s);
				}
				else
				{

				}*/
			}

			var timerTaken:uint = endTimer - startTimer;

			report("<<<", liveCount, "object(s).");
			report("New objects:", newCount);
			report("Time taken:", timerTaken + "ms.");
			report("Memory change:", roundMem(startMemory) + "mb to", roundMem(endMemory) + "mb (" + roundMem(endMemory - startMemory) + "mb)");

			_started = false;
			clearSamples();
		}

		private function roundMem(num:int):Number
		{
			return Math.round(num / 10485.76) / 100;
		}

		private function reportNewSample(sample:NewObjectSample):void
		{
			var className:String = getQualifiedClassName(sample.type);
			try
			{
				if (sample.type == String)
				{
					reportNewStringSample(sample, className);
				}
				else
				{
					report(sample.id, className, getSampleSize(sample), sample.object, getSampleStack(sample));
				}
			}
			catch (err:Error)
			{
				report(sample.id, getSampleSize(sample), className, getSampleStack(sample));
			}
		}

		private function reportNewStringSample(sample:NewObjectSample, className:String):void
		{
			var output:String = "";
			var masterStringFunction:Function = getDefinitionByName("flash.sampler.getMasterString") as Function; // only supported post flash 10.1

			var str:String = sample.object;
			if (masterStringFunction != null)
			{
				while (str)
				{
					output += "\"" + str + "\" > ";
					str = masterStringFunction(str);
				}
			}
			report(sample.id, className, getSampleSize(sample), output, getSampleStack(sample));
		}

		private function getSampleStack(sample:Sample):String
		{
			var output:String = "";
			for each (var stack:String in sample.stack)
			{
				stack = stack.replace(/.*?\:\:/, "");
				stack = stack.replace(/\[.*?\:([0-9]+)\]/, ":$1");
				output += stack + "; ";
			}
			return output;
		}

		private function getSampleSize(sample:Sample):String
		{
			if ("size" in sample)
			{
				return sample['size'];
			}
			return "";
		}

		private function report(... args:Array):void
		{
			var call:Function = reportCallback != null ? reportCallback : trace;
			call.apply(this, args);
		}

		private function shouldPrintClass(type:Class):Boolean
		{
			return !isClassInIgnoredList(type) && isClassInInterestedList(type);
		}

		private function isClassInInterestedList(type:Class):Boolean
		{
			if (_interestedClassExpressions.length == 0)
			{
				return true;
			}
			return classMatchesExpressionList(type, _interestedClassExpressions);
		}

		private function isClassInIgnoredList(type:Class):Boolean
		{
			return classMatchesExpressionList(type, _ignoredClassExpressions);
		}

		private function classMatchesExpressionList(type:Class, list:Array):Boolean
		{
			var className:String = getQualifiedClassName(type);
			for each (var expression:* in list)
			{
				if (className.search(expression) == 0)
				{
					return true;
				}
			}
			return false;
		}
	}
}
