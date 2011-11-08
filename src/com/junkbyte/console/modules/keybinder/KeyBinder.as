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
package com.junkbyte.console.modules.keybinder 
{
	import com.junkbyte.console.KeyBind;
	import com.junkbyte.console.modules.ConsoleModuleNames;
	import com.junkbyte.console.modules.commandLine.ICommandLine;
	import com.junkbyte.console.view.StageModule;

	import flash.display.Stage;
	import flash.events.KeyboardEvent;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import com.junkbyte.console.core.ConsoleModule;
	import com.junkbyte.console.core.ModuleTypeMatcher;

	/**
	 * Suppose this could be 'view' ?
	 */
	public class KeyBinder extends ConsoleModule{
		
		private var _passInd:int;
		private var _binds:Object = {};
		
		private var _warns:uint;
		
		public function KeyBinder() {
			super();
			
			addModuleRegisteryCallback(new ModuleTypeMatcher(StageModule), stageRegistered, stageUnregistered);
			addModuleRegisteryCallback(new ModuleTypeMatcher(ICommandLine), commandLineRegistered, commandLineUnregistered);
		}
		
		override public function getModuleName():String
		{
			return ConsoleModuleNames.KEYBINDER;
		}
		protected function stageRegistered(module:StageModule):void
		{
			var stage:Stage = module.stage;
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler, false, 0, true);
			stage.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler, false, 0, true);
		}
		
		protected function stageUnregistered(module:StageModule):void
		{
			var stage:Stage = module.stage;
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
			stage.removeEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
		}
		
		protected function commandLineRegistered(module:ICommandLine):void
		{
			module.addInternalSlashCommand("keybinds", printBinds, "List all keybinds used");
		}
		
		protected function commandLineUnregistered(module:ICommandLine):void
		{
			module.addInternalSlashCommand("keybinds", null);
		}

		public function bindKey(key:KeyBind, fun:Function ,args:Array = null):void{
			if(config.keystrokePassword && (!key.useKeyCode && key.key.charAt(0) == config.keystrokePassword.charAt(0))){
				report("Error: KeyBind ["+key.key+"] is conflicting with Console password.",9);
				return;
			}
			if(fun == null){
				delete _binds[key.key];
			}else{
				_binds[key.key] = [fun, args];
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
						layer.toggleVisibility();
					}else if(_warns < 3){
						_warns++;
						report("Password did not trigger because you have focus on an input TextField.", 8);
					}
				}
			}
			else
			{
				if(!isKeyUp) _passInd = 0;
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
				if(layer.stage && layer.stage.focus is TextField){
					var txt:TextField = layer.stage.focus as TextField;
					if(txt.type == TextFieldType.INPUT) {
						return false;
					}
				}
			}catch(err:Error) { }
			return true;
		}
	}
}