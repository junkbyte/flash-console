/*
* 
* Copyright (c) 2008 Atticmedia
* 
* @author 		Lu Aye Oo
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
* 
*/
package com.atticmedia.console.samples {
	import flash.utils.*;	
	import flash.events.MouseEvent;	
	import flash.display.*;
	import com.atticmedia.console.*;

	public class Sample extends MovieClip{

		public function Sample() {
			//
			// SET UP
			C.start(this, ""); 
			// "" - change for password. this will start hidden
			
			C.commandLine = true; // enable command line
			
			C.fpsMode = 2; // enable FPS monitor with setting 2
			
			C.width = 600;
			C.height = 200;//C.tracing = true; // trace on flash's normal trace
			
			C.remoting = true;

			// LOGGING
			C.add("This is an important error alert! (priority 10)", 10);
			C.add("This is a less importnat error alert. (priority 9)", 9);
			C.add("This is a warning! (priority 8)", 8);
			C.add("This is a message (priority 5)", 5);
			C.add("This is a default log level (priority 2)", 2);
			C.add("This is totally a dummy (priority 0)", 0);

			//
			C.ch("myChannel", "Hello my Channel");
			C.ch("myChannel", "Hello importnat message at my channel", 10);

			// press @ at the top for console menu.
			// press H on second right for console menu help

			// if you want to use command line, please type /help 
			// in command line at the bottom for examples

			// garbage collection monitor
			var aSprite:Sprite = new Sprite();
			C.watch(aSprite, "aSprite");
			aSprite = null;
			// it will probably never get collected in this example
			// but if you have debugger version of flash player installed,
			// you can press G in console menu (press @ at top) to force garbage collect
			
			
			
			btnInterval.addEventListener(MouseEvent.CLICK, onButtonClick);
			btnAdd.addEventListener(MouseEvent.CLICK, onButtonClick);
			btnAddChannel.addEventListener(MouseEvent.CLICK, onButtonClick);
		}
		private function onButtonClick(e:MouseEvent):void{
			switch(e.currentTarget){
				case btnAdd:
					C.add("adding test text");
				break;
				case btnInterval:
					if(_interval){
						clearInterval(_interval);
						_interval = 0;
						btnInterval.label = "Start Interval";
					}else{
						_interval = setInterval(onIntervalEvent,100);
						btnInterval.label = "Stop Interval";
					}
				break;
				case btnAddChannel:
					C.ch("myChannel","adding test text");
				break;
			}
		}
		private function onIntervalEvent():void{
			C.add("Repeative log _ " + getTimer(), 5,true);
		}
		
		
		private var _interval:uint;
	}
}
