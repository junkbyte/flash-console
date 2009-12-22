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

package com.luaye.console {
	/**
	 * @author Lu
	 */
	public class Ch {
		
		private var _c:*; // because it could be Console or C
		public var name:String;
		
		public function Ch(n:String = null, c:Console = null){
			name = n;
			// allowed to pass in Console here incase you want to use a different console instance from whats used in C
			_c = c?c:C;
		}
		public function add(str:*, priority:Number = 2, isRepeating:Boolean = false):void{
			_c.ch(name, str, priority, isRepeating);
		}
		public function log(...args):void{
			_c.logch.apply(null, [name].concat(args));
		}
		public function info(...args):void{
			_c.infoch.apply(null, [name].concat(args));
		}
		public function debug(...args):void{
			_c.debugch.apply(null, [name].concat(args));
		}
		public function warn(...args):void{
			_c.warnch.apply(null, [name].concat(args));
		}
		public function error(...args):void{
			_c.errorch.apply(null, [name].concat(args));
		}
		public function fatal(...args):void{
			_c.fatalch.apply(null, [name].concat(args));
		}
		/*
		not worth using...
		public function set tracing(v:Boolean):void{
			var chs:Array = _c.tracingChannels;
			var i:int = chs.indexOf(name);
			if(v){
				_c.tracing = true;
				if(i<0){
					chs.push(name);
				}
			}else if(i>=0){
				chs.splice(i,1);
			}
		}
		public function get tracing():Boolean{
			if(!_c.tracing) return false;
			var chs:Array = _c.tracingChannels;
			if(chs.length==0) return true;
			//
			var i:int = chs.indexOf(name);
			if(i<0) return false;
			return true;
		}*/
		
		/**
		 * Clear channel
		 */
		public function clear():void{
			_c.clear(name);
		}
	}
}
