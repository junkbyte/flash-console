/*
*
* Copyright (c) 2008-2011 Lu Aye Oo
*
* @author 		Lu Aye Oo
*
* http://code.google.com/p/flash-console/
* http://junkbyte.com
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
package com.junkbyte.console.view
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.core.ConsoleModule;
	import com.junkbyte.console.modules.ConsoleModuleNames;

	import flash.display.Stage;
	import flash.events.Event;

	public class StageModule extends ConsoleModule
	{
		private var _stage:Stage;

		private var _listeningConsole:Console;

		public function StageModule()
		{
			super();
		}

		public function get stage():Stage
		{
			return _stage;
		}

		override public function getModuleName():String
		{
			return ConsoleModuleNames.STAGE;
		}


		// This module can register it self to console when console layer is added to stage.
		public function registerSelfToConsoleWhenAddedToStage(console:Console):void
		{
			_listeningConsole = console;
			var layer:ConsoleLayer = _listeningConsole.layer;
			if (_listeningConsole.layer.stage != null)
			{
				onAddedToStage();
			}
			else
			{
				_listeningConsole.layer.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			}
		}

		private function onAddedToStage(e:Event = null):void
		{
			var layer:ConsoleLayer = _listeningConsole.layer;
			layer.removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			layer.addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
			_stage = layer.stage;
			registerSelf();
		}

		private function onRemovedFromStage(e:Event):void
		{
			var layer:ConsoleLayer = _listeningConsole.layer;
			layer.removeEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
			layer.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			_stage = null;
			unregisterSelf();
		}

		protected function registerSelf():void
		{
			_listeningConsole.modules.registerModule(this);
		}

		protected function unregisterSelf():void
		{
			_listeningConsole.modules.unregisterModule(this);
		}
	}
}
