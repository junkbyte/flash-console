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
package com.luaye.console.core {
	public class Logs{
		
		public var first:Log;
		public var last:Log;
		
		private var _length:uint;
		
		public function clear():void{
			first = null;
			last = null;
			_length = 0;
		}
		
		public function get length():uint{
			return _length;
		}
		// add to the last of chain
		public function push(v:Log):void{
			if(last==null) {
				first = v;
			}else{
				last.next = v;
				v.prev = last;
			}
			last = v;
			_length++;
		}
		// remove last item of chain
		public function pop():void{
			if(last) {
				last = last.prev;
				_length--;
			}
		}
		// remove first item of chain
		public function shift(count:uint = 1):void{
			while(first != null && count>0){
				first = first.next;
				count--;
				_length--;
			}
		}
		public function remove(log:Log):void{
			if(first == log) first = log.next;
			if(last == log) last = log.prev;
			if(log.next != null) log.next.prev = log.prev;
			if(log.prev != null) log.prev.next = log.next;
			_length--;
		}
	}
}