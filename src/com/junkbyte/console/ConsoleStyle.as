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
	
	public class ConsoleStyle {
		
		/** Font for menus and almost all others */
		public var menuFont:String = "Arial";
		
		/** Default font size */
		public var menuFontSize:int = 12;
		
		/** Font for trace field */
		public var traceFont:String = "Verdana";
		
		/** Font size for trace field */
		public var traceFontSize:int = 11;
		
		/** Panels background color */
		public var backgroundColor:uint;
		
		/** Panels background alpha */
		public var backgroundAlpha:Number = 0.9;
		
		/** Color of scroll bar, scaler, etc. Some gets alpha applied */
		public var controlColor:uint = 0x990000;
		
		/** Size of controls, scroll bar, scaler, etc */
		public var controlSize:uint = 5;
		
		/** Command line background and text color. Background gets alpha so it is less visible. */
		public var commandLineColor:uint = 0x10AA00;
		
		/** Font color for high priority text, such as user input. */
		public var highColor:uint = 0xFFFFFF;
		
		/** Font color for less important / smaller text */
		public var lowColor:uint = 0xC0C0C0; 
		
		/** Font color for log header text (line number, channel and time stamp) */
		public var logHeaderColor:uint = 0xC0C0C0; 
		
		/** Font color for menu */
		public var menuColor:uint = 0xFF8800;
		
		/** Font color for highlighted menu */
		public var menuHighlightColor:uint = 0xDD5500; 
		
		/** Font color for channel names */
		public var channelsColor:uint = 0xFFFFFF;
		
		/** Font color for current channel name */
		public var channelColor:uint = 0x0099CC;
		
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
		
		
		/** Show top menu */
		public var topMenu:Boolean = true;
		
		/** Show command line scope */
		public var showCommandLineScope:Boolean = true;
		
		/** Maximum number of channels to display on top menu */
		public var maxChannelsInMenu:int = 7;
		
		/** Panel snapping radius during drag move. default:3, set to 0 to disable*/
		public var panelSnapping:int = 3;
		
		/** Panels background corner rounding */
		public var roundBorder:int = 10;
		
		
		/** Use white base pre configuration */
		public function whiteBase():void{
			backgroundColor = 0xFFFFFF;
			controlColor = 0xFF3333;
			commandLineColor = 0x66CC00;
			//
			highColor = 0x000000;
			lowColor = 0x333333;
			logHeaderColor = 0x444444;
			menuColor = 0xCC1100;
			menuHighlightColor = 0x881100;
			channelsColor = 0x000000;
			channelColor = 0x0066AA;
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
			traceFontSize = 13;
			menuFontSize = 14;
		}
		
		/////////////////////
		//                 //
		//  END OF CONFIG  //
		//                 //
		/////////////////////
				
		private var _css:StyleSheet;
		/**
		 * Construct ConsoleStyle. Starts with default black based style.
		 * You must set up the desired style and configuration before starting Console.
		 */
		public function ConsoleStyle() {
			_css = new StyleSheet();
		}
		
		/**
		 * Called by console at start to generate the style sheet based on the style settings set
		 * If you ever changed the style settings after console have already started, 
		 * calling this method have a good chance of updating console style on the fly as well - not guarantee tho.
		 */
		public function updateStyleSheet():void {
			_css.setStyle("high",{color:hesh(highColor), fontFamily:menuFont, fontSize:menuFontSize, display:'inline'});
			_css.setStyle("low",{color:hesh(lowColor), fontFamily:menuFont, fontSize:menuFontSize-2, display:'inline'});
			_css.setStyle("menu",{color:hesh(menuColor), display:'inline'});
			_css.setStyle("menuHi",{color:hesh(menuHighlightColor), display:'inline'});
			_css.setStyle("chs",{color:hesh(channelsColor), fontSize:menuFontSize, leading:'2', display:'inline'});
			_css.setStyle("ch",{color:hesh(channelColor), display:'inline'});
			_css.setStyle("tt",{color:hesh(menuColor),fontFamily:menuFont,fontSize:menuFontSize, textAlign:'center'});
			_css.setStyle("r",{textAlign:'right', display:'inline'});
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
			_css.setStyle("logs",{color:hesh(logHeaderColor), display:'inline'});
		}
		/**
		 * Style sheet used by Console.
		 * <p>
		 * You may add your own style definitions if you plan to use Cc.addHTML feature excessively.
		 * Only CSS properties supported by flash will work.
		 * 
		 * </p>
		 * At console startup, it sets several style sets using settings from ConsoleStyle, such as trace font size, menu color, etc.
		 * <ul>
		 * <li>List of build in styles:</li>
		 * <ul>
		 * <li>high - color:ConsoleStyle.highColor</li>
		 * <li>low - color:ConsoleStyle.lowColor</li>
		 * <li>menu - color:ConsoleStyle.menuColor</li>
		 * <li>menuHi - color:ConsoleStyle.menuHighlightColor</li>
		 * <li>chs - color:ConsoleStyle.channelsColor, fontSize:ConsoleStyle.menuFontSize, leading:2, display:inline</li>
		 * <li>r - textAlign:right (does not always work in logging)</li>
		 * <li>p - fontFamily:traceFont, fontSize:traceFontSize</li>
		 * <li>p0 - (priority0) color:priority0</li>
		 * <li>p1 - (priority1) color:priority1</li>
		 * <li>p2 - (priority2) color:priority2</li>
		 * <li>p3 - (priority3) color:priority3</li>
		 * <li>p4 - (priority4) color:priority4</li>
		 * <li>p5 - (priority5) color:priority5</li>
		 * <li>p6 - (priority6) color:priority6</li>
		 * <li>p7 - (priority7) color:priority7</li>
		 * <li>p8 - (priority8) color:priority8</li>
		 * <li>p9 - (priority9) color:priority9</li>
		 * <li>p10 - (priority10) color:priority10, fontWeight:bold</li>
		 * <li>p-1 - (priority-1) color:priority-1</li>
		 * <li>p-2 - (priority-2) color:priority-2</li>
		 * <li>tt - (tooltip) color:channelsColor, fontFamily:menuFont, fontSize:menuFontSize, textAlign:center</li>
		 * </ul>
		 * <li>Adding new style example:</li>
		 * <ul>
		 * <li><code>Cc.config.style.styleSheet.setStyle("purple",{color:'#FF00FF', fontWeight:'bold', display:'inline'});</code></li>
		 * <li><code>Cc.addHTML("My special &lt;purple&gt;PURPLE&lt;/purple&gt; text");</code></li>
		 * </ul>
		 * <li>Example 2:</li>
		 * <ul>
		 * <li><code>Cc.config.style.styleSheet.setStyle(".spacy",{letterSpacing:10});</code></li>
		 * <li><code>Cc.addHTML("Here is &lt;span class='spacy'&gt;big letter spacing&lt;/span&gt;.");</code></li>
		 * </ul>
		 * </ul>
		 */
		public function get styleSheet():StyleSheet	{
			return _css;
		}
		private function hesh(n:Number):String{
			return "#"+n.toString(16);
		}
	}
}