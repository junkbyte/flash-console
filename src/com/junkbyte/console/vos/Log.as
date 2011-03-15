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
package com.junkbyte.console.vos {
	import flash.utils.ByteArray;
	
	public class Log{
		public var text:String;
		public var ch:String;
		public var priority:int;
		public var repeat:Boolean;
		public var html:Boolean;
		//
		public var next:Log;
		public var prev:Log;
		//
		public function Log(txt:String, cc:String, pp:int, repeating:Boolean = false, skipSafe:Boolean = false){
			text = txt;
			ch = cc;
			priority = pp;
			repeat = repeating;
			html = skipSafe;
		}
		public function toBytes():ByteArray{
			var bytes:ByteArray = new ByteArray();
			bytes.writeUnsignedInt(text.length);
			bytes.writeUTFBytes(text); // because writeUTF can't accept more than 65535
			bytes.writeUTF(ch);
			bytes.writeInt(priority);
			bytes.writeBoolean(repeat);
			return bytes;
		}
		public static function FromBytes(bytes:ByteArray):Log{
			var t:String = bytes.readUTFBytes(bytes.readUnsignedInt());
			var c:String = bytes.readUTF();
			var p:int = bytes.readInt();
			var r:Boolean = bytes.readBoolean();
			return new Log(t, c, p, r);
		}
		
		public function plainText():String{
			return text.replace(/<.*?>/g, "").replace(/&lt;/g, "<").replace(/&gt;/g, ">");
		}
		public function toString():String{
			return "["+ch+"] " + plainText();
		}
		
		public function clone():Log{
			return new Log(text, ch, priority, repeat, html);
		}
	}
}