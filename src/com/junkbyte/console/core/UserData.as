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
package com.junkbyte.console.core {
	import flash.net.SharedObject;

	public class UserData {
		
		private static const CMD_HISTORY_KEY:String = "clhistory";
		
		private var _so:SharedObject;
		private var _data:Object = {};
		
		public function UserData(name:String, localPath:String = null){
			if(name){
				try{
					_so = SharedObject.getLocal(name, localPath);
					_data = _so.data;
				}catch(e:Error){
					
				}
			}
		}
		
		public function get commandLineHistory():Array{
			if(_data[CMD_HISTORY_KEY] is Array){
				return _data[CMD_HISTORY_KEY];
			}else{
				var a:Array = new Array();
				_data[CMD_HISTORY_KEY] = a;
				return a;
			}
		}
		public function commandLineHistoryChanged():void{
			if(_so) _so.setDirty(CMD_HISTORY_KEY);
		}
	}
}
