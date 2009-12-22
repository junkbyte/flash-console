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
	import com.luaye.console.view.GraphingPanel;
	
	import flash.events.Event;

	public class FPSPanel extends GraphingPanel {
		//
		private var _cachedCurrent:Number;
		//
		public function FPSPanel(m:Console) {
			super(m, 80,40);
			name = Console.PANEL_FPS;
			lowest = 0;
			minimumWidth = 32;
			add(this, "current", 0xFF3333, "FPS");
		}
		public override function close():void {
			super.close();
			master.panels.updateMenu(); // should be black boxed :/
		}
		//public override function reset():void {
		//	//lowest = NaN;
		//	super.reset();
		//}
		public override function stop():void {
			super.stop();
			reset();
		}
		public override function updateKeyText():void{
			if(_history.length>0){
				keyTxt.htmlText = "<r><s>"+master.fps.toFixed(1)+" | "+getAverageOf(0).toFixed(1)+" <menu><a href=\"event:reset\">R</a> <a href=\"event:close\">X</a></menu></r></s>";
			}else{
				keyTxt.htmlText = "<r><s><y>no fps input</y> <menu><a href=\"event:close\">X</a></menu></s></r>";
			}
		}
		public function get current():Number{
			if(isNaN(_cachedCurrent))
				return master.fps;
			var mspf:Number = _cachedCurrent;
			_cachedCurrent = NaN;
			return mspf;
		}
		public function addCurrent(n:Number):void{
			_cachedCurrent = n;
			updateData();
		}
		protected override function onFrame(e:Event):Boolean{
			if(master.remote) return false;
			var mspf:Number = master.mspf;
			if (!isNaN(mspf)) {
				if(super.onFrame(e)){
					updateKeyText();
					if(stage){
						fixed = true;
						averaging = stage.frameRate;
						highest = averaging;
						var frames:int = Math.floor(mspf/(1000/highest));
						// this is to try add the frames that have been lagged
						if(frames>Console.FPS_MAX_LAG_FRAMES) frames = Console.FPS_MAX_LAG_FRAMES; // Don't add too many
						while(frames>1){
							updateData();
							frames--;
						}
					}
					return true;
				}
			}
			return false;
		}
	}
}
