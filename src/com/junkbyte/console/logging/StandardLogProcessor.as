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
	import com.junkbyte.console.utils.EscHTML;

	import flash.utils.ByteArray;

	public class StandardLogProcessor extends BaseLogProcessor
	{
		override public function process(input:*, currentOutput:String):String
		{
			if (input is Boolean)
			{
				return primitiveOutput(currentOutput);
			}
			else if (input is Number)
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
					return EscHTML(stackstr);
				}
				else
				{
					return EscHTML(String(err));
				}
			}
			else if (input is ByteArray)
			{
				return "[ByteArray position:" + ByteArray(input).position + " length:" + ByteArray(input).length + "]";
			}
			return currentOutput === null ? EscHTML(String(input)) : currentOutput;
		}

		protected function primitiveOutput(input:String):String
		{
			return "<prim>" + input + "</prim>";
		}
	}
}
