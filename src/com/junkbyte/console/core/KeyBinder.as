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
package com.junkbyte.console.core {
	import com.junkbyte.console.KeyBind;
	import flash.events.KeyboardEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;

	/**
	 * Suppse this could be 'view' ?
	 */
	public class KeyBinder extends EventDispatcher {
		
		private var _password:String;
		private var _passwordIndex:int;
		private var _keyBinds:Object = {};
		
		public function KeyBinder(pass:String) {
			_password = pass == ""?null:pass;
		}
		public function keyDownHandler(e:KeyboardEvent):void{
			var char:String = String.fromCharCode(e.charCode);
			if(!char) return;
			if(_password != null && char == _password.substring(_passwordIndex,_passwordIndex+1)){
				_passwordIndex++;
				if(_passwordIndex >= _password.length){
					_passwordIndex = 0;
					dispatchEvent(new Event(Event.CONNECT));
				}
			}
			else
			{
				_passwordIndex = 0;
				var keybind:KeyBind = new KeyBind(char, e.shiftKey, e.ctrlKey, e.altKey);
				if(_keyBinds[keybind.key]){
					var bind:Array = _keyBinds[keybind.key];
					(bind[0] as Function).apply(this, bind[1]);
				}
			}
		}
		public function bindKey(key:KeyBind, fun:Function ,args:Array = null):void{
			var keystr:String = key.key;
			if(fun == null){
				delete _keyBinds[keystr];
			}else{
				_keyBinds[keystr] = [fun, args];
			}
		}
	}
}
