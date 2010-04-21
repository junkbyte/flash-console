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
	import flash.events.TextEvent;

	import com.luaye.console.Console;
	import com.luaye.console.view.GraphingPanel;
	import com.luaye.console.vos.GraphGroup;

	public class FPSPanel extends GraphingPanel {
		//
		public function FPSPanel(m:Console) {
			super(m, 80,40);
			name = Console.PANEL_FPS;
			minimumWidth = 32;
			// 
		}
		protected override function linkHandler(e:TextEvent):void{
			if(e.text == "close"){
				master.fpsMonitor = false;
			}else{
				super.linkHandler(e);
			}
		}
		public override function update(group:GraphGroup, draw:Boolean = true):void{
			super.update(group, draw);
			updateKeyText();
		}
		public override function updateKeyText():void{
			if(isNaN(_interest.v)) {
				keyTxt.htmlText = "<r><s>no fps input <menu><a href=\"event:close\">X</a></menu></s></r>";
			}else{
				keyTxt.htmlText = "<r><s>"+_interest.v.toFixed(1)+" | "+_interest.avg.toFixed(1)+" <menu><a href=\"event:reset\">R</a> <a href=\"event:close\">X</a></menu></r></s>";
			}
			keyTxt.scrollH = keyTxt.maxScrollH;
		}
	}
}
