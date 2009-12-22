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
	import com.luaye.console.C;
	import flash.geom.Rectangle;	
	import flash.utils.*;	
	import flash.events.MouseEvent;	
	import flash.display.*;
	import flash.text.*;
	import com.luaye.console.Ch;

	public dynamic class Sample extends MovieClip{
		
		private var _spamcount:int;
		
		//private var _ch:Ch = new Ch('chan');
		
		public function Sample() {
			//
			// SET UP
			C.startOnStage(this, "`"); 
			// "`" - change for password. This will start hidden
			C.remotingPassword = null;
			C.visible = true; // show console, because having password hides console.
			//C.tracing = true; // trace on flash's normal trace
			C.commandLine = true; // enable command line
			
			C.width = 640;
			C.height = 220;
			C.maxLines = 2000;
			C.fpsMonitor = true;
			C.remoting = true;
			
			TextField(txtPriority).restrict = "0-9";
			TextField(txtPriority2).restrict = "0-9";
			setUpButton(btnInterval, "Start interval");
			setUpButton(btnAdd1, "Add");
			setUpButton(btnAdd2, "Add");
			setUpButton(btnSpam, "Spam");
			
			//
			// basic logging
			//
			C.info("Hello world.");
			C.log("A log message for console.", "optionally there", "can be", "multiple arguments.");
			C.debug("A debug level log.");
			C.warn("This is a warning log.");
			C.error("This is an error log.", "multiple arguments are supported", "for above basic logging methods.");
			//
			// basic channel logging
			//
			C.infoch("myChannel", "Hello myChannel.");
			C.logch("myChannel", "A log message at myChannel.", "optionally there", "can be", "multiple arguments.");
			C.debugch("myChannel", "A debug level log.");
			C.warnch("myChannel", "This is a warning log.");
			C.errorch("myChannel", "This is an error log.", "multiple arguments are supported", "for above basic logging methods.");
			//
			// advanced logging
			//
			C.add("My advanced log in priority 7.", 7);
			C.add("My advanced log in priority 2, 1 (no repeats)", 2, true);
			C.add("My advanced log in priority 2, 2 (no repeats)", 2, true);
			C.add("My advanced log in priority 2, 3 (no repeats)", 2, true);
			//
			// Advanced channel logging
			//
			C.ch("chn", "Advanced log in priority 7.", 7);
			C.ch("chn", "Advanced log in priority 3, 1 (no repeats)", 3, true);
			C.ch("chn", "Advanced log in priority 3, 2 (no repeats)", 3, true);
			C.ch("chn", "Advanced log in priority 3, 3 (no repeats)", 3, true);
			
			//
			// DEMO
			//
			
			//
			// Set key to capture display map, - only works when DisplayRoller (RL) is active.
			C.setRollerCaptureKey("c");
			
			//
			// garbage collection monitor
			var aSprite:Sprite = new Sprite();
			C.watch(aSprite, "aSprite");
			C.store("sprite", aSprite);
			aSprite = null;
			// it will probably won't get garbage collected straight away,
			// but if you have debugger version of flash player installed,
			// you can open memory monitor (M) and then press G in that panel to force garbage collect
			
			//
			//Add graph show the mouse X/Y positions
			C.addGraph("mouse", this,"mouseX", 0xff3333,"mouseX");
			C.addGraph("mouse", this,"mouseY", 0x3333ff,"Y", new Rectangle(340,225,80,80), true);
			
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
				case btnSpam:
					spam();
				break;
			}
		}
		private function onIntervalEvent():void{
			C.add("Repeative log _ " + getTimer(), 5,true);
		}
		private function spam():void{
			for(var i:int = 0;i<100;i++){
				var str:String = "Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.";
				var rand:int = Math.random()*5;
				if(rand == 1){
					str = "Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam,";
				}else if(rand == 2){
					str = "At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi";
				}else if(rand == 3){
					str = "Temporibus autem quibusdam et aut officiis debitis aut rerum necessitatibus saepe eveniet ut et voluptates repudiandae sint et molestiae non recusandae.";
				}else if(rand == 4){
					str = "Itaque earum rerum hic tenetur a sapiente delectus.";
				}else if(rand == 5){
					str = "voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi, id est laborum et dolorum fuga. Et harum quidem rerum facilis est et expedita distinctio. Nam libero tempore, cum soluta nobis";
				}
				_spamcount++;
				C.ch("ch"+Math.round(Math.random()*5), _spamcount+" "+str, Math.round(Math.random()*10));
			}
		}
		
		private var _interval:uint;
	}
}
