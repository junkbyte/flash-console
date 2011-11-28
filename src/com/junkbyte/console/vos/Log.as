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
package com.junkbyte.console.vos
{
	import com.junkbyte.console.interfaces.IConsoleLogProcessor;

	import flash.utils.ByteArray;

	public class Log
	{
		public var inputs:Array;
		// public var line:uint;
		public var text:String;
		public var channel:String;
		public var priority:int;
		// public var stack:String;
		//
		public var next:Log;
		public var prev:Log;

		//
		public function Log()
		{
		}

		public function clearInput():void
		{
			inputs = null;
		}

		public function setOutputUsingProcessors(processors:Vector.<IConsoleLogProcessor>):void
		{
			text = makeOutputUsingProcessors(processors);
		}

		public function makeOutputUsingProcessors(processors:Vector.<IConsoleLogProcessor>):String
		{
			var outputs:Vector.<String> = new Vector.<String>(inputs.length);

			var len:uint = processors.length;
			for (var i:uint = 0; i < len; i++)
			{
				processors[i].processEntry(this, outputs);
			}

			return outputs.join(" ");
		}

		public function toBytes(bytes:ByteArray):void
		{
			bytes.writeUnsignedInt(text.length);
			bytes.writeUTFBytes(text);
			// because writeUTF can't accept more than 65535
			bytes.writeUTF(channel);
			bytes.writeInt(priority)
		}

		public static function FromBytes(bytes:ByteArray):Log
		{
			var t:String = bytes.readUTFBytes(bytes.readUnsignedInt());
			var c:String = bytes.readUTF();
			var p:int = bytes.readInt();
			var entry:Log = new Log();
			entry.text = t;
			entry.channel = c;
			entry.priority = p;
			return entry;
		}

		public function plainText():String
		{
			return text.replace(/<.*?>/g, "").replace(/&lt;/g, "<").replace(/&gt;/g, ">");
		}

		public function toString():String
		{
			return "[" + channel + "] " + plainText();
		}

		public function clone():Log
		{
			var entry:Log = new Log();
			entry.text = text;
			entry.channel = channel;
			entry.priority = priority;
			// entry.line = line;
			// entry.stack = stack;
			return entry;
		}
	}
}
