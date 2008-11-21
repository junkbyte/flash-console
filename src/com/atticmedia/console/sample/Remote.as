package com.atticmedia.console.samples {
	

	import com.atticmedia.console.*;

	import flash.display.*;
	import flash.events.*;

	/**
	 * @author lu
	 */
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
