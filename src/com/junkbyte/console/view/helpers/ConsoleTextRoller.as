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
package com.junkbyte.console.view.helpers
{
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.text.TextField;

	public class ConsoleTextRoller
	{
		private static const TEXT_ROLL:String = "TEXT_ROLL";

		public static function register(field:TextField, overhandle:Function, linkHandler:Function = null):void
		{
			field.addEventListener(MouseEvent.MOUSE_MOVE, onTextFieldMouseMove, false, 0, true);
			field.addEventListener(MouseEvent.ROLL_OUT, onTextFieldMouseOut, false, 0, true);
			field.addEventListener(TEXT_ROLL, overhandle, false, 0, true);
			if (linkHandler != null)
				field.addEventListener(TextEvent.LINK, linkHandler, false, 0, true);
		}

		private static function onTextFieldMouseOut(e:MouseEvent):void
		{
			TextField(e.currentTarget).dispatchEvent(new TextEvent(TEXT_ROLL));
		}

		private static function onTextFieldMouseMove(e:MouseEvent):void
		{
			var field:TextField = e.currentTarget as TextField;
			var index:int;
			if (field.scrollH > 0)
			{
				// kinda a hack really :(
				var scrollH:Number = field.scrollH;
				var w:Number = field.width;
				field.width = w + scrollH;
				index = field.getCharIndexAtPoint(field.mouseX + scrollH, field.mouseY);
				field.width = w;
				field.scrollH = scrollH;
			}
			else
			{
				index = field.getCharIndexAtPoint(field.mouseX, field.mouseY);
			}
			var url:String = null;
			if (index > 0)
			{
				// TextField.getXMLText(...) is not documented
				try
				{
					var X:XML = new XML(field.getXMLText(index, index + 1));
					if (X.hasOwnProperty("textformat"))
					{
						var txtformat:XML = X["textformat"][0] as XML;
						if (txtformat)
						{
							url = txtformat.@url;
						}
					}
				}
				catch (err:Error)
				{
					url = null;
				}
			}
			field.dispatchEvent(new TextEvent(TEXT_ROLL, false, false, url));
		}
	}
}
