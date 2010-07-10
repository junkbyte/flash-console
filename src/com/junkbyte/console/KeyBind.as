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
package com.junkbyte.console 
{
	public class KeyBind 
	{
		
		private static const SHIFT:uint = 1;
		private static const CTRL:uint = 1<<1;
		private static const ALT:uint = 1<<2;
		
		public var char:String;
		public var extra:uint;
		
		public function KeyBind(character:String, shift:Boolean = false, ctrl:Boolean = false, alt:Boolean = false)
		{
			if(!character || character.length != 1){
				throw new Error("KeyBind: character (first char) must be a single character. You gave ["+character+"]");
			}
			char = character.toUpperCase();
			if(shift) extra |= SHIFT;
			if(ctrl) extra |= CTRL;
			if(alt) extra |= ALT;
		}
		
		public function get key():String
		{
			return char+extra;
		}
		public function toString():String
		{
			var str:String = char;
			if(extra & SHIFT) str+="+shift";
			if(extra & CTRL) str+="+ctrl";
			if(extra & ALT) str+="+alt";
			return str;
		}
	}
}
