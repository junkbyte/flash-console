/*
* Copyright (c) 2008 Lu Aye Oo (Atticmedia)
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
*/


package com.atticmedia.console {
	import flash.utils.Dictionary;
	
	public class Weak {
		private var _dir:Object;
		
		public function Weak() {
			_dir = new Object();
		}
		
		
		public function set(n:String,obj:Object, strong:Boolean = false):void{
			if(obj == null){
				return;
			}
			var dic:Dictionary = new Dictionary(!strong);
			dic[obj] = null;
			_dir[n] = dic;
		}
		
		public function get(n:String):Object{
			if(_dir[n]){
				return extract(_dir[n]);
			}
			return null;
		}
		
		private function extract(dir:Dictionary):Object{
			//there should be only 1 key in it anyway
			for(var X:Object in dir){
				return X;
			}
			return null;
		}
	}
}