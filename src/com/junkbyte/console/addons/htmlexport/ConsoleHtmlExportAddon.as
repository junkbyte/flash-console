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
* REQUIRES Flash Player 11.0 OR com.adobe.serialization.json.JSON
*/
package com.junkbyte.console.addons.htmlexport
{
	import com.junkbyte.console.Cc;
	import com.junkbyte.console.Console;
	import com.junkbyte.console.ConsoleConfig;
	import com.junkbyte.console.ConsoleStyle;
	import com.junkbyte.console.view.MainPanel;
	import com.junkbyte.console.vos.Log;

	import flash.net.FileReference;
	import flash.utils.ByteArray;
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;

	/**
	 * This addon allows you to export logs from flash console to a HTML file.
	 *
	 * <ul>
	 * <li>Preserves channels and priorities.</li>
	 * <li>It also have all those filtering features in HTML page.</li>
	 * <li>Add to Console menu by calling ConsoleHtmlExport.addMenuToConsole();</li>
	 * </ul>
	 *
	 * REQUIRES Flash Player 11.0 OR com.adobe.serialization.json.JSON library.
	 */
	public class ConsoleHtmlExportAddon
	{
		[Embed(source = "template.html", mimeType = "application/octet-stream")]
		private static var EmbeddedTemplate:Class;

		public static const HTML_REPLACEMENT:String = "{text:'HTML_REPLACEMENT'}";

		public var referencesDepth:uint = 1;

		protected var console:Console;

		/**
		 * Adding 'export' menu item at the top menu of Console.
		 *
		 * @param menuName Name of menu. Default = 'export'
		 * @param console Instance to Console. You do not need to pass this param if you use Cc.
		 *
		 * @return New ConsoleHTMLExport instance created by this method.
		 */
		public static function addToMenu(menuName:String = "export", console:Console = null):ConsoleHtmlExportAddon
		{
			if (console == null)
			{
				console = Cc.instance;
			}
			var exporter:ConsoleHtmlExportAddon;
			if (console)
			{
				exporter = new ConsoleHtmlExportAddon(console);
				console.addMenu(menuName, exporter.exportToFile, new Array(), "Export logs to HTML");
			}
			return exporter;
		}

		public function ConsoleHtmlExportAddon(console:Console):void
		{
			if (console == null)
			{
				console = Cc.instance;
			}
			this.console = console;
		}

		/**
		 * Trigger 'save to file' dialogue to save console logs in HTML file.
		 *
		 * @param fileName Initial file name to use in save dialogue.
		 */
		public function exportToFile(fileName:String = null):void
		{
			if (fileName == null)
			{
				fileName = generateFileName();
			}

			var file:FileReference = new FileReference();
			try
			{
				var html:String = exportHTMLString();
				file['save'](html, fileName); // flash player 10+ 
			}
			catch (err:Error)
			{
				console.report("Failed to save to file: " + err, 8);
			}
		}

		protected function generateFileName():String
		{
			var date:Date = new Date();
			var fileName:String = "log@" + date.getFullYear() + "." + (date.getMonth() + 1) + "." + (date.getDate() + 1);
			fileName += "_" + date.hours + "." + date.minutes;
			fileName += ".html";
			return fileName;
		}

		/**
		 * Generate HTML String of Console logs.
		 */
		public function exportHTMLString():String
		{
			var html:String = String(new EmbeddedTemplate() as ByteArray);
			html = html.replace(HTML_REPLACEMENT, exportJSON());
			return html;
		}

		protected function exportJSON():String
		{
			var object:Object = exportObject();
			try
			{
				var nativeJSON:Class = getDefinitionByName("JSON") as Class;
				return nativeJSON["stringify"](object);
			}
			catch (error:Error)
			{
				// native json not found. pre flash player 11.
			}
			var libJSON:Class = getDefinitionByName("com.adobe.serialization.json.JSON") as Class;
			return libJSON["encode"](object);
		}

		protected function exportObject():Object
		{
			var data:Object = new Object();

			data.config = getConfigToEncode();

			data.ui = getUIDataToEncode();

			data.logs = getLogsToEncode();

			var refs:ConsoleHTMLRefsGen = new ConsoleHTMLRefsGen(console, referencesDepth);
			refs.fillData(data);

			return data;
		}

		protected function getConfigToEncode():Object
		{
			var config:ConsoleConfig = console.config;
			var object:Object = convertTypeToObject(config);
			object.style = getStyleToEncode();
			return object;
		}

		protected function getStyleToEncode():Object
		{
			var style:ConsoleStyle = console.config.style;
			/*if(!preserveStyle)
			{
				style = new ConsoleStyle();
				style.updateStyleSheet();
			}*/

			var object:Object = convertTypeToObject(style);
			object.styleSheet = getStyleSheetToEncode(style);

			return object;
		}

		protected function getStyleSheetToEncode(style:ConsoleStyle):Object
		{
			var object:Object = new Object();
			for each (var styleName:String in style.styleSheet.styleNames)
			{
				object[styleName] = style.styleSheet.getStyle(styleName);
			}
			return object;
		}

		protected function getUIDataToEncode():Object
		{
			var object:Object = new Object();

			var mainPanel:MainPanel = console.panels.mainPanel;
			object.viewingPriority = mainPanel.priority;
			object.viewingChannels = mainPanel.viewingChannels;
			object.ignoredChannels = mainPanel.ignoredChannels;

			return object;
		}

		protected function getLogsToEncode():Object
		{
			var lines:Array = new Array();
			var line:Log = console.logs.last;
			while (line)
			{
				var obj:Object = convertTypeToObject(line);
				delete obj.next;
				delete obj.prev;
				lines.push(obj);
				line = line.prev;
			}
			lines = lines.reverse();
			return lines;
		}

		protected function convertTypeToObject(typedObject:Object):Object
		{
			var object:Object = new Object();
			var desc:XML = describeType(typedObject);
			for each (var varXML:XML in desc.variable)
			{
				var key:String = varXML.@name;
				object[key] = typedObject[key];
			}
			return object;
		}
	}
}
