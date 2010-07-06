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
package com.luaye.console {

	public class ConsoleStyle {
		
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
		
		/** Panels backround color */
		public var roundBorder:int = 10;
		
		/** Panels background alpha */
		public var backgroundAlpha:Number = 0.85;
		
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
		public var priority0:uint = 0x336633;
		/** Color of log priority level 1. C.log(...)*/
		public var priority1:uint = 0x44BB44;
		/** Color of log priority level 2. */
		public var priority2:uint = 0x77D077;
		/** Color of info log priority level 3. C.info(...) */
		public var priority3:uint = 0xA0E0A0;
		/** Color of log priority level 4. */
		public var priority4:uint = 0xD6FFD6;
		/** Color of debug log priority level 5. C.debug(...) */
		public var priority5:uint = 0xE9E9E9;
		/** Color of log priority level 6. */
		public var priority6:uint = 0xFFD6D6;
		/** Color of warn log priority level 7. C.warn(...) */
		public var priority7:uint = 0xFFAAAA;
		/** Color of log priority level 8. */
		public var priority8:uint = 0xFF7777;
		/** Color of error log priority level 9. C.error(...) */
		public var priority9:uint = 0xFF2222;
		/** Color of fatal log priority level 10. C.fatal(...) */
		public var priority10:uint = 0xFF2222; // priority 10, also gets a bold
		
		/** Color of console status log.*/
		public var priorityC1:uint = 0x0099CC;
		/** Color of console event log.*/
		public var priorityC2:uint = 0xFF8800;
		
		/**
		 * Construct ConsoleStyle. Starts with default black based style.
		 * You must pass set up the desired style before starting Console.
		 */
		public function ConsoleStyle() {
			
		}
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
	}
}