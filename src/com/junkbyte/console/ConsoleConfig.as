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
package com.junkbyte.console {
	import flash.text.StyleSheet;	
	
	public class ConsoleConfig {
		
		//////////////////////
		//                  //
		//  LOGGING CONIFG  //
		//                  //
		//////////////////////
		
		/** Global channel name (where it prints all logs) */
		public var globalChannel:String = " * ";
		
		/** Default channel name (logs without channel name) */
		public var defaultChannel:String = "-";
		
		/** Console's channel name */
		public var consoleChannel:String = "C";
		
		/** Filtered channel name */
		public var filteredChannel:String = "~";
		
		/**
		 * Maximum number of logs Console should remember.
		 * 0 = unlimited. Setting to very high will take up more memory and potentially slow down.
		 */
		public var maxLines:uint = 1000;
		
		/**
		 * Frames before repeating line is forced to print to next line.
		 * <p>
		 * Set to -1 to never force. Set to 0 to force every line.
		 * Default = 75;
		 * </p>
		 */
		public var maxRepeats:uint = 75;
		
		/**
		 * Auto stack trace logs for this priority and above
		 * default priortiy = 10; fatal level
		 */
		public var autoStackPriority:int = Console.FATAL_LEVEL;

		/**
		 * Default stack trace depth.
		 * default depth = 3;
		 */
		public var defaultStackDepth:int = 3;
		
		/**
		 * Assign custom trace function.
		 * <p>
		 * Strong reference to function. Console will only call this when C.tracing is true.
		 * Custom function must accept at 3 parameter:
		 * - String channel name.
		 * - String the log line.
		 * - int    priority level -2 to 10.
		 * </p>
		 * <p>
		 * Default function calls flash build-in trace in this format: "[channel] log line" (ignores priority)
		 * Example:
		 * function defaultTrace(ch:String, line:String, level:int):void {
		 * 	  trace("["+ch+"] "+line);
		 * }
		 * </p>
		 * @see C.tracing
		 */
		public var traceCall:Function = defaultTrace;
		
		private static function defaultTrace(ch:String, line:String, level:int):void
		{
			trace("["+ch+"] "+line);
		}
		
		///////////////////////
		//                   //
		//  REMOTING CONFIG  //
		//                   //
		///////////////////////
		
		/** 
		 * Shared connection name used for remoting 
		 * You can change this if you don't want to use default channel
		 * Other remotes with different remoting channel won't be able to connect your flash.
		 * Start with _ to work in any domain + platform (air/swf - local / network)
		 * Note that local to network sandbox still apply.
		 */
		public var remotingConnectionName:String = "_Console";
		
		/**
		 * Accessor for remoter's broadcast interval in frames.
		 * Default = 1 (sent every frame)
		 */
		public var remoteDelay:uint = 1;
		
		
		///////////////////
		//               //
		//  MISC CONFIG  //
		//               //
		///////////////////
		
		
		/**
		 * Command line usage allowance.
		 * <p>
		 * CommandLine is a big security hole for your code and flash. It is a very good
		 * practice to disable it after development phase.
		 * On the other hand having it on full access will let you debug the code easier.
		 * This will automatically set to true when you set C.commandLine = true
		 * </p>
		 */
		public var commandLineAllowed:Boolean;
		
		/**
		 * Determine if Console should hide the mouse cursor when using Ruler tool.
		 * <p>
		 * You may want to turn it off if your app/game don't use system mouse.
		 * Default: true
		 * </p>
		 */
		public var rulerHidesMouse:Boolean = true;
		
		/** Local shared object used for storing user data such as command line history
		 *  Set to null to disable storing to local shared object.
		 */
		public var sharedObjectName:String = "com.junkbyte/Console/UserData";
		
		/** Local shared object path */
		public var sharedObjectPath:String = "/";
		
		
		////////////////////
		//                //
		//  STYLE CONFIG  //
		//                //
		////////////////////
		
		/** Font for menus and almost all others */
		public var menuFont:String = "Arial";
		
		/** Default font size */
		public var menuFontSize:int = 12;
		
		/** Font for trace field */
		public var traceFont:String = "Verdana";
		
		/** Font size for trace field */
		public var traceFontSize:int = 11;
		
		/** Panels backround color */
		public var backgroundColor:uint;
		
		/** Panels background corner rounding */
		public var roundBorder:int = 10;
		
		/** Panels background alpha */
		public var backgroundAlpha:Number = 0.9;
		
		/** Color of scroll bar, scaler, etc. Some gets alpha applied */
		public var controlColor:uint = 0x990000;
		
		/** Command line background and text color. Background gets alpha so it is less visible. */
		public var commandLineColor:uint = 0x10AA00;
		
		/** Font color for high priority text, such as user input. */
		public var highColor:uint = 0xFFFFFF;
		
		/** Font color for less important / smaller text */
		public var lowColor:uint = 0xC0C0C0; 
		
		/** Font color for menu */
		public var menuColor:uint = 0xFF8800;
		
		/** Font color for highlighted menu */
		public var menuHighlightColor:uint = 0xDD5500; 
		
		/** Font color for channel names */
		public var channelsColor:uint = 0xFFFFFF;
		
		/** Font color for current channel name */
		public var channelColor:uint = 0x0099CC;
		
		/** Font color for tool tips */
		public var tooltipColor:uint = 0xDD5500;
		
		//
		
		/** Color of log priority level 0.*/
		public var priority0:uint = 0x3A773A;
		/** Color of log priority level 1. C.log(...)*/
		public var priority1:uint = 0x449944;
		/** Color of log priority level 2. */
		public var priority2:uint = 0x77BB77;
		/** Color of info log priority level 3. C.info(...) */
		public var priority3:uint = 0xA0D0A0;
		/** Color of log priority level 4. */
		public var priority4:uint = 0xD6EED6;
		/** Color of debug log priority level 5. */
		public var priority5:uint = 0xE9E9E9;
		/** Color of log priority level 6. C.debug(...) */
		public var priority6:uint = 0xFFDDDD;
		/** Color of warn log priority level 7. */
		public var priority7:uint = 0xFFAAAA;
		/** Color of log priority level 8. C.warn(...) */
		public var priority8:uint = 0xFF7777;
		/** Color of error log priority level 9. C.error(...) */
		public var priority9:uint = 0xFF2222;
		/** Color of fatal log priority level 10. C.fatal(...) */
		public var priority10:uint = 0xFF2222; // priority 10, also gets a bold
		
		/** Color of console status log.*/
		public var priorityC1:uint = 0x0099CC;
		/** Color of console event log.*/
		public var priorityC2:uint = 0xFF8800;
		
		/** Use white base pre configuration */
		public function whiteBase():void{
			backgroundColor = 0xFFFFFF;
			controlColor = 0xFF3333;
			commandLineColor = 0x66CC00;
			//
			highColor = 0x000000;
			lowColor = 0x333333;
			menuColor = 0xCC1100;
			menuHighlightColor = 0x881100;
			channelsColor = 0x000000;
			channelColor = 0x0066AA;
			tooltipColor = 0xAA3300;
			//
			priority0 = 0x44A044;
			priority1 = 0x339033;
			priority2 = 0x227722;
			priority3 = 0x115511;
			priority4 = 0x003300;
			priority5 = 0x000000;
			priority6 = 0x660000;
			priority7 = 0x990000;
			priority8 = 0xBB0000;
			priority9 = 0xDD0000;
			priority10 = 0xDD0000;
			priorityC1 = 0x0099CC;
			priorityC2 = 0xFF6600;
		}
		/** Use bigger font size */
		public function big():void{
			traceFontSize = 12;
			menuFontSize = 14;
		}
		/** Use opaque background */
		public function opaque():void{
			backgroundAlpha = 1;
		}
		/** Use black and white traces */
		public function blackAndWhiteTrace():void{
			priority0 = 0x808080;
			priority1 = 0x888888;
			priority2 = 0x999999;
			priority3 = 0x9F9F9F;
			priority4 = 0xAAAAAA;
			priority5 = 0xAAAAAA;
			priority6 = 0xCCCCCC;
			priority7 = 0xCCCCCC;
			priority8 = 0xDDDDDD;
			priority9 = 0xFFFFFF;
			priority10 = 0xFFFFFF;
			priorityC1 = 0xBBC0CC;
			priorityC2 = 0xFFEEDD;
		}
		
		
		/////////////////////
		//                 //
		//  END OF CONFIG  //
		//                 //
		/////////////////////
				
		private var _css:StyleSheet;
		/**
		 * Construct ConsoleConfig. Starts with default black based style.
		 * You must set up the desired style and configuration before starting Console.
		 */
		public function ConsoleConfig() {
			_css = new StyleSheet();
		}
		
		/**
		 * Called by console at start to generate the style sheet based on the style settings set
		 * If you ever changed the style settings after console have already started, 
		 * calling this method have a good chance of updating console style on the fly as well - not guarantee tho.
		 */
		public function updateStyleSheet():void
		{
			_css.setStyle("r",{textAlign:'right', display:'inline'});
			_css.setStyle("w",{color:hesh(highColor), fontFamily:menuFont, fontSize:menuFontSize, display:'inline'});
			_css.setStyle("s",{color:hesh(lowColor), fontFamily:menuFont, fontSize:menuFontSize-2, display:'inline'});
			_css.setStyle("hi",{color:hesh(menuHighlightColor), display:'inline'});
			_css.setStyle("menu",{color:hesh(menuColor), display:'inline'});
			_css.setStyle("chs",{color:hesh(channelsColor), fontSize:menuFontSize, leading:'2', display:'inline'});
			_css.setStyle("ch",{color:hesh(channelColor), display:'inline'});
			_css.setStyle("tt",{color:hesh(tooltipColor),fontFamily:menuFont,fontSize:menuFontSize, textAlign:'center'});
			_css.setStyle("p",{fontFamily:traceFont, fontSize:traceFontSize});
			_css.setStyle("p0",{color:hesh(priority0), display:'inline'});
			_css.setStyle("p1",{color:hesh(priority1), display:'inline'});
			_css.setStyle("p2",{color:hesh(priority2), display:'inline'});
			_css.setStyle("p3",{color:hesh(priority3), display:'inline'});
			_css.setStyle("p4",{color:hesh(priority4), display:'inline'});
			_css.setStyle("p5",{color:hesh(priority5), display:'inline'});
			_css.setStyle("p6",{color:hesh(priority6), display:'inline'});
			_css.setStyle("p7",{color:hesh(priority7), display:'inline'});
			_css.setStyle("p8",{color:hesh(priority8), display:'inline'});
			_css.setStyle("p9",{color:hesh(priority9), display:'inline'});
			_css.setStyle("p10",{color:hesh(priority10), fontWeight:'bold', display:'inline'});
			_css.setStyle("p-1",{color:hesh(priorityC1), display:'inline'});
			_css.setStyle("p-2",{color:hesh(priorityC2), display:'inline'});
		}
		public function get styleSheet():StyleSheet	{
			return _css;
		}
		private function hesh(n:Number):String{
			return "#"+n.toString(16);
		}
	}
}