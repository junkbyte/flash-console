/*
*
* Copyright (c) 2008-2011 Lu Aye Oo
*
* @author 		Lu Aye Oo
*
* http://code.google.com/p/flash-console/
* http://junkbyte.com
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
package com.junkbyte.console {

	public class ConsoleConfig {
		
		//////////////////////
		//                  //
		//  LOGGING CONIFG  //
		//                  //
		//////////////////////
		
		/**
		 * Default stack trace depth
		 */
		public var defaultStackDepth:int = 2;
		
		/**
		 * Stack trace exit classes.
		 * Stack tracing will stop on reaching one of the first classes in the array.
		 */
		public var stackTraceExitClasses:Array = null;
		
		/**
		 * Seconds in which object links should be hard referenced for.
		 * If you logged a temp object (object that is not referenced anywhere else), it will become a link in console. 
		 * However it will get garbage collected almost straight away which prevents you from clicking on the object link. 
		 * (You will normally get this message: "Reference no longer exists")
		 * This feature allow you to set how many seconds console should hard reference object logs.
		 * Example, if you set 120, you will get 2 mins guaranteed time that any object link will work since it first appeared.
		 * Default is 0, meaning everything is weak linked straight away.
		 * Recommend not to use too high numbers. possibly 120 (2 minutes) is max you should set.
		 * 
		 * Example:
		 * <code>
		 * Cc.log("This is a temp object:", new Object());
		 * // if you click this link in run time, it'll most likely say 'no longer exist'.
		 * // However if you set objectHardReferenceTimer to 60, you will get AT LEAST 60 seconds before it become unavailable.
		 * </code>
		 */
		public var objectHardReferenceTimer:uint = 0;
		

		// Work in progress
		//public var rolloverStackToolTip:Boolean = false;
		
		///////////////////////
		//                   //
		//  REMOTING CONFIG  //
		//                   //
		///////////////////////
		
		/** 
		 * Local shared object used for storing user data such as command line history
		 * Set to null to disable storing to local shared object.
		 */
		public var sharedObjectName:String = "com.junkbyte/Console/UserData";
		
		/** Local shared object path */
		public var sharedObjectPath:String = "/";
			
		/**
		 * Remembers viewing filters such as channels and priority level over different sessions.
		 * <ul>
		 * <li>Must be set before starting console (before Cc.start / Cc.startOnStage)</li>
		 * <li>Requires sharedObject feature turned on</li>
		 * <li>Because console's SharedObject is shared across, your filtering settings will carry over to other flash projects</li>
		 * <li>You may want to set sharedObjectName to store project specificly</li>
		 * </ul>
		 */
		public var rememberFilterSettings:Boolean;
		
		
		////////////////////
		//                //
		//  STYLE CONFIG  //
		//                //
		////////////////////
		
		public function get style():ConsoleStyle{
			return _style;
		}
		
		/////////////////////
		//                 //
		//  END OF CONFIG  //
		//                 //
		/////////////////////
		
		private var _style:ConsoleStyle;
		
		public function ConsoleConfig(){
			_style = new ConsoleStyle();
		}
	}
}