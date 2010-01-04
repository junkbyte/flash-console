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

package com.luaye.console.view {
	import com.luaye.console.Console;

	import flash.events.Event;
	import flash.events.TextEvent;

	public class MemoryPanel extends GraphingPanel {
		
		//
		public function MemoryPanel(m:Console) {
			super(m, 80,40);
			name = Console.PANEL_MEMORY;
			updateEvery = 5;
			drawEvery = 5;
			minimumWidth = 32;
			//master.mm.addEventListener(MemoryMonitor.GARBAGE_COLLECTED, onGC, false, 0, true);
			//master.mm.notifyGC = !m.isRemote;
			add(this, "current", 0x5060FF, "Memory");
		}
		public override function close():void {
			super.close();
			master.panels.updateMenu(); // should be black boxed :/
		}
		public function get current():Number{
			// in MB, up to 2 decimal
			return Math.round(master.currentMemory/10485.76)/100;
		}
		protected override function onFrame(e:Event):Boolean{
			if(super.onFrame(e)){
				updateKeyText();
				return true;
			}
			return false;
		}
		public override function updateKeyText():void{
			var mem:Number = getCurrentOf(0);
			if(mem>0){
				keyTxt.htmlText =  "<r><s>"+mem.toFixed(2)+"mb <menu><a href=\"event:gc\">G</a> <a href=\"event:reset\">R</a> <a href=\"event:close\">X</a></menu></r></s>";
			}else{
				keyTxt.htmlText = "<r><s><y>no mem input</y> <menu><a href=\"event:close\">X</a></menu></s></r>";
			}
		}
		protected override function linkHandler(e:TextEvent):void{
			if(e.text == "gc"){
				master.gc();
			}
			super.linkHandler(e);
		}
		//
		
		protected override function onMenuRollOver(e:TextEvent):void{
			var txt:String = e.text?e.text.replace("event:",""):null;
			if(txt == "gc"){
				txt = "Garbage collect::Requires debugger version of flash player";
			}
			master.panels.tooltip(txt, this);
		}
		/*private function onGC(e:Event):void{
			mark(0xFF000000);
		}*/
	}
}
