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
	import flash.utils.Dictionary;
	
	public class WeakRef{
		
		private var _val:*;
		private var _strong:Boolean;
		
		//
		// There is abilty to use strong reference incase you need to mix - 
		// weak and strong references together somewhere
		public function WeakRef(ref:*, strong:Boolean = false) {
			if(ref is Function) strong = true; // Function must be strong ref, for now :/
			_strong = strong;
			reference = ref;
		}
		//
		//
		//
		public function get reference():*{
			if(_strong){
				return _val;
			}else{
				//there should be only 1 key in it anyway
				for(var X:* in _val){
					return X;
				}
			}
			return null;
		}
		public function set reference(ref:*):void{
			if(_strong){
				_val = ref;
			}else{
				_val = new Dictionary(true);
				_val[ref] = null;
			}
		}
		//
		//
		//
		public function get strong():Boolean{
			return _strong;
		}
		public function set strong(b:Boolean):void{
			if(_strong != b){
				var ref:* = reference;
				_strong = b;
				reference = ref;
			}
		}
	}
}