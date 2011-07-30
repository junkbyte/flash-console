package com.junkbyte.console.core {
	import com.junkbyte.console.Console;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;
	public class KeyStates extends ConsoleCore
	{
		
		public static const NAME:String = "keyStates";
		
		protected var _shift:Boolean;
		protected var _ctrl:Boolean;
		protected var _alt:Boolean;
		
		public function KeyStates()
		{
			super();
			
		}
		
		override public function registerConsole(console:Console):void
		{
			super.registerConsole(console);
			
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
			return NAME;
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
			_shift = e.shiftKey;
			_ctrl = e.ctrlKey;
			_alt = e.altKey;
		}
		
		public function get altKeyDown():Boolean
		{
			return _alt;
		}
		
		public function get ctrlKeyDown():Boolean
		{
			return _ctrl;
		}
		
		public function get shiftKeyDown():Boolean
		{
			return _shift;
		}

		protected function keyDownHandler(e:KeyboardEvent):void
		{
			if(e.keyCode == Keyboard.SHIFT) _shift = true;
			if (e.keyCode == Keyboard.CONTROL) _ctrl = true;
			if (e.keyCode == 18) _alt = true; //Keyboard.ALTERNATE not supported in flash 9
		}
		
		protected function keyUpHandler(e:KeyboardEvent):void
		{
			if(e.keyCode == Keyboard.SHIFT) _shift = false;
			else if(e.keyCode == Keyboard.CONTROL) _ctrl = false;
			else if (e.keyCode == 18) _alt = false;
		}
	}
}
