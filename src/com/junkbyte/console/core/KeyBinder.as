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
		
		private var _pass:String;
		private var _passInd:int;
		private var _binds:Object = {};
		
		public function KeyBinder(pass:String) {
			_pass = pass == ""?null:pass;
		}
		public function keyDownHandler(e:KeyboardEvent):void{
			var char:String = String.fromCharCode(e.charCode);
			if(_pass != null && char && char == _pass.substring(_passInd,_passInd+1)){
				_passInd++;
				if(_passInd >= _pass.length){
					_passInd = 0;
					dispatchEvent(new Event(Event.CONNECT));
				}
			}
			else
			{
				_passInd = 0;
				var bind:KeyBind = new KeyBind(e.keyCode, e.shiftKey, e.ctrlKey, e.altKey);
				tryRunKey(bind.key);
				if(char){
					bind = new KeyBind(char, e.shiftKey, e.ctrlKey, e.altKey);
					tryRunKey(bind.key);
				}
			}
		}
		private function tryRunKey(key:String):void
		{
			var a:Array = _binds[key];
			if(a){
				(a[0] as Function).apply(this, a[1]);
			}
		}
		public function bindKey(key:KeyBind, fun:Function ,args:Array = null):Boolean{
			if(_pass && (key.useChar &&  key.char == _pass.charAt(0)))
			{
				return false;
			}
			var keystr:String = key.key;
			if(fun == null){
				delete _binds[keystr];
			}else{
				_binds[keystr] = [fun, args];
			}
			return true;
		}
	}
}
