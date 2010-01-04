/*
* 
* Copyright (c) 2008-2009 Lu Aye Oo
* 
* @author Lu Aye Oo
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
	import com.luaye.console.Console;
	import com.luaye.console.view.AbstractPanel;
	
	import flash.display.MovieClip;
	import flash.display.NativeWindowDisplayState;
	import flash.display.NativeWindowResize;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.filters.GlowFilter;
	import flash.text.TextField;		

	public class ConsoleRemoteAIR extends MovieClip {
		
		private var _c:Console;
		
		public function ConsoleRemoteAIR() {
			
			stage.nativeWindow.alwaysInFront = true;
			
			//C.start(this, "", 951);
			_c = new Console(null, 951);
			addChild(_c);
			_c.maxLines = 2000;
			_c.visible = true;
			_c.remote = true;
			_c.commandLine = true;
			_c.x = 10;
			_c.y = 10;
			
			var menu:TextField = _c.panels.mainPanel.getChildByName("menuField") as TextField;
			menu.doubleClickEnabled = true;
			menu.addEventListener(MouseEvent.DOUBLE_CLICK, ondouble);
			_c.panels.mainPanel.addEventListener(AbstractPanel.STARTED_DRAGGING, moveHandle);
			_c.panels.mainPanel.addEventListener(AbstractPanel.STARTED_SCALING, scaleHandle);
			//_c.panels.mainPanel.addEventListener(AbstractPanel.CLOSED, closeHandle);
			_c.filters = [new GlowFilter(0, 0.7, 5, 5)];
			//
			_c.panels.mainPanel.addMenuKey("Sf");
			_c.panels.mainPanel.topMenuRollOver = onMenuRollOver;
			_c.panels.mainPanel.topMenuClick = onMenuClick;
			//
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(Event.RESIZE, onStageResize);
			onStageResize();
		}
		private function onMenuRollOver(key:String):String{
			switch (key){
				case "Sf":
					return "Save to file";
				case "close":
					return "Close";
			}
			return "";
		}
		private function onMenuClick(key:String):Boolean{
			if(key == "Sf"){
				var docsDir:File = File.documentsDirectory;
				try{
				    docsDir.browseForSave("Save Log As");
				    docsDir.addEventListener(Event.SELECT, saveData);
				}catch (err:Error){
				    _c.error("Failed:", err.message);
				}
				return true;
			}else if(key == "close"){
				stage.nativeWindow.close();
				return true;
			}
			return false;
		}
		private	function saveData(e:Event):void{
				var file:File = e.target as File;
				if(!file.exists){
					var path:String = file.nativePath;
					var dot:int = path.lastIndexOf(".");
					var separator:int = path.lastIndexOf(File.separator);
					if(dot<0 || separator > dot){
						file.nativePath = path+".txt";
					}
				}
				var str:String = _c.getAllLog(File.lineEnding);
				var stream:FileStream = new FileStream();
			try{
				stream.open(file, FileMode.WRITE);
				stream.writeUTFBytes(str);
				stream.close();
				_c.report("Saved log to "+file.nativePath, -1);
			}catch(e:Error){
				// maybe read-only , etc
				_c.report("There was a problem saving the log to "+file.nativePath+"\n"+e, 10);
			}
		}
		private function ondouble(e:Event):void {
			if(stage.nativeWindow.displayState != NativeWindowDisplayState.MAXIMIZED){
				stage.nativeWindow.maximize();
			}else{
				stage.nativeWindow.restore();
			}
		}
		private function moveHandle(e:Event):void {
			stage.nativeWindow.startMove();
		}
		private function scaleHandle(e:Event):void {
			_c.panels.mainPanel.stopScaling();
			stage.nativeWindow.startResize(NativeWindowResize.BOTTOM_RIGHT);
		}
		private function onStageResize(e : Event = null):void {
			_c.width = stage.stageWidth-20;
			_c.height = stage.stageHeight-20;
		}
	}
}