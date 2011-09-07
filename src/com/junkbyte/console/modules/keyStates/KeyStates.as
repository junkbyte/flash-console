package com.junkbyte.console.modules.keyStates {
	import com.junkbyte.console.Console;
	import com.junkbyte.console.core.ConsoleModule;
	import com.junkbyte.console.modules.ConsoleModuleNames;
	
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
			
			if(display.stage)
			{
				stageAddedHandle();
			}
			else 
			{
				display.addEventListener(Event.ADDED_TO_STAGE, stageAddedHandle);
			}
		}
		
		override public function getModuleName():String
		{
			return ConsoleModuleNames.KEY_STATES;
		}
		
		protected function stageAddedHandle(e:Event=null):void
		{
			display.removeEventListener(Event.ADDED_TO_STAGE, stageAddedHandle);
			display.addEventListener(Event.REMOVED_FROM_STAGE, stageRemovedHandle);
			display.stage.addEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown, true, 0, true);
			display.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler, false, 0, true);
			display.stage.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler, false, 0, true);
		}
		
		protected function stageRemovedHandle(e:Event=null):void
		{
			display.removeEventListener(Event.REMOVED_FROM_STAGE, stageRemovedHandle);
			display.addEventListener(Event.ADDED_TO_STAGE, stageAddedHandle);
			display.stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
			display.stage.removeEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
			display.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown, true);
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
