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
		
		private var _code:Boolean;
		private var _key:String;
		
		/**
		 * @param code Pass a single string (e.g. "a") OR pass keyCode (e.g. Keyboard.F1)
		 * @param shift Set true if shift key needs to be pressed to trigger
		 * @param ctrl Set true if ctrl key needs to be pressed to trigger
		 * @param alt Set true if alt key needs to be pressed to trigger
		 */
		public function KeyBind(v:*, shift:Boolean = false, ctrl:Boolean = false, alt:Boolean = false, onUp:Boolean = false)
		{
			_key = String(v).toUpperCase();
			if(v is uint){
				_code = true;
			}else if(!v || _key.length != 1) {
				throw new Error("KeyBind: character (first char) must be a single character. You gave ["+v+"]");
			}
			
			if(_code) _key = "keycode:"+_key;
			if(shift) _key+="+shift";
			if(ctrl) _key+="+ctrl";
			if(alt) _key+="+alt";
			if(onUp) _key+="+up";
			
		}
		
		public function get useKeyCode():Boolean
		{
			return _code;
		}
		public function get key():String
		{
			return _key;
		}
	}
}