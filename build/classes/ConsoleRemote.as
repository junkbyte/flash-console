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

	import flash.display.*;
	import flash.events.*;

	[SWF(width='600',height='420',backgroundColor='0xCCCCCC',frameRate='25')]
	// used to compile in flex/fdt
	// To compile in flash, point this class as document class.
	// comment out the metadata tag above if you are getting an error.
	
	public class ConsoleRemote extends MovieClip {

		public function ConsoleRemote() {
			C.start(this, "");
			C.remote = true;
			C.commandLine = true;
			C.maxLines = 2000;
			
			//
			// This is special case for remote to disable scaling and moving
			C.instance.panels.mainPanel.moveable = false;
			C.instance.panels.mainPanel.scalable = false;
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