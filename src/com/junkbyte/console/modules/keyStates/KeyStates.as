package com.junkbyte.console.modules.keyStates {
	import com.junkbyte.console.Console;
	import com.junkbyte.console.core.ConsoleModule;
	import com.junkbyte.console.interfaces.IConsoleModule;
	import com.junkbyte.console.modules.ConsoleModuleNames;
	import com.junkbyte.console.view.StageModule;
	import com.junkbyte.console.vos.ConsoleModuleMatch;
	
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;

	public class KeyStates extends ConsoleModule implements IKeyStates
	{
		
		protected var _keyDownsByKeyCode:Object = new Object();
		
		public function KeyStates()
		{
			super();
		}
		
		override public function registeredToConsole(console:Console):void
		{
			super.registeredToConsole(console);
		}
		
		override public function getDependentModules():Vector.<ConsoleModuleMatch>
		{
			var vect:Vector.<ConsoleModuleMatch> = super.getDependentModules();
			vect.push(ConsoleModuleMatch.createForClass(StageModule));
			return vect;
		}
		
		override public function dependentModuleRegistered(module:IConsoleModule):void
		{
			if(module is StageModule)
			{
				var stage:Stage = StageModule(module).stage;
				stage.addEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown, true, 0, true);
				stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler, false, 0, true);
				stage.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler, false, 0, true);
			}
		}
		
		override public function dependentModuleUnregistered(module:IConsoleModule):void
		{
			if(module is StageModule)
			{
				var stage:Stage = StageModule(module).stage;
				stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
				stage.removeEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
				stage.removeEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown, true);
			}
		}
		
		override public function getModuleName():String
		{
			return ConsoleModuleNames.KEY_STATES;
		}

		protected function onStageMouseDown(e : MouseEvent) : void
		{
			setKeyCodeState(Keyboard.CONTROL, e.ctrlKey);
			setKeyCodeState(Keyboard.SHIFT, e.shiftKey);
			setKeyCodeState(18, e.altKey);
		}
		
		protected function setKeyCodeState(keyCode:uint, isDown:Boolean):void
		{
			if(isDown)
			{
				_keyDownsByKeyCode[keyCode] = true;
			}
			else
			{
				delete _keyDownsByKeyCode[keyCode];
			}
		}

		protected function keyDownHandler(e:KeyboardEvent):void
		{
			setKeyCodeState(e.keyCode, true);
		}
		
		protected function keyUpHandler(e:KeyboardEvent):void
		{
			setKeyCodeState(e.keyCode, false);
		}
		
		public function get altKeyDown():Boolean
		{
			return isKeyCodeDown(18); //Keyboard.ALTERNATE not supported in flash 9
		}
		
		public function get ctrlKeyDown():Boolean
		{
			return isKeyCodeDown(Keyboard.CONTROL);
		}
		
		public function get shiftKeyDown():Boolean
		{
			return isKeyCodeDown(Keyboard.SHIFT);
		}
		
		public function isKeyCodeDown(keyCode:uint):Boolean
		{
			return _keyDownsByKeyCode[keyCode] == true;
		}
	}
}
