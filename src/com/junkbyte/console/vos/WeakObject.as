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
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	
	public dynamic class WeakObject extends Proxy{
		
		private var _item:Array;
		private var _dir:Object;
		
		public function WeakObject() {
			_dir = new Object();
		}
		public function set(n:String, obj:Object, strong:Boolean = false):void{
			if(obj == null) delete _dir[n]; 
			else _dir[n] = new WeakRef(obj, strong);
		}
		public function get(n:String):*{
			var ref:WeakRef = getWeakRef(n);
			return ref?ref.reference:undefined;
		}
		public function getWeakRef(n:String):WeakRef{
			return _dir[n] as WeakRef;
		}
		//
		// PROXY
		//
		override flash_proxy function getProperty(n:*):* {
			return get(n);
		}
		override flash_proxy function callProperty(n:*, ... rest):* {
			var o:Object = get(n);
			return o.apply(this, rest);
		}
		override flash_proxy function setProperty(n:*, v:*):void {
			set(n,v);
		}
	    override flash_proxy function nextName(index:int):String {
	        return _item[index - 1];
	    }
	    override flash_proxy function nextValue(index:int):* {
	        return this[flash_proxy::nextName(index)];
	    }
		override flash_proxy function nextNameIndex (index:int):int {
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
	     override flash_proxy function deleteProperty(name:*):Boolean {
	        return delete _dir[name];
	     }
	     public function toString():String{
	     	return "[WeakObject]";
	     }
	}
}