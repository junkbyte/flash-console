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
package com.junkbyte.console.core 
{
	import flash.text.TextFieldType;
	import flash.text.TextField;
	import com.junkbyte.console.Console;
	import com.junkbyte.console.KeyBind;

	import flash.events.KeyboardEvent;

	/**
	 * @private
	 * 
	 * Suppse this could be 'view' ?
	 */
	public class KeyBinder extends ConsoleCore{
		
		private var _passInd:int;
		private var _binds:Object = {};
		
		private var _warns:uint;
		
		public function KeyBinder(console:Console) {
			super(console);
			
			console.cl.addCLCmd("keybinds", printBinds, "List all keybinds used");
		}
		public function bindKey(key:KeyBind, fun:Function ,args:Array = null):void{
			if(config.keystrokePassword && (!key.useKeyCode && key.key.charAt(0) == config.keystrokePassword.charAt(0))){
				report("Error: KeyBind ["+key.key+"] is conflicting with Console password.",9);
				return;
			}
			if(fun == null){
				delete _binds[key.key];
				//if(!config.quiet) report("Unbined key "+key.key+".", -1);
			}else{
				_binds[key.key] = [fun, args];
				//if(!config.quiet) report("Bined key "+key.key+" to a function."+(config.keyBindsEnabled?"":" (will not trigger while key binding is disabled in config)"), -1);
			}
		}
		public function keyDownHandler(e:KeyboardEvent):void{
			handleKeyEvent(e, false);
		}
		public function keyUpHandler(e:KeyboardEvent):void{
			handleKeyEvent(e, true);
		}
		
		private function handleKeyEvent(e:KeyboardEvent, isKeyUp:Boolean):void
		{
			var char:String = String.fromCharCode(e.charCode);
			if(isKeyUp && config.keystrokePassword != null && char && char == config.keystrokePassword.substring(_passInd,_passInd+1)){
				_passInd++;
				if(_passInd >= config.keystrokePassword.length){
					_passInd = 0;
					if(canTrigger()){
						if(console.visible && !console.panels.mainPanel.visible){
							console.panels.mainPanel.visible = true;
						}else {
							console.visible = !console.visible;
						}
						if(console.visible && console.panels.mainPanel.visible){
							console.panels.mainPanel.visible = true;
							console.panels.mainPanel.moveBackSafePosition();
						}
					}else if(_warns < 3){
						_warns++;
						report("Password did not trigger because you have focus on an input TextField.", 8);
					}
				}
			}
			else
			{
				if(isKeyUp) _passInd = 0;
				var bind:KeyBind = new KeyBind(e.keyCode, e.shiftKey, e.ctrlKey, e.altKey, isKeyUp);
				tryRunKey(bind.key);
				if(char){
					bind = new KeyBind(char, e.shiftKey, e.ctrlKey, e.altKey, isKeyUp);
					tryRunKey(bind.key);
				}
			}
		}
		private function printBinds(...args:Array):void{
			report("Key binds:", -2);
			var i:uint = 0;
			for (var X:String in _binds){
				i++;
				report(X, -2);
			}
			report("--- Found "+i, -2);
		}
		private function tryRunKey(key:String):void
		{
			var a:Array = _binds[key];
			if(config.keyBindsEnabled && a){
				if(canTrigger()){
					(a[0] as Function).apply(null, a[1]);
				}else if(_warns < 3){
					_warns++;
					report("Key bind ["+key+"] did not trigger because you have focus on an input TextField.", 8);
				}
			}
		}
		private function canTrigger():Boolean{
			// in try catch block incase the textfield is in another domain and we wont be able to access the type... (i think)
			try {
				if(console.stage && console.stage.focus is TextField){
					var txt:TextField = console.stage.focus as TextField;
					if(txt.type == TextFieldType.INPUT) {
						return false;
					}
				}
			}catch(err:Error) { }
			return true;
		}
	}
}