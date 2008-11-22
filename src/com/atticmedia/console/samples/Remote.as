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
	

	import com.atticmedia.console.*;

	import flash.display.*;
	import flash.events.*;

	public class Remote extends MovieClip {

		public function Remote() {
			C.start(this, "");
			C.isRemote = true;
			C.commandLine = true;
			C.menuMode = 0;
			
			//
			// This is special case for remote to disable scaling and moving
			C.instance.getChildByName("scaler").visible = false;
			C.instance.moveable = false;
			//
			
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(Event.RESIZE, onStageResize);
			onStageResize();
		}
		private function onStageResize(e : Event = null) : void {
			C.width = stage.stageWidth;
			C.height = stage.stageHeight;
		}
	}
}
