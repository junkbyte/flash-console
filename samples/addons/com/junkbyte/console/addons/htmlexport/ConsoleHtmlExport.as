package com.junkbyte.console.addons.htmlexport {
	import flash.text.StyleSheet;
	import com.junkbyte.console.vos.Log;
	import com.adobe.serialization.json.JSON;
	import flash.net.FileReference;
	import com.junkbyte.console.Cc;
	import com.junkbyte.console.Console;
	import flash.utils.ByteArray;
	/**
	 * @author LuAye
	 */
	public class ConsoleHtmlExport 
	{
		[Embed(source="template.html", mimeType="application/octet-stream")]
		private static var EmbeddedTemplate:Class;
		
		public static const REPLACE_BACKGROUND_COLOR:RegExp = /#BACKGROUND_COLOR/g;
		public static const REPLACE_TEXT_COLOR:RegExp = /#TEXT_COLOR/g;
		public static const REPLACE_STYLES:String = "#REPLACE_STYLES_FROM_FLASH{}";
		public static const REPLACE_LOGS:String = "[{text:'REPLACE_LOGS_FROM_FLASH'}]";
		
		private var console:Console;
		
		public static function register(menuText:String = "export", console:Console = null):void
		{
			new ConsoleHtmlExport(menuText, console);
		}
		
		public function ConsoleHtmlExport(menuText:String, console:Console)
		{
			if(console == null)
			{
				console = Cc.instance;
			}
			this.console = console;
			if (console) 
			{
				console.addMenu(menuText, export);
			}
		}
		
		private function export():void
		{
			var html:String = String(new EmbeddedTemplate() as ByteArray);
			
			html = html.replace(REPLACE_BACKGROUND_COLOR, safeColor(console.config.style.backgroundColor.toString(16)));
			html = html.replace(REPLACE_TEXT_COLOR, safeColor(console.config.style.menuColor.toString(16)));
			html = html.replace(REPLACE_STYLES, getStylesReplacement());
			html = html.replace(REPLACE_LOGS, getLogsReplacement());
			
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
		
		private function getLogsReplacement():String
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
		
		private function getStylesReplacement():String
		{
			var result:String = "";
			var css:StyleSheet = console.config.style.styleSheet;
			for each(var styleName:String in css.styleNames)
			{
				var style:Object = css.getStyle(styleName);
				var parts:String = "";
				for (var keyX:String in style)
				{
					var key:String = keyX;
					var value:String = style[key];
					if(key == "fontSize")
					{
						key = "font-size";
					}
					else if(key == "fontFamily")
					{
						key = "font-family";
					}
					else if(key == "fontWeight")
					{
						key = "font-weight";
					}
					else if(key == "color")
					{
						value = safeColor(value.substring(1));
					}
					parts += key+":"+value+"; ";
				}
				result += styleName + " {" +parts+"}\n";
			}
			return result;
		}
		
		private function safeColor(col:String):String
		{
			while(col.length < 6)
			{
				col = "0"+col;
			}
			return "#"+col;
		}
	}
}
