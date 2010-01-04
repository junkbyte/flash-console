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
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	
	public class WeakObject extends Proxy{
		
		private var _item:Array; // array of object's properties
		private var _dir:Object;
		
		public function WeakObject() {
			_dir = new Object();
		}
		
		
		public function set(n:String,obj:Object, strong:Boolean = false):void{
			if(obj == null){
				return;
			}
			_dir[n] = new WeakRef(obj, strong);
		}
		public function get(n:String):Object{
			if(_dir[n]){
				return _dir[n].reference;
			}
			return null;
		}
		//
		// PROXY
		//
		override flash_proxy function getProperty(n:*):* {
			return get(n);
		}
		override flash_proxy function callProperty(n:*, ... rest):* {
			var o:Object = get(n);
			if(o is Function){
				return (o as Function).apply(this, rest);
			}
			return null;
		}
		override flash_proxy function setProperty(n:*, v:*):void {
			set(n,v);
		}
		override flash_proxy function nextNameIndex (index:int):int {
         // initial call
         if (index == 0) {
             _item = new Array();
             for (var x:* in _dir) {
                _item.push(x);
             }
         }
         if (index < _item.length) {
             return index + 1;
         } else {
             return 0;
         }
     }
     override flash_proxy function nextName(index:int):String {
         return _item[index - 1];
     }
     public function toString():String{
     	return "[WeakObject]";
     }
	}
}