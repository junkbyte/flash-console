/*
* 
* Copyright (c) 2008-2011 Lu Aye Oo
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
package com.junkbyte.console.addons.htmlexport {
	import flash.text.StyleSheet;
	import com.junkbyte.console.vos.Log;
	import com.adobe.serialization.json.JSON;
	import flash.net.FileReference;
	import com.junkbyte.console.Cc;
	import com.junkbyte.console.Console;
	import flash.utils.ByteArray;
	
	public class ConsoleHtmlExport
	{
		[Embed(source="template.html", mimeType="application/octet-stream")]
		private static var EmbeddedTemplate:Class;
		
		public static const REPLACE_BACKGROUND_COLOR:RegExp = /#BACKGROUND_COLOR/g;
		public static const REPLACE_TEXT_COLOR:RegExp = /#TEXT_COLOR/g;
		public static const REPLACE_STYLES:String = "#REPLACE_STYLES_FROM_FLASH{}";
		public static const REPLACE_LOGS:String = "[{text:'REPLACE_LOGS_FROM_FLASH'}]";
		
		public static function register(console:Console = null):void
		{
			if(console == null)
			{
				console = Cc.instance;
			}
			if (console) 
			{
				var exporter:ConsoleHtmlExport = new ConsoleHtmlExport();
				console.addMenu("export", exporter.export, new Array(console), "Export logs to HTML");
			}
		}
		
		public function export(console:Console):void
		{
			var html:String = String(new EmbeddedTemplate() as ByteArray);
			
			html = html.replace(REPLACE_BACKGROUND_COLOR, safeColorString(console.config.style.backgroundColor.toString(16)));
			html = html.replace(REPLACE_TEXT_COLOR, safeColorString(console.config.style.menuColor.toString(16)));
			html = html.replace(REPLACE_STYLES, getStylesReplacement(console));
			html = html.replace(REPLACE_LOGS, getLogsReplacement(console));
			
			var file:FileReference = new FileReference();
			try
			{
				file.save(html, "logs.html");
			}
			catch(err:Error) 
			{
				console.report("Failed to save to file.", 8);
			}
		}
		
		private function getLogsReplacement(console:Console):String
		{
			var lines:Array = new Array();
			var line:Log = console.logs.last;
			while(line){
				var obj:Object = {
					text:line.text.replace(/<a(\s+)href=.*?>/g,"<a>"),
					ch:line.ch,
					priority:line.priority
				};
				lines.push(obj);
				line = line.prev;
			}
			lines = lines.reverse();
			return JSON.encode(lines);
		}
		
		private function getStylesReplacement(console:Console):String
		{
			var result:String = "";
			var css:StyleSheet = console.config.style.styleSheet;
			for each(var styleName:String in css.styleNames)
			{
				var style:Object = css.getStyle(styleName);
				var parts:String = "";
				for (var key:String in style)
				{
					var value:String = style[key];
					if(key == "color")
					{
						value = safeColorString(value.substring(1));
					}
					key = key.replace(/([A-Z])/g,"-$1").toLowerCase();
					parts += key+":"+value+"; ";
				}
				result += styleName + " {" +parts+"}\r\n";
			}
			return result;
		}
		
		private function safeColorString(col:String):String
		{
			while(col.length < 6)
			{
				col = "0"+col;
			}
			return "#"+col;
		}
	}
}
