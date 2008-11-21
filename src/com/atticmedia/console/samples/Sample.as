package com.atticmedia.console.samples {
	
	import flash.display.*;
	import com.atticmedia.console.*;
	/**
	 * @author lu
	 */
	public class Sample extends MovieClip{

		public function Sample() {
			//
			// SET UP
			C.start(this, ""); 
			// "" - change for password. this will start hidden
			
			C.prefixChannelNames = false;
			C.commandLine = true; // enable command line
			
			C.fpsMode = 2; // enable FPS monitor with setting 2
			
			C.width = 500;
			C.height = 300;//C.tracing = true; // trace on flash's normal trace
			
			C.remoting = true;

			// LOGGING
			C.add("Hello world");
			C.add("This is important!", 10);
			C.add("This is not really important", 7);
			C.add("This is totally a dummy", 0);

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
		}
	}
}
