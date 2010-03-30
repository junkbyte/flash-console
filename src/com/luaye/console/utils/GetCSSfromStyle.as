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
package com.luaye.console.utils {
	import com.luaye.console.ConsoleStyle;

	import flash.text.StyleSheet;
	/**
	 * @author LuAye
	 */
	public function GetCSSfromStyle(style:ConsoleStyle) : StyleSheet {
		var css:StyleSheet = new StyleSheet();
		with(style){
			css.setStyle("r",{textAlign:'right', display:'inline'});
			css.setStyle("w",{color:hesh(highColor), fontFamily:menuFont, fontSize:menuFontSize, display:'inline'});
			css.setStyle("s",{color:hesh(lowColor), fontFamily:menuFont, fontSize:menuFontSize-2, display:'inline'});
			css.setStyle("hi",{color:hesh(menuHighlightColor), display:'inline'});
			css.setStyle("menu",{color:hesh(menuColor), display:'inline'});
			css.setStyle("chs",{color:hesh(channelsColor), fontSize:menuFontSize, leading:'2', display:'inline'});
			css.setStyle("ch",{color:hesh(channelColor), display:'inline'});
			css.setStyle("tooltip",{color:hesh(tooltipColor),fontFamily:menuFont,fontSize:menuFontSize, textAlign:'center'});
			css.setStyle("p",{fontFamily:traceFont, fontSize:traceFontSize});
			css.setStyle("p0",{color:hesh(priority0), display:'inline'});
			css.setStyle("p1",{color:hesh(priority1), display:'inline'});
			css.setStyle("p2",{color:hesh(priority2), display:'inline'});
			css.setStyle("p3",{color:hesh(priority3), display:'inline'});
			css.setStyle("p4",{color:hesh(priority4), display:'inline'});
			css.setStyle("p5",{color:hesh(priority5), display:'inline'});
			css.setStyle("p6",{color:hesh(priority6), display:'inline'});
			css.setStyle("p7",{color:hesh(priority7), display:'inline'});
			css.setStyle("p8",{color:hesh(priority8), display:'inline'});
			css.setStyle("p9",{color:hesh(priority9), display:'inline'});
			css.setStyle("p10",{color:hesh(priority10), fontWeight:'bold', display:'inline'});
			css.setStyle("p-1",{color:hesh(priorityC1), display:'inline'});
			css.setStyle("p-2",{color:hesh(priorityC2), display:'inline'});
		}
		return css;
	}
}
function hesh(n:Number):String{
	return "#"+n.toString(16);
}
