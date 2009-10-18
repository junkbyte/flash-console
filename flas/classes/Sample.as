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
package {
	import flash.geom.Rectangle;	
	import flash.utils.*;	
	import flash.events.MouseEvent;	
	import flash.display.*;
	import flash.text.*;
	import com.atticmedia.console.*;

	public dynamic class Sample extends MovieClip{

		public function Sample() {
			//
			// SET UP
			//C.start(this, "", 2);
			C.start(this, "`"); 
			// "`" - change for password. This will start hidden
			C.visible = true; // show console, because having password hides console.
			C.tracing = true; // trace on flash's normal trace
			C.commandLine = true; // enable command line
			//C.commandLinePermission = 1;
			C.width = 600;
			C.height = 200;
			
			C.remoting = true;

			// LOGGING
			C.add("This is an important error alert! (priority 10)", 10);
			C.add("This is a less important error alert. (priority 9)", 9);
			C.add("This is a warning! (priority 8)", 8);
			C.add("This is a message (priority 5)", 5);
			C.add("This is a default log level (priority 2)", 2);
			C.add("This is totally a dummy (priority 0)", 0);
			//
			C.ch("myChannel", "Hello my Channel");
			C.ch("myChannel", "Hello important message at my channel", 10);
			
			//
			//
			// Convenience logging... infinite arguments
			C.log("Log", "with multiple", "arguments");
			C.message("Message", "with multiple", "arguments");
			C.debug("Debug", "with multiple", "arguments");
			C.warning("Warning", "with multiple", "arguments");
			C.error("Error", "with multiple", "arguments");
			//
			// Convenience logging with channel... infinite arguments
			C.logch("myChannel", "Log", "with multiple", "arguments");
			C.messagech("myChannel", "Message", "with multiple", "arguments");
			C.debugch("myChannel", "Debug", "with multiple", "arguments");
			C.warningch("myChannel", "Warning", "with multiple", "arguments");
			C.errorch("myChannel", "Error", "with multiple", "arguments");		
			
			
			
			// if you want to use command line, please type /help 
			// in command line at the bottom for examples

			C.setRollerCaptureKey("c");
			
			// garbage collection monitor
			var aSprite:Sprite = new Sprite();
			C.watch(aSprite, "aSprite");
			C.store("sprite", aSprite);
			aSprite = null;
			// it will probably never get collected in this example
			// but if you have debugger version of flash player installed,
			// you can open memory monitor (M) and then press G in that panel to force garbage collect
			
			//Add graph show the mouse X/Y positions
			C.addGraph("mouse", this,"mouseX", 0xff3333,"mouseX");
			C.addGraph("mouse", this,"mouseY", 0x3333ff,"Y", new Rectangle(340,210,80,80), true);
			//C.fixGraphRange("mouse", 100,300);
			
			TextField(txtPriority).restrict = "0-9";
			TextField(txtPriority2).restrict = "0-9";
			setUpButton(btnInterval, "Start interval");
			setUpButton(btnAdd1, "Add");
			setUpButton(btnAdd2, "Add");
		}
		private function setUpButton(btn:MovieClip, t:String):void{
			btn.stop();
			btn.buttonMode = true;
			btn.mouseChildren = false;
			btn.txt.text = t;
			btn.addEventListener(MouseEvent.CLICK, onButtonClick);
			btn.addEventListener(MouseEvent.ROLL_OVER, onButtonEvent);
			btn.addEventListener(MouseEvent.ROLL_OUT, onButtonEvent);
		}
		private function onButtonEvent(e:MouseEvent):void{
			MovieClip(e.currentTarget).gotoAndStop(e.type==MouseEvent.ROLL_OVER?"over":"out");
		}
		private function onButtonClick(e:MouseEvent):void{
			switch(e.currentTarget){
				case btnAdd1:
					C.add(txtLog.text,int(txtPriority.text));
				break;
				case btnAdd2:
					C.ch(txtChannel.text, txtLog2.text,int(txtPriority2.text));
				break;
				case btnInterval:
					if(_interval){
						clearInterval(_interval);
						_interval = 0;
						btnInterval.txt.text = "Start Interval";
					}else{
						_interval = setInterval(onIntervalEvent,100);
						btnInterval.txt.text = "Stop Interval";
					}
				break;
			}
		}
		private function onIntervalEvent():void{
			C.add("Repeative log _ " + getTimer(), 5,true);
		}
		
		
		private var _interval:uint;
	}
}
