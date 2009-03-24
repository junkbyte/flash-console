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
	import flash.utils.*;	
	import flash.events.MouseEvent;	
	import flash.display.*;
	import flash.text.*;
	import com.atticmedia.console.*;

	public class RegressionTest extends MovieClip{
		
		private var _c:Console;
		/*
		
		// WORK IN PROGRESS //
		// WORK IN PROGRESS //
		// WORK IN PROGRESS //
		// WORK IN PROGRESS //
		// WORK IN PROGRESS //
		// WORK IN PROGRESS //
		// WORK IN PROGRESS //
		// WORK IN PROGRESS //
		
		*/
		public function RegressionTest() {
			
			//
			// regression tester
			_c = new Console();
			_c.width = 600;
			_c.height = 200;
			_c.alwaysOnTop = false;
			_c.commandLine = true;
			addChild(_c);
			
			_c.add("-- This is the regression tester");
			
			
			//
			// test subject
			C.start(this, "");  
			C.x = 20;
			C.y = 250;
			C.commandLine = true;
			C.fpsMode = 2;
			C.menuMode = 2;
			C.width = 600;
			C.height = 200;
			C.remoting = true;
			C.add("-- This is the test subject");
			
			//
			//
			_c.add("this = "+C.runCommand("this"));
		}
	}
}
