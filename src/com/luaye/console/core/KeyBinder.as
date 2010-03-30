/*
* 
* Copyright (c) 2008-2009 Lu Aye Oo
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
package com.luaye.console.core {
	import com.luaye.console.utils.Utils;

	import flash.events.KeyboardEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;

	/**
	 * Suppse this could be 'view' ?
	 */
	public class KeyBinder extends EventDispatcher {
		
		public static const PASSWORD_ENTERED:String = "PASSWORD_ENTERED";
		
		private var _password:String;
		private var _passwordIndex:int;
		private var _keyBinds:Object;
		
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
					dispatchEvent(new Event(PASSWORD_ENTERED));
				}
			}else if(_keyBinds != null){
				_passwordIndex = 0;
				var key:String = getKey(char, e.ctrlKey, e.altKey, e.shiftKey);
				if(_keyBinds[key]){
					var bind:Array = _keyBinds[key];
					(bind[0] as Function).apply(this, bind[1]);
				}
			}
		}
		public function bindKey(char:String, ctrl:Boolean, alt:Boolean, shift:Boolean, fun:Function ,args:Array = null):String{
			var key:String = getKey(char, ctrl, alt, shift);
			bindByKey(key, fun, args);
			return key; 
		}
		public function bindByKey(key:String, fun:Function ,args:Array = null):void{
			if(fun==null){
				if(_keyBinds != null) {
					delete _keyBinds[key];
					if(!Utils.HaveItemsInObject(_keyBinds)) _keyBinds = null;
				}
			}else{
				if(_keyBinds == null) _keyBinds = {};
				_keyBinds[key] = [fun,args];
			}
		}
		private function getKey(char:String, ctrl:Boolean = false, alt:Boolean = false, shift:Boolean = false):String{
			return char.toLowerCase()+(ctrl?"1":"0")+(alt?"1":"0")+(shift?"1":"0");
		}
		public static function GetStringOfKey(key:String):String{
			var str:String = key.charAt(0).toUpperCase();
			if(key.charAt(1) == "1") str+="+ctrl";
			if(key.charAt(2) == "1") str+="+alt";
			if(key.charAt(3) == "1") str+="+shift";
			return str;
		}
	}
}
