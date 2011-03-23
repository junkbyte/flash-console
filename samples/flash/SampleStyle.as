/*
* 
* Copyright (c) 2008-2010 Lu Aye Oo
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
package 
{
	import com.junkbyte.console.Cc;

	import flash.display.*;

	[SWF(width='640',height='420',backgroundColor='0',frameRate='30')]
	// Might want to add compile argument: -use-network=false -debug=true

	public dynamic class SampleStyle extends MovieClip{
		
		public function SampleStyle() {
			//
			// SETUP - only required once
			//
			// you must modify the styles before starting console.
			Cc.config.style.big(); // BIGGER text. this modifies the config variables such as traceFontSize, menuFontSize
			Cc.config.style.whiteBase(); // Black on white. this modifies the config variables such as priority0, priority1, etc
			Cc.config.style.backgroundAlpha = 1; // makes it non-transparent background.
			
			//// Alternatively you can modify the style variables directly:
			//config.style.traceFontSize = 16;
			//config.style.menuColor = 0xFF0000;
			//
			
			Cc.startOnStage(this, "`"); // "`" - change for password. This will start hidden
			Cc.visible = true; // show console, because having password hides console.
			Cc.commandLine = true; // enable command line
			Cc.config.commandLineAllowed = true;
			
			Cc.width = 640;
			Cc.height = 320;
			//
			// END OF SETUP
			//
			
			
			// 
			// SAMPLE LOGS
			//
			Cc.info("Hello world.");
			Cc.log("A log message for console.", "optionally there", "can be", "multiple arguments.");
			Cc.debug("A debug level log.");
			Cc.warn("This is a warning log.");
			Cc.error("This is an error log.", "multiple arguments are supported", "for above basic logging methods.");
			Cc.fatal("This is a fatal error log.", "with high visibility");
			//
			Cc.infoch("myChannel", "Hello myChannel.");
			Cc.logch("myChannel", "A log message at myChannel.", "optionally there", "can be", "multiple arguments.");
			Cc.debugch("myChannel", "A debug level log.");
			Cc.warnch("myChannel", "This is a warning log.");
			Cc.errorch("myChannel", "This is an error log.", "multiple arguments are supported", "for above basic logging methods.");
			
			
			Cc.info("Custom css examples:");	
			Cc.config.style.styleSheet.setStyle("purple",{color:'#FF00FF', fontWeight:'bold', display:'inline'});
			Cc.addHTML("My special <purple>PURPLE</purple> text.");
			
			Cc.config.style.styleSheet.setStyle(".spacy",{letterSpacing:10});
			Cc.addHTML("Here is <span class='spacy'>big letter spacing</span>.");
			
			
		}
	}
}
